import 'dart:io'; // For Platform check
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart'; // ✅ WebView import

import 'core/constants/theme_constants.dart';
import 'core/services/news_service.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_services.dart';


import 'features/weather/screens/home_screen.dart';
import 'features/weather/providers/weather_provider.dart';
import 'features/weather/providers/forecast_provider.dart';
import 'features/weather/providers/MultiCityWeatherProvider.dart';
import 'features/weather/providers/alert_provider.dart';


import 'features/news/providers/news_provider.dart';
import 'features/news/data/repositories/news_repository.dart';
import 'features/news/models/articles_model.dart'; // ✅ Article + Source models
import 'features/news/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Notification Services
  await NotificationService.initialize();

  // ✅ Initialize Hive
  await Hive.initFlutter();

  // ✅ Register Hive Adapters
  Hive.registerAdapter(ArticleAdapter());
  Hive.registerAdapter(SourceAdapter()); // ✅ Required for nested `Source`

  // ✅ Open bookmarks box
  await Hive.openBox<Article>('bookmarks');

  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WeatherProvider()..fetchWeather()),
        ChangeNotifierProvider(create: (_) => ForecastProvider()),
        ChangeNotifierProvider(create: (_) => MultiCityWeatherProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(
          create: (_) => NewsProvider(
            NewsRepository(NewsService()),
          ),
        ),
      ],

      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'Weather App',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.system,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
