import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/oko_colors.dart';
import 'core/splashscreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OkoApp());
}

/// التطبيق: oko — كشف الحروف من الصور.
class OkoApp extends StatelessWidget {
  const OkoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // اسم التطبيق: oko
      title: 'oko',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // خط عادي للواجهة كلها (بدون أي خطوط مخصصة للعناوين)
        scaffoldBackgroundColor: OkoColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: OkoColors.primary,
        ).copyWith(surface: OkoColors.surface),
        appBarTheme: const AppBarTheme(
          backgroundColor: OkoColors.primary,
          foregroundColor: OkoColors.buttonText,
          centerTitle: true,
          elevation: 0,
          toolbarHeight: 64,
          // شريط عنبري فاصل أسفل الشريط — لمسة هندسية
          shape: Border(
            bottom: BorderSide(color: OkoColors.accent, width: 3),
          ),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: OkoColors.primary,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: OkoColors.ink,
          contentTextStyle: TextStyle(color: OkoColors.buttonText),
        ),
      ),
      // واجهة عربية بالكامل (من اليمين لليسار)
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const SplashScreen(),
    );
  }
}
