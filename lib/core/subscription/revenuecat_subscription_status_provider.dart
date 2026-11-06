import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/subscription/purchases_gateway.dart';
import 'package:newsreader/core/subscription/subscription_plan.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';

/// `SubscriptionStatusProvider` sobre RevenueCat. Con [apiKey] nulo (hoy,
/// Android) no configura el SDK: el usuario se trata como sin suscripción y
/// los planes no están disponibles. Ver
/// `openspec/changes/migrate-to-revenuecat/design.md` (D1, D6, D10).
class RevenueCatSubscriptionStatusProvider
    implements SubscriptionStatusProvider {
  final PurchasesGateway _gateway;
  final String? _apiKey;

  final _changes = StreamController<bool>.broadcast();
  final Map<String, Package> _packagesById = {};

  bool _isConfigured = false;
  bool _isSubscribed = false;

  /// Usuario que la app quiere tener identificado ante RevenueCat. Se conserva
  /// aunque `logIn` falle (sin red) para reintentar antes de comprar: una
  /// compra anónima no la vería `sync-entitlement`, que consulta por el
  /// `user_id` de Supabase.
  String? _wantedUserId;
  bool _isIdentified = false;

  RevenueCatSubscriptionStatusProvider({
    required PurchasesGateway gateway,
    required String? apiKey,
  }) : _gateway = gateway,
       _apiKey = apiKey;

  /// Configura el SDK y deja el estado inicial listo. `configure` no usa la red;
  /// el estado inicial sale de la caché del SDK y no se espera: el listener lo
  /// actualiza cuando llegue, sin bloquear el arranque.
  Future<void> init() async {
    final apiKey = _apiKey;
    if (apiKey == null) return;
    await _gateway.configure(apiKey);
    _isConfigured = true;
    _gateway.addProEntitlementListener(_setSubscribed);
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    try {
      _setSubscribed(await _gateway.hasProEntitlement());
    } catch (e) {
      // Sin caché ni red: se queda en el valor actual y el listener lo corrige.
      debugPrint('No se pudo leer el estado de suscripción: $e');
    }
  }

  void _setSubscribed(bool value) {
    if (value == _isSubscribed) return;
    _isSubscribed = value;
    _changes.add(value);
  }

  @override
  bool get isSubscribed => _isSubscribed;

  @override
  Stream<bool> get isSubscribedChanges => _changes.stream;

  @override
  Future<void> identify(String userId) async {
    if (!_isConfigured) return;
    _wantedUserId = userId;
    await _ensureIdentified();
  }

  @override
  Future<void> reset() async {
    _wantedUserId = null;
    _isIdentified = false;
    if (!_isConfigured) return;
    try {
      _setSubscribed(await _gateway.logOut());
    } on PlatformException catch (e) {
      // El SDK rechaza `logOut` si el usuario ya es anónimo; no es un fallo.
      debugPrint('logOut de RevenueCat: ${e.code}');
      _setSubscribed(false);
    }
  }

  /// Reintenta `logIn` si el anterior falló. No lanza: un `logIn` sin red no
  /// debe tumbar el arranque ni el login (se reintenta al comprar).
  Future<void> _ensureIdentified() async {
    final userId = _wantedUserId;
    if (userId == null || _isIdentified) return;
    try {
      _setSubscribed(await _gateway.logIn(userId));
      _isIdentified = true;
    } on PlatformException catch (e) {
      debugPrint('logIn de RevenueCat falló: ${e.code}');
    }
  }

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    if (!_isConfigured) {
      throw const SubscriptionException(
        AppErrorCode.subscriptionOffersUnavailable,
        'not_configured',
      );
    }

    final List<Package> packages;
    try {
      packages = await _gateway.currentOfferingPackages();
    } on PlatformException catch (e) {
      throw SubscriptionException(
        AppErrorCode.subscriptionOffersUnavailable,
        _errorCode(e).name,
      );
    }

    final supported = packages
        .where(
          (p) =>
              p.packageType == PackageType.monthly ||
              p.packageType == PackageType.annual,
        )
        .toList();
    if (supported.isEmpty) {
      throw const SubscriptionException(
        AppErrorCode.subscriptionOffersUnavailable,
        'no_packages',
      );
    }

    final eligibility = await _trialEligibility(supported);
    _packagesById
      ..clear()
      ..addEntries(supported.map((p) => MapEntry(p.identifier, p)));

    final plans = supported.map((p) {
      final status = eligibility[p.storeProduct.identifier]?.status;
      final isEligible =
          status == IntroEligibilityStatus.introEligibilityStatusEligible;
      return SubscriptionPlan(
        id: p.identifier,
        type: p.packageType == PackageType.annual
            ? SubscriptionPlanType.annual
            : SubscriptionPlanType.monthly,
        priceString: p.storeProduct.priceString,
        freeTrialDays: isEligible ? _freeTrialDays(p.storeProduct) : null,
      );
    }).toList()..sort((a, b) => a.type.index.compareTo(b.type.index));
    return plans;
  }

  /// Un fallo al consultar la elegibilidad no impide mostrar los planes: solo
  /// se omite la prueba gratis.
  Future<Map<String, IntroEligibility>> _trialEligibility(
    List<Package> packages,
  ) async {
    final withTrial = packages
        .where((p) => _freeTrialDays(p.storeProduct) != null)
        .map((p) => p.storeProduct.identifier)
        .toList();
    if (withTrial.isEmpty) return const {};
    try {
      return await _gateway.introEligibility(withTrial);
    } catch (e) {
      debugPrint('No se pudo consultar la elegibilidad de la prueba: $e');
      return const {};
    }
  }

  /// Días de la oferta de introducción si es una prueba gratis (precio 0).
  static int? _freeTrialDays(StoreProduct product) {
    final intro = product.introductoryPrice;
    if (intro == null || intro.price != 0) return null;
    final days = switch (intro.periodUnit) {
      PeriodUnit.day => intro.periodNumberOfUnits,
      PeriodUnit.week => intro.periodNumberOfUnits * 7,
      PeriodUnit.month => intro.periodNumberOfUnits * 30,
      PeriodUnit.year => intro.periodNumberOfUnits * 365,
      PeriodUnit.unknown => 0,
    };
    return days > 0 ? days : null;
  }

  @override
  Future<PurchaseOutcome> purchase(SubscriptionPlan plan) async {
    final package = _packagesById[plan.id];
    if (!_isConfigured || package == null) {
      throw const SubscriptionException(
        AppErrorCode.purchaseFailed,
        'unknown_plan',
      );
    }
    await _ensureIdentified();
    try {
      final hasPro = await _gateway.purchasePackage(package);
      _setSubscribed(hasPro);
      if (!hasPro) {
        throw const SubscriptionException(
          AppErrorCode.purchaseFailed,
          'entitlement_inactive',
        );
      }
      return PurchaseOutcome.purchased;
    } on PlatformException catch (e) {
      final code = _errorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      throw SubscriptionException(_appErrorCode(code), code.name);
    }
  }

  @override
  Future<bool> restore() async {
    if (!_isConfigured) {
      throw const SubscriptionException(
        AppErrorCode.restoreFailed,
        'not_configured',
      );
    }
    await _ensureIdentified();
    try {
      final hasPro = await _gateway.restorePurchases();
      _setSubscribed(hasPro);
      return hasPro;
    } on PlatformException catch (e) {
      final code = _errorCode(e);
      throw SubscriptionException(
        code == PurchasesErrorCode.networkError
            ? AppErrorCode.network
            : AppErrorCode.restoreFailed,
        code.name,
      );
    }
  }

  /// `getErrorCode` hace `num.parse(e.code)` y lanza con un código no numérico
  /// (por ejemplo, un error del canal de plataforma); aquí cae a desconocido.
  static PurchasesErrorCode _errorCode(PlatformException e) {
    try {
      return PurchasesErrorHelper.getErrorCode(e);
    } on FormatException {
      return PurchasesErrorCode.unknownError;
    }
  }

  static AppErrorCode _appErrorCode(PurchasesErrorCode code) => switch (code) {
    PurchasesErrorCode.networkError ||
    PurchasesErrorCode.offlineConnectionError => AppErrorCode.network,
    _ => AppErrorCode.purchaseFailed,
  };
}
