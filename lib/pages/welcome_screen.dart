import 'dart:ui';

import 'package:flutter/material.dart';

import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  static const _logoImage = 'assets/images/app_logo.png';

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return _SceneBackground(progress: _controller.value);
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
              child: Column(
                children: [
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final pulse =
                          1 + ((_controller.value - 0.5).abs() * -0.04);
                      return Transform.scale(scale: pulse, child: child);
                    },
                    child: const _LogoHero(),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Highway TollPay',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 310),
                    child: Text(
                      'Fast and cashless highway payments with a smoother start to every trip.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFFD4D7E5),
                        height: 1.55,
                      ),
                    ),
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF131722),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Get Started'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneBackground extends StatelessWidget {
  const _SceneBackground({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF06111F),
                const Color(0xFF090A17),
                const Color(0xFF020409),
              ],
            ),
          ),
        ),
        Positioned(
          top: -80,
          left: -40,
          child: _GlowBlob(
            size: 260,
            color: const Color(0xFF3FC6FF).withValues(alpha: 0.16),
          ),
        ),
        Positioned(
          top: 80,
          right: -70,
          child: _GlowBlob(
            size: 320,
            color: const Color(0xFF846BFF).withValues(alpha: 0.20),
          ),
        ),
        Positioned(
          bottom: -90,
          left: -10,
          child: _GlowBlob(
            size: 260,
            color: const Color(0xFF143A64).withValues(alpha: 0.24),
          ),
        ),
        const Positioned.fill(child: IgnorePointer(child: SizedBox.expand())),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _LanePatternPainter(progress: progress),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.1, -0.15),
              radius: 0.9,
              colors: [
                const Color(0xFFB89CFF).withValues(alpha: 0.12),
                const Color(0x00000000),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.10),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.28),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

class _LanePatternPainter extends CustomPainter {
  const _LanePatternPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF6D58B2).withValues(alpha: 0.10);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
      ..color = const Color(0xFF7D93FF).withValues(alpha: 0.18);

    final laneEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFF88A5D7).withValues(alpha: 0.16);

    final tollGatePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFB9C8FF).withValues(alpha: 0.12);

    for (double i = -size.width; i < size.width * 1.6; i += 72) {
      canvas.drawLine(
        Offset(i, size.height * 0.66),
        Offset(i + size.width * 0.55, size.height),
        gridPaint,
      );
    }

    for (double i = -40; i < size.width * 1.4; i += 82) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + size.width * 0.72, size.height * 0.6),
        gridPaint,
      );
    }

    final lanePath = Path()
      ..moveTo(size.width * 0.12, size.height)
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.78,
        size.width * 0.52,
        size.height * 0.52,
      )
      ..quadraticBezierTo(
        size.width * 0.64,
        size.height * 0.30,
        size.width * 0.88,
        0,
      );

    final companionLane = Path()
      ..moveTo(size.width * 0.22, size.height)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.80,
        size.width * 0.57,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.69,
        size.height * 0.34,
        size.width * 0.96,
        size.height * 0.05,
      );

    canvas.drawPath(lanePath, glowPaint);
    canvas.drawPath(companionLane, laneEdgePaint);

    final gateY = size.height * 0.18;
    canvas.drawLine(
      Offset(size.width * 0.42, gateY),
      Offset(size.width * 0.9, gateY),
      tollGatePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.48, gateY),
      Offset(size.width * 0.48, gateY + 24),
      tollGatePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.84, gateY),
      Offset(size.width * 0.84, gateY + 24),
      tollGatePaint,
    );

    final laneMetric = lanePath.computeMetrics().firstOrNull;
    final companionMetric = companionLane.computeMetrics().firstOrNull;

    if (laneMetric != null) {
      _drawLaneDashes(
        canvas,
        laneMetric,
        color: const Color(0xFFD7E6FF),
        speedOffset: 0.0,
      );
    }

    if (companionMetric != null) {
      _drawLaneDashes(
        canvas,
        companionMetric,
        color: const Color(0xFFFFE5B1),
        speedOffset: 0.38,
      );
    }

    _drawTollSweep(
      canvas,
      size,
      lanePath: lanePath,
      glowColor: const Color(0xFF8ED9FF),
    );
  }

  void _drawLaneDashes(
    Canvas canvas,
    PathMetric metric, {
    required Color color,
    required double speedOffset,
  }) {
    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5)
      ..color = color.withValues(alpha: 0.5);

    final dashLength = metric.length * 0.05;
    final gap = metric.length * 0.17;
    final shift = ((1 - progress + speedOffset) % 1) * gap;

    for (
      double distance = -dashLength + shift;
      distance < metric.length + dashLength;
      distance += gap
    ) {
      final start = distance.clamp(0.0, metric.length);
      final end = (distance + dashLength).clamp(0.0, metric.length);
      if (end > start) {
        canvas.drawPath(metric.extractPath(start, end), segmentPaint);
      }
    }
  }

  void _drawTollSweep(
    Canvas canvas,
    Size size, {
    required Path lanePath,
    required Color glowColor,
  }) {
    final sweepY = size.height * (0.14 + (progress * 0.16));
    final beamPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              glowColor.withValues(alpha: 0),
              glowColor.withValues(alpha: 0.34),
              glowColor.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(
            Rect.fromLTWH(
              size.width * 0.34,
              sweepY - 20,
              size.width * 0.62,
              40,
            ),
          )
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawLine(
      Offset(size.width * 0.36, sweepY),
      Offset(size.width * 0.92, sweepY),
      beamPaint,
    );

    final gateGlow = Paint()
      ..color = glowColor.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(size.width * 0.84, sweepY), 14, gateGlow);

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..color = glowColor.withValues(alpha: 0.14);
    canvas.drawPath(lanePath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _LanePatternPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _LogoHero extends StatelessWidget {
  const _LogoHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7E68F8).withValues(alpha: 0.28),
                blurRadius: 56,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
        Container(
          width: 176,
          height: 176,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFE8E4FF)],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.58),
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFF5F3FF)],
              ),
              border: Border.all(color: const Color(0xFFD7D2F7), width: 1.4),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                WelcomeScreen._logoImage,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
