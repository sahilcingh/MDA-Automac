import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // --- NEW IMPORT ---

import '../../auth/screens/login_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart'; // --- NEW IMPORT ---

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _ringsController;
  late AnimationController _pathController;

  @override
  void initState() {
    super.initState();

    // 1. Controls the endless rotation of the background rings
    _ringsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // 2. Controls the endless comet tracing on the 'M' logo
    _pathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // 3. Check login status and navigate after animation finishes
    _checkLoginAndNavigate();
  }

  // --- NEW: The smart navigation function ---
  Future<void> _checkLoginAndNavigate() async {
    // Wait for 3.5 seconds to let your beautiful animation play out
    await Future.delayed(const Duration(milliseconds: 3500));

    // Check device memory for the login badge
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // Ensure the widget is still on screen before navigating
    if (!mounted) return;

    // Decide which screen to go to based on the badge
    Widget nextScreen = isLoggedIn
        ? const DashboardScreen()
        : const LoginScreen();

    // Perform your beautiful smooth fade transition to the correct screen
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _ringsController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA0C8EB),
      body: Stack(
        children: [
          // Background Grid
          Positioned.fill(child: CustomPaint(painter: GridPainter())),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 4),

                    // Animated Rings & Tracing 'M' Logo
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _ringsController,
                            builder: (context, child) {
                              return CustomPaint(
                                size: const Size(220, 220),
                                painter: RingsPainter(
                                  rotation: _ringsController.value,
                                ),
                              );
                            },
                          ),
                          AnimatedBuilder(
                            animation: _pathController,
                            builder: (context, child) {
                              return CustomPaint(
                                size: const Size(100, 80),
                                painter: MPathPainter(
                                  progress: _pathController.value,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Your Company Logo Image
                    SizedBox(
                      height: 90,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Image.asset('assets/mdasoftlogo.png'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Subtitle
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: const Color(0xFF1E3A8A).withOpacity(0.2),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'INTELLIGENT WORKFLOW ENGINE',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF1E3A8A).withOpacity(0.8),
                              fontSize: 11,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: const Color(0xFF1E3A8A).withOpacity(0.2),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CUSTOM PAINTERS (Light Mode)
// -----------------------------------------------------------------------------

class RingsPainter extends CustomPainter {
  final double rotation;
  RingsPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius - 30;

    final outerPaint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final innerPaint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * math.pi);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: outerRadius),
      0,
      math.pi * 1.7,
      false,
      outerPaint,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-rotation * 2 * math.pi);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: innerRadius),
      math.pi / 2,
      math.pi * 1.5,
      false,
      innerPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(RingsPainter oldDelegate) =>
      rotation != oldDelegate.rotation;
}

class MPathPainter extends CustomPainter {
  final double progress;
  MPathPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.1, 0, size.width * 0.25, 0);
    path.quadraticBezierTo(
      size.width * 0.4,
      0,
      size.width * 0.5,
      size.height * 0.6,
    );
    path.quadraticBezierTo(size.width * 0.6, 0, size.width * 0.75, 0);
    path.quadraticBezierTo(size.width * 0.9, 0, size.width, size.height);

    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, bgPaint);

    final metrics = path.computeMetrics().first;
    final length = metrics.length;

    final currentPoint = length * progress;
    final trailLength = length * 0.25;

    double tailPoint = currentPoint - trailLength;
    if (tailPoint < 0) tailPoint = 0;

    final activePath = metrics.extractPath(tailPoint, currentPoint);

    final cyanPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.transparent, Color(0xFF00B8D4)],
      ).createShader(activePath.getBounds())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.saveLayer(activePath.getBounds().inflate(20), Paint());
    canvas.drawPath(activePath, cyanPaint);
    canvas.drawPath(
      activePath,
      cyanPaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.restore();

    final inverseProgress = 1.0 - progress;
    final orangeCurrentPoint = length * inverseProgress;
    double orangeTailPoint = orangeCurrentPoint + trailLength;
    if (orangeTailPoint > length) orangeTailPoint = length;

    final orangeActivePath = metrics.extractPath(
      orangeCurrentPoint,
      orangeTailPoint,
    );

    final orangePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF7A00), Colors.transparent],
      ).createShader(orangeActivePath.getBounds())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.saveLayer(orangeActivePath.getBounds().inflate(20), Paint());
    canvas.drawPath(orangeActivePath, orangePaint);
    canvas.drawPath(
      orangeActivePath,
      orangePaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(MPathPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..strokeWidth = 1.0;

    const spacing = 45.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
