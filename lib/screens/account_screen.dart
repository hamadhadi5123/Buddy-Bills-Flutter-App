import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
import '../models/user.dart';
import '../services/user_activity_service.dart';
import '../widgets/glass_widgets.dart';
import 'enhanced_admin_dashboard.dart';
import 'user_support_screen.dart';
import 'user_announcements_screen.dart';
import 'admin_announcements_screen.dart';
import 'admin_support_management_screen.dart';

class AccountScreen extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;

  const AccountScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final Color primaryBrandColor = const Color(0xFFFFD700); // Premium Gold
  final Color accentGreen = const Color(0xFF27C46E);
  final Color luxuryBlack = const Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final darkMode = themeProvider.isDarkMode;
    final Color textColor = darkMode ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Account", style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildGlassProfileCard(textColor, darkMode),
            const SizedBox(height: 20),
            _buildStatsRow(textColor, darkMode),
            const SizedBox(height: 32),
            _buildSectionHeader("Management", textColor),
            if (widget.user.role.toLowerCase() == 'admin' || widget.user.isAdmin) ...[
              _buildSettingItem(
                icon: Icons.admin_panel_settings_rounded,
                title: "Admin Dashboard",
                subtitle: "User & system management",
                textColor: textColor,
                darkMode: darkMode,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EnhancedAdminDashboard(currentUser: widget.user))),
              ),
              _buildSettingItem(
                icon: Icons.campaign_rounded,
                title: "Broadcasts",
                subtitle: "Manage announcements",
                textColor: textColor,
                darkMode: darkMode,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminAnnouncementsScreen(currentUser: widget.user))),
              ),
              _buildSettingItem(
                icon: Icons.support_agent_rounded,
                title: "Support Console",
                subtitle: "Manage user requests",
                textColor: textColor,
                darkMode: darkMode,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminSupportManagementScreen(currentUser: widget.user))),
              ),
            ],
            _buildSettingItem(
              icon: Icons.campaign_rounded,
              title: "Announcements",
              subtitle: "View latest system broadcasts",
              textColor: textColor,
              darkMode: darkMode,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserAnnouncementsScreen(currentUser: widget.user))),
            ),
            _buildSettingItem(
              icon: Icons.help_center_rounded,
              title: "Support Center",
              subtitle: "Get help & feedback",
              textColor: textColor,
              darkMode: darkMode,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserSupportScreen(currentUser: widget.user))),
            ),
            _buildSettingItem(
              icon: Icons.lock_reset_rounded,
              title: "Reset Password",
              subtitle: "Send secure reset link to email",
              textColor: textColor,
              darkMode: darkMode,
              onTap: () async {
                if (widget.user.email.isEmpty) {
                  _infoSnack("No email associated with account");
                  return;
                }
                try {
                  await fb.FirebaseAuth.instance.sendPasswordResetEmail(email: widget.user.email);
                  _infoSnack("Password reset email sent to ${widget.user.email}");
                } catch (e) {
                  _infoSnack("Reset failed: ${e.toString()}");
                }
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader("Preferences", textColor),
            _buildSettingItem(
              icon: Icons.dark_mode_rounded,
              title: "Dark Appearance",
              textColor: textColor,
              darkMode: darkMode,
              trailing: Switch(
                value: darkMode,
                activeColor: accentGreen,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
              ),
            ),
            _buildSettingItem(
              icon: Icons.translate_rounded,
              title: "Language",
              subtitle: "English (Default)",
              textColor: textColor,
              darkMode: darkMode,
              onTap: () => _infoSnack("Localization coming soon!"),
            ),
            const SizedBox(height: 40),
            _buildLogoutButton(darkMode),
            const SizedBox(height: 24),
            Text("Buddy Bills Premium v1.2.5", style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.3))),
            const SizedBox(height: 4),
            Text("Member Since: ${_formatDate(widget.user.createdAt)}", style: GoogleFonts.poppins(fontSize: 10, color: textColor.withOpacity(0.2))),
            if (widget.user.lastLoginAt != null)
              Text("Last Active: ${_formatDate(widget.user.lastLoginAt!)}", style: GoogleFonts.poppins(fontSize: 10, color: textColor.withOpacity(0.2))),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassProfileCard(Color textColor, bool darkMode) {
    return GlassCard(
      isDarkMode: darkMode,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryBrandColor, primaryBrandColor.withOpacity(0.6)]),
              shape: BoxShape.circle,
              border: Border.all(color: primaryBrandColor.withOpacity(0.5), width: 2),
              boxShadow: [BoxShadow(color: primaryBrandColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Center(
              child: Text(widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : "A", 
                style: GoogleFonts.cinzel(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.user.name, 
                  style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(widget.user.email, 
                  style: GoogleFonts.manrope(fontSize: 12, color: textColor.withOpacity(0.6)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _buildSmallBadge(widget.user.role == 'admin' ? "SYSTEM ADMIN" : "PREMIUM MEMBER", primaryBrandColor),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openEditProfileDialog(darkMode),
            icon: Icon(Icons.edit_note_rounded, color: primaryBrandColor, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Color textColor, bool darkMode) {
    return Row(
      children: [
        Expanded(child: _buildStatItem("Spent", "\$${widget.user.totalExpenses}", Icons.account_balance_wallet_outlined, textColor, darkMode)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem("Groups", "${widget.user.groupsJoined}", Icons.groups_outlined, textColor, darkMode)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem("Status", widget.user.isActive ? "Active" : "Inactive", Icons.verified_outlined, textColor, darkMode)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color textColor, bool darkMode) {
    return GlassCard(
      isDarkMode: darkMode,
      padding: const EdgeInsets.symmetric(vertical: 16),
      borderRadius: 20,
      child: Column(
        children: [
          Icon(icon, color: primaryBrandColor, size: 20),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          Text(label, style: GoogleFonts.manrope(fontSize: 10, color: textColor.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: textColor.withOpacity(0.1))),
        ],
      ),
    );
  }

  Widget _buildSettingItem({required IconData icon, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap, required Color textColor, required bool darkMode}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDarkMode: darkMode,
        padding: EdgeInsets.zero,
        borderRadius: 18,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: primaryBrandColor),
          title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor)),
          subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.5))) : null,
          trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textColor.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(bool darkMode) {
    return GlassButton(
      onPressed: () => _logoutConfirmation(darkMode),
      label: "Sign Out",
      icon: Icons.logout_rounded,
      color: Colors.redAccent,
      isDarkMode: darkMode,
    );
  }

  void _openEditProfileDialog(bool darkMode) {
    final nameCtrl = TextEditingController(text: widget.user.name);
    final phoneCtrl = TextEditingController(text: widget.user.phoneNumber ?? '');
    bool isLoading = false;
    final color = darkMode ? Colors.white : const Color(0xFF1A1A2E);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => GlassDialog(
          isDarkMode: darkMode,
          title: "Edit Profile",
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.poppins(color: color),
                decoration: InputDecoration(
                  labelText: "Full Name",
                  labelStyle: TextStyle(color: color.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.person_outline, color: primaryBrandColor),
                  filled: true,
                  fillColor: color.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneCtrl,
                style: GoogleFonts.poppins(color: color),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  labelStyle: TextStyle(color: color.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.phone_outlined, color: primaryBrandColor),
                  filled: true,
                  fillColor: color.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: TextStyle(color: color.withOpacity(0.5))),
            ),
            if (isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBrandColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final newName = nameCtrl.text.trim();
                  final newPhone = phoneCtrl.text.trim();
                  if (newName.isEmpty) return;

                  setDialogState(() => isLoading = true);
                  await _updateProfile(newName, newPhone);
                  setDialogState(() => isLoading = false);
                  Navigator.pop(ctx);
                },
                child: const Text("Save Changes"),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile(String newName, String newPhone) async {
    try {
      final updatedUser = User(
        uid: widget.user.uid,
        name: newName,
        email: widget.user.email,
        isAdmin: widget.user.isAdmin,
        isActive: widget.user.isActive,
        phoneNumber: newPhone.isEmpty ? null : newPhone,
        profilePictureUrl: widget.user.profilePictureUrl,
        role: widget.user.role,
        totalExpenses: widget.user.totalExpenses,
        groupsJoined: widget.user.groupsJoined,
        createdAt: widget.user.createdAt,
        lastLoginAt: widget.user.lastLoginAt,
      );
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update(updatedUser.toMap());
      final firebaseUser = fb.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) await firebaseUser.updateDisplayName(newName);
      await UserActivityService.logProfileUpdated(widget.user.uid, newName);
      _infoSnack("Profile updated successfully!");
    } catch (e) {
      _infoSnack("Update failed: $e");
    }
  }

  void _logoutConfirmation(bool darkMode) {
    showDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        isDarkMode: darkMode,
        title: "Sign Out",
        content: Text("Are you sure you want to log out of Buddy Bills?", style: GoogleFonts.poppins(color: darkMode ? Colors.white : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Stay", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onLogout();
            },
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );
  }

  void _infoSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
