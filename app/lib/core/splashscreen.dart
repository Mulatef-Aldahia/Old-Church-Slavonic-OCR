import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'homescreen.dart';

/// شاشة البداية: خلفية بيضاء + موجة برتقالية + قاعدة كحلية، والشعار في المنتصف.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const int _durationSeconds = 3;

  Timer? _timer;

  /// حركة الموجة (مستمرة وهادئة).
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  /// ظهور الشعار (مرة واحدة).
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _intro, curve: Curves.easeOut);
  late final Animation<double> _scale = Tween<double>(begin: 0.85, end: 1.0)
      .animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutBack));

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: _durationSeconds), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wave.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _SplashColors.top,
        body: Stack(
          children: [
            // الخلفية والموجة
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _wave,
                builder: (context, _) => CustomPaint(
                  painter: _WavePainter(t: _wave.value),
                ),
              ),
            ),

            // الشعار في الجزء الأبيض
            Align(
              alignment: const Alignment(0, -0.32),
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: const Text(
                    'OKO',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 8,
                      color: _SplashColors.navy,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ألوان الشاشة (يمكنك ربطها بـ OkoColors لاحقاً).
class _SplashColors {
  static const Color top = Color(0xFFF7F7F9);
  static const Color navy = Color(0xFF0B0B3B);
  static const Color orange = Color(0xFFFF8A00);
  static const Color amber = Color(0xFFFFC53D);
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.t});

  /// من 0 إلى 1، دورة كاملة للموجة.
  final double t;

  /// مسار الموجة. [lift] يرفع الموجة للأعلى (لعمل الشريط البرتقالي).
  Path _wavePath(Size s, {double leftLift = 0, double rightLift = 0}) {
    final w = s.width;
    final h = s.height;
    final p = t * math.pi * 2;

    // إزاحة بسيطة تعطي إحساس التموج
    final a = math.sin(p) * h * 0.012;
    final b = math.cos(p) * h * 0.012;

    final path = Path()..moveTo(0, h * 0.55 - leftLift);
    path.cubicTo(
      w * 0.22, h * 0.72 + a - leftLift * 0.6,
      w * 0.42, h * 0.50 + b - leftLift * 0.3,
      w * 0.68, h * 0.60 - a - rightLift * 0.5,
    );
    path.cubicTo(
      w * 0.84, h * 0.66 + b - rightLift * 0.8,
      w * 0.94, h * 0.54 - a - rightLift,
      w, h * 0.52 - rightLift,
    );
    return path;
  }

  Path _closed(Path wave, Size s) => Path.from(wave)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    // 1) الخلفية العلوية
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _SplashColors.top,
    );

    // 2) الشريط البرتقالي (أسمك عند اليسار وأرفع عند اليمين)
    final orangeWave = _wavePath(size, leftLift: 26, rightLift: 8);
    canvas.drawPath(
      _closed(orangeWave, size),
      Paint()
        ..shader = const LinearGradient(
          colors: [_SplashColors.amber, _SplashColors.orange],
        ).createShader(Offset.zero & size),
    );

    // 3) القاعدة الكحلية فوق البرتقالي
    final navyWave = _wavePath(size);
    canvas.drawPath(
      _closed(navyWave, size),
      Paint()..color = _SplashColors.navy,
    );

    // 4) خط لامع رفيع على حافة الموجة
    canvas.drawPath(
      navyWave,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.t != t;
}