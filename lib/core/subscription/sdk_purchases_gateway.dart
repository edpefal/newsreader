import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:newsreader/core/subscription/purchases_gateway.dart';

/// Entitlement de RevenueCat que desbloquea las funciones premium. Debe
/// coincidir con `ENTITLEMENT_ID` de las Edge Functions de `entitlements`.
const proEntitlementId = 'pro';

class SdkPurchasesGateway implements PurchasesGateway {
  const SdkPurchasesGateway();

  static bool _hasPro(CustomerInfo info) =>
      info.entitlements.active.containsKey(proEntitlementId);

  @override
  Future<void> configure(String apiKey) =>
      Purchases.configure(PurchasesConfiguration(apiKey));

  @override
  Future<bool> hasProEntitlement() async =>
      _hasPro(await Purchases.getCustomerInfo());

  @override
  void addProEntitlementListener(void Function(bool hasPro) listener) {
    Purchases.addCustomerInfoUpdateListener((info) => listener(_hasPro(info)));
  }

  @override
  Future<bool> logIn(String userId) async =>
      _hasPro((await Purchases.logIn(userId)).customerInfo);

  @override
  Future<bool> logOut() async => _hasPro(await Purchases.logOut());

  @override
  Future<List<Package>> currentOfferingPackages() async =>
      (await Purchases.getOfferings()).current?.availablePackages ?? const [];

  @override
  Future<Map<String, IntroEligibility>> introEligibility(
    List<String> productIds,
  ) => Purchases.checkTrialOrIntroductoryPriceEligibility(productIds);

  @override
  Future<bool> purchasePackage(Package package) async => _hasPro(
    (await Purchases.purchase(PurchaseParams.package(package))).customerInfo,
  );

  @override
  Future<bool> restorePurchases() async =>
      _hasPro(await Purchases.restorePurchases());
}
