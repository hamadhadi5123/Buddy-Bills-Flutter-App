import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/premium_background.dart';
import 'auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Main entrance animations
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Pulse animation for logo glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _mainController.forward();

    // Navigation timer
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AuthWrapper(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Ensure base is black
      body: PremiumBackground(
        showParticles: true,
        child: Stack(
          children: [
            // Center Content
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo with Gold Glow
                    AnimatedBuilder(
                      animation: Listenable.merge([_mainController, _pulseController]),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            width: 180, // Slightly reduced from 200
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFFFD700).withOpacity(0.25), // Gold
                                  const Color(0xFFDAA520).withOpacity(0.1), // Goldenrod
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.6, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.4 * _pulseAnimation.value),
                                  blurRadius: 50 * _pulseAnimation.value,
                                  spreadRadius: 15 * _pulseAnimation.value,
                                ),
                                BoxShadow(
                                  color: const Color(0xFFB8860B).withOpacity(0.2), // Dark golden rod
                                  blurRadius: 80,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(22), // Adjusted from 25
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0F0F0F), // Very dark grey, almost black
                                border: Border.all(
                                  color: const Color(0xFFFFD700),
                                  width: 2.5,
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF2C2C2C),
                                    const Color(0xFF000000),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.8),
                                    blurRadius: 15,
                                    offset: const Offset(5, 5),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF333333).withOpacity(0.5),
                                    blurRadius: 15,
                                    offset: const Offset(-5, -5),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: const Center(
                                    child: Icon(
                                      Icons.account_balance_wallet_rounded,
                                      size: 70, // Slightly reduced from 80
                                      color: Color(0xFFFFD700),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 50), // Reduced from 70

                    // Animated Title with Luxury Gold Gradient
                    AnimatedBuilder(
                      animation: _mainController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFF7EF8A), // Light Gold
                                Color(0xFFD4AF37), // Metallic Gold
                                Color(0xFFC5A028), // Deep Gold
                                Color(0xFFF7EF8A), // Light Gold Repeat
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: [0.0, 0.4, 0.7, 1.0],
                            ).createShader(bounds),
                            child: Text(
                              'BUDDY BILLS',
                              style: GoogleFonts.cinzel( // Using Cinzel for a more premium/luxury feel if available, else Outfit
                                fontSize: 38, // Slightly reduced from 42
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16), // Reduced from 20
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), // Adjusted padding
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFFD700).withOpacity(0.0),
                                  const Color(0xFFFFD700).withOpacity(0.1),
                                  const Color(0xFFFFD700).withOpacity(0.0),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                              border: Border(
                                top: BorderSide(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
                                bottom: BorderSide(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
                              ),
                            ),
                            child: Text(
                              'ELITE EXPENSE MANAGEMENT',
                              style: GoogleFonts.montserrat(
                                fontSize: 10, // Slightly reduced from 12
                                color: const Color(0xFFFFD700),
                                letterSpacing: 3.0, // Slightly reduced from 3.5
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 60), // Reduced from 90
                    
                    // Premium Loading Indicator
                    AnimatedBuilder(
                      animation: _mainController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Column(
                            children: [
                              SizedBox(
                                width: 24, // Slightly reduced from 30
                                height: 24,
                                child: CircularProgressIndicator(
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                                  strokeWidth: 2,
                                  backgroundColor: const Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20), // Added bottom safety padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
