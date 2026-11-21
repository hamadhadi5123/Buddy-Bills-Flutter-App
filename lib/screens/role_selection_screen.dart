import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/premium_background.dart';

class RoleSelectionScreen extends StatelessWidget {
  final Function(bool) onRoleSelected;
  const RoleSelectionScreen({super.key, required this.onRoleSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Ensure pure black base
      body: PremiumBackground(
        showParticles: true,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        
                        // Header
                        _buildHeader(),
                        
                        const SizedBox(height: 60),
                        
                        // Role Cards
                        _buildRoleCard(
                          context,
                          title: "Standard User",
                          subtitle: "Personal Finance",
                          description: "Track expenses, split bills, and manage groups with ease.",
                          icon: Icons.person_outline_rounded,
                          isPrimary: true, // Made like Admin button as requested
                          onTap: () => onRoleSelected(false),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        _buildRoleCard(
                          context,
                          title: "Administrator",
                          subtitle: "System Management",
                          description: "Full access to analytics, user management, and system controls.",
                          icon: Icons.admin_panel_settings_outlined,
                          isPrimary: true,
                          onTap: () => onRoleSelected(true),
                        ),
                        
                        const SizedBox(height: 60),
                      ],
                    ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App Icon
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0F0F0F),
            border: Border.all(
              color: const Color(0xFFFFD700),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
               filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
               child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 45,
                color: Color(0xFFFFD700),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        
        // Title
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFF7EF8A),
              Color(0xFFD4AF37),
              Color(0xFFC5A028),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            "BUDDY BILLS",
            style: GoogleFonts.cinzel(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Subtitle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.2)),
            color: Colors.black.withOpacity(0.3),
          ),
          child: Text(
            "CHOOSE YOUR ACCESS LEVEL",
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: const Color(0xFFFFD700).withOpacity(0.9),
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        constraints: const BoxConstraints(minHeight: 160), 
        child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  // Always Gold since user requested "like admin button" for both
                  color: const Color(0xFFFFD700).withValues(alpha: 0.6), 
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF202020).withValues(alpha: 0.9),
                    const Color(0xFF101010).withValues(alpha: 0.95)
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Box
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0F0F),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                              width: 1,
                            ),
                            boxShadow: [
                               BoxShadow(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: const Color(0xFFFFD700),
                            size: 30,
                          ),
                        ),
                        
                        const SizedBox(width: 20),
                        
                        // Text Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.cinzel( // Consistent font
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFFD700),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                description,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // Arrow
                         Padding(
                           padding: const EdgeInsets.only(top: 20),
                           child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                            size: 16,
                           ),
                         ),
                      ],
                    ),
                  ),
                ),
            ),
          ),
        ),
      );
    }
  }
