import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'data/models/article_model.dart';
import 'data/models/news_source_model.dart';
import 'domain/usecases/maintenance/run_maintenance.dart';
import 'presentation/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(NewsSourceModelAdapter());
  Hive.registerAdapter(ArticleModelAdapter());
  await Hive.openBox<NewsSourceModel>(AppConstants.hiveSourcesBox);
  await Hive.openBox<ArticleModel>(AppConstants.hiveArticlesBox);
  await Hive.openBox<dynamic>(AppConstants.hiveSettingsBox);

  // 2. Setup dependency injection
  await setupDependencies();

  // 3. Run maintenance silently on startup
  await getIt<RunMaintenance>().execute();

  runApp(App(themeCubit: getIt()));
}
