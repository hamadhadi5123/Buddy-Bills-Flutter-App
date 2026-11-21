import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_activity.dart';
import 'package:intl/intl.dart';
import '../widgets/premium_background.dart';
// import '../theme/premium_theme.dart';

class ActivityScreen extends StatelessWidget {
  final List<UserActivity>? activities;
  final bool isDarkMode;
  final String? error;
  final bool isLoading;

  const ActivityScreen({
    super.key, 
    this.activities, 
    required this.isDarkMode,
    this.error,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic Theme Logic
    final isDark = isDarkMode;
    
    // Colors based on theme
    final Color primaryColor = const Color(0xFFFFD700); // Gold
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color glassColor = isDark 
        ? const Color(0xFF1C1C1C).withOpacity(0.6) 
        : Colors.white.withOpacity(0.7);
    final Color borderColor = isDark 
        ? primaryColor.withOpacity(0.15) 
        : Colors.grey.withOpacity(0.2);
    final Color iconBoxColor = isDark 
        ? primaryColor.withOpacity(0.1) 
        : primaryColor.withOpacity(0.15); // Slightly stronger in light mode
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Activity", style: GoogleFonts.cinzel(color: textColor, fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Stack(
        children: [
          // Background - Only show Premium Particles in Dark Mode
          if (isDark)
            PremiumBackground(showParticles: true, child: Container())
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFFFFF),
                    const Color(0xFFF1F4F9),
                  ],
                ),
              ),
            ),
            
          // Content
          error != null
            ? _buildErrorState(error!, textColor)
            : isLoading || activities == null
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : activities!.isEmpty
                    ? _buildEmptyState(textColor, primaryColor)
                    : _buildActivityList(activities!, textColor, primaryColor, glassColor, borderColor, iconBoxColor),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text("Something went wrong", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Text(
              "We couldn't load your activity logs. If you just set up the app, Firestore might be creating indexes.",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(color: textColor.withOpacity(0.6), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 80, color: primaryColor.withOpacity(0.3)),
          const SizedBox(height: 24),
          Text("No activity yet", style: GoogleFonts.cinzel(fontSize: 22, color: textColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            "Your expense activities will appear here",
            style: GoogleFonts.manrope(color: textColor.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(
      List<UserActivity> list, 
      Color textColor, 
      Color primaryColor, 
      Color glassColor,
      Color borderColor,
      Color iconBoxColor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Padding for AppBar
          const SizedBox(height: 80), 
          ...list.map((activity) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: glassColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconBoxColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: primaryColor.withOpacity(0.1)),
                          ),
                          child: Icon(
                            IconData(UserActivity.getActivityIcon(activity.action), fontFamily: 'MaterialIcons'),
                            color: primaryColor, // Always Gold for brand recognition
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.userName,
                                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                activity.details,
                                style: GoogleFonts.manrope(fontSize: 12, color: textColor.withOpacity(0.7)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd • hh:mm a').format(activity.timestamp),
                                style: GoogleFonts.manrope(fontSize: 11, color: textColor.withOpacity(0.5)),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
