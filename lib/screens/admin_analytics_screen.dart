import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  final User currentUser;
  const AdminAnalyticsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final primaryColor = const Color(0xFFFFD700); // Gold

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) return Center(child: Text('Error: ${userSnapshot.error}', style: TextStyle(color: textColor)));
          if (userSnapshot.connectionState == ConnectionState.waiting || !userSnapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }

          final users = userSnapshot.data!.docs
              .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

          final totalUsers = users.length;
          final activeUsers = users.where((u) => u.isActive).length;
          final adminUsers = users.where((u) => u.isAdmin).length;
          final regularUsers = totalUsers - adminUsers;
          final totalExpenses = users.fold<int>(0, (acc, user) => acc + user.totalExpenses);
          final totalGroups = users.fold<int>(0, (acc, user) => acc + user.groupsJoined);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("System Vitals", textColor),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: (MediaQuery.of(context).size.width / 2) / 160,
                  children: [
                    _buildGlassStatCard('Registry', totalUsers.toString(), Icons.people_outline, primaryColor, isDark),
                    _buildGlassStatCard('Active', activeUsers.toString(), Icons.verified_user_outlined, Colors.greenAccent, isDark),
                    _buildGlassStatCard('Expenses', totalExpenses.toString(), Icons.receipt_long_rounded, Colors.amberAccent, isDark),
                    _buildGlassStatCard('Groups', totalGroups.toString(), Icons.groups_rounded, Colors.lightBlueAccent, isDark),
                  ],
                ),
                const SizedBox(height: 32),
                _buildGlassDistributionCard('Authorization Levels', [
                  _DistributionItem('Administrators', adminUsers, primaryColor),
                  _DistributionItem('Standard Users', regularUsers, isDark ? Colors.white70 : Colors.grey),
                ], isDark, textColor),
                const SizedBox(height: 32),
                _buildSectionHeader("Performance Leaders", textColor),
                const SizedBox(height: 16),
                _buildMostActiveUsersList(users, isDark, textColor, primaryColor),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Text(title, style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 0.5));
  }

  Widget _buildGlassStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1C).withOpacity(0.6) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, 
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: color)
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(title, 
                  style: GoogleFonts.manrope(fontSize: 10, color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.6), fontWeight: FontWeight.w500)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassDistributionCard(String title, List<_DistributionItem> items, bool isDark, Color textColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1C).withOpacity(0.6) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 16),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item.label, style: GoogleFonts.manrope(fontSize: 13, color: textColor.withOpacity(0.7)))),
                    Text(item.count.toString(), style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: item.color)),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMostActiveUsersList(List<User> users, bool isDark, Color textColor, Color primaryColor) {
    final sortedUsers = List<User>.from(users)..sort((a, b) => b.totalExpenses.compareTo(a.totalExpenses));
    final topUsers = sortedUsers.take(5).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1C).withOpacity(0.6) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? primaryColor.withOpacity(0.15) : Colors.grey.withOpacity(0.2)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topUsers.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: textColor.withOpacity(0.05)),
            itemBuilder: (context, index) {
              final user = topUsers[index];
              return ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: _getRankColor(index, primaryColor).withOpacity(0.2), shape: BoxShape.circle),
                  child: Center(child: Text('${index + 1}', style: TextStyle(color: _getRankColor(index, primaryColor), fontWeight: FontWeight.bold))),
                ),
                title: Text(user.name, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                subtitle: Text('${user.totalExpenses} entries • ${user.groupsJoined} groups', style: GoogleFonts.manrope(fontSize: 12, color: textColor.withOpacity(0.5))),
                trailing: Icon(user.isAdmin ? Icons.verified_user_rounded : Icons.person_outline_rounded, size: 18, color: textColor.withOpacity(0.3)),
              );
            },
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int index, Color primaryColor) {
    if (index == 0) return const Color(0xFFFFD700); // Gold
    if (index == 1) return const Color(0xFFC0C0C0); // Silver
    if (index == 2) return const Color(0xFFCD7F32); // Bronze
    return primaryColor.withOpacity(0.7);
  }
}

class _DistributionItem {
  final String label;
  final int count;
  final Color color;
  _DistributionItem(this.label, this.count, this.color);
}
