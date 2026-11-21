import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'premium_background.dart';


class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final bool isDarkMode;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.05,
    this.borderRadius = 24,
    this.borderColor,
    this.padding,
    this.isDarkMode = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color ?? (isDarkMode 
                ? const Color(0xFF1C1C1C).withOpacity(0.7) // Dark luxury glass
                : Colors.white.withOpacity(0.95)),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? (isDarkMode 
                  ? const Color(0xFFFFD700).withOpacity(0.4) // Prominent Gold border
                  : const Color(0xFFFFD700).withOpacity(0.6)),
              width: 1.5, // Thicker for luxury feel
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.15), // Gold glow
                blurRadius: 25,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4), // Deep shadow
                blurRadius: 15,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;
  final Color color;
  final bool isDarkMode;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    required this.color,
    this.isDarkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLightBackground = color.computeLuminance() > 0.45;
    final Color contentColor = isLightBackground ? const Color(0xFF0F172A) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35), // Glow effect
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: icon != null ? Icon(icon, size: 20, color: contentColor) : const SizedBox.shrink(),
            label: Text(
              label, 
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, 
                fontSize: 16,
                color: contentColor,
                letterSpacing: 0.3,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withOpacity(0.95), // Very solid for professionalism
              foregroundColor: contentColor,
              elevation: 4, // Slight lift
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isLightBackground ? Colors.black.withOpacity(0.15) : Colors.white.withOpacity(0.3)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final bool isDarkMode;

  const GlassDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.isDarkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
    
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        content: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A1A2E).withOpacity(0.8) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
            ),
          ),
          child: Stack(
            children: [
               // Subtle inner glow/detail
               Positioned(
                 top: -50, right: -50,
                 child: Container(
                   width: 100, height: 100,
                   decoration: BoxDecoration(shape: BoxShape.circle, color: isDarkMode ? Colors.blue.withOpacity(0.1) : Colors.amber.withOpacity(0.1)),
                 ),
               ),
               Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, 
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)
                    ),
                    const SizedBox(height: 16),
                    content,
                    if (actions != null) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: actions!,
                      ),
                    ],
                  ],
                ),
               ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassBackground extends StatelessWidget {
  final bool isDarkMode;
  final List<Color>? gradientColors;
  final Widget? child;

  const GlassBackground({
    super.key,
    required this.isDarkMode,
    this.gradientColors,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    // If not dark mode, we might want a lighter, cleaner look but still premium.
    // For now, let's allow PremiumBackground to handle the main ambiance if it's broadly compatible.
    // Or we stick to the requested "Surprising graphics" -> PremiumBackground everywhere.
    
    return PremiumBackground(
      
      showParticles: true, // Always show particles for that "wow" factor
      child: Container(
        // Overlay for light mode readability if needed, or tinting
        color: isDarkMode ? Colors.transparent : Colors.white.withOpacity(0.85),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
