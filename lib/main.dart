import 'dart:io';

import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/provider/provider.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/routes.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:dngmsp/app/viewmodel/http_overrides.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await IotSharedPreferences().get().then((prefs) {
    HttpOverrides.global = IotHttpOverrides();
    runApp(
      MultiProvider(
        providers: iotMultiProvider,
        child: MainApp(preferences: prefs),
      ),
    );
  });
}

class MainApp extends StatelessWidget {
  final List<String> preferences;
  MainApp({required this.preferences});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(1080, 1920),
      builder: (context, widget) => MaterialApp(
        title: IOT_DESCRIPTION,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('en', ''), // English, no country code
          const Locale('vi', ''), // Vietnamese, no country code
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: IOT_BG_COLOR).copyWith(
            primary: IOT_BG_COLOR,
            secondary: IOT_FG_COLOR,
            surface: Colors.white,
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: IOT_BG_COLOR,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            surfaceTintColor: Colors.transparent,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: IOT_BG_COLOR,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        initialRoute: (preferences.isEmpty
            ? IotRoutes.LOGIN_PAGE
            : IotRoutes.HOME_PAGE),
        onGenerateRoute: (settings) => IotRoutes().routes(settings),
      ),
    );
  }
}
