import 'dart:math';
import 'package:flutter/material.dart';

class PremiumBackground extends StatefulWidget {
  final Widget child;
  final bool animate;
  final bool showParticles;

  const PremiumBackground({
    super.key,
    required this.child,
    this.animate = true,
    this.showParticles = true,
  });

  @override
  State<PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<PremiumBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _particleController;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Slower, more subtle for general use
    );

    if (widget.animate) {
      _particleController.repeat();
    }

    if (widget.showParticles) {
      for (int i = 0; i < 15; i++) {
        _particles.add(Particle(random: _random));
      }
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Dynamic Gradient Background
        AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF000000), // Pure Black
                    Color.lerp(
                        const Color(0xFF1A1A1A), // Charcoal
                        const Color(0xFF2D2D2D), // Soft Gray
                        0.5 + 0.5 * sin(_particleController.value * pi))!,
                    const Color(0xFF0A0A0A), // Deep Black
                  ],
                  // Subtle rotation for "alive" feel
                  transform: GradientRotation(_particleController.value * pi / 16), 
                ),
              ),
            );
          },
        ),

        // 2. Animated Particles
        if (widget.showParticles)
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(_particles, _particleController.value),
                size: Size.infinite,
              );
            },
          ),

        // 3. Child Content
        widget.child,
      ],
    );
  }
}

class Particle {
  late double x;
  late double y;
  late double radius;
  late double speed;
  late double theta;
  final Random random;

  Particle({required this.random}) {
    reset();
  }

  void reset() {
    x = random.nextDouble();
    y = random.nextDouble();
    radius = random.nextDouble() * 2 + 1; // Slightly smaller than splash
    speed = random.nextDouble() * 0.05 + 0.02; // Slower speed
    theta = random.nextDouble() * 2 * pi;
  }

  void update() {
    x += speed * cos(theta) * 0.01;
    y += speed * sin(theta) * 0.01;

    if (x < 0 || x > 1 || y < 0 || y > 1) {
      reset();
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.15) // Radiant Gold
      ..style = PaintingStyle.fill;
    
    final accentPaint = Paint()
      ..color = const Color(0xFFFFC107).withOpacity(0.2) // Bright Amber Gold
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < particles.length; i++) {
        var particle = particles[i];
      particle.update();
      final offset = Offset(particle.x * size.width, particle.y * size.height);
      
      // Mix of Gold and Amber particles
      if (i % 2 == 0) {
         canvas.drawCircle(offset, particle.radius, accentPaint);
      } else {
         canvas.drawCircle(offset, particle.radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
