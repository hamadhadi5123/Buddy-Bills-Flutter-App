import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
import '../models/user.dart';
import '../models/user_activity.dart';
import '../services/user_activity_service.dart';
import 'admin_analytics_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'auth_wrapper.dart';
import '../models/group.dart';
import 'create_group_screen.dart';
import '../services/database_service.dart';
import '../widgets/premium_background.dart';
import 'group_detail_screen.dart';
import 'admin_announcements_screen.dart';
import 'admin_support_management_screen.dart';

class EnhancedAdminDashboard extends StatefulWidget {
  final User currentUser;

  const EnhancedAdminDashboard({super.key, required this.currentUser});

  @override
  State<EnhancedAdminDashboard> createState() => _EnhancedAdminDashboardState();
}

class _EnhancedAdminDashboardState extends State<EnhancedAdminDashboard> with SingleTickerProviderStateMixin {
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
  
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController uidCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController searchCtrl = TextEditingController();
  
  bool isAdminSwitch = false;
  bool isActiveSwitch = true;
  String searchQuery = '';
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    uidCtrl.dispose();
    phoneCtrl.dispose();
    searchCtrl.dispose();
    super.dispose();
  }

  void _showUserDialog({User? user}) {
    // Dynamic styling for dialog
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = const Color(0xFFFFD700);

    if (user != null) {
      nameCtrl.text = user.name;
      emailCtrl.text = user.email;
      passwordCtrl.clear(); // Clear password for existing users
      uidCtrl.text = user.uid;
      phoneCtrl.text = user.phoneNumber ?? '';
      isAdminSwitch = user.isAdmin;
      isActiveSwitch = user.isActive;
    } else {
      nameCtrl.clear();
      emailCtrl.clear();
      passwordCtrl.clear();
      uidCtrl.clear();
      phoneCtrl.clear();
      isAdminSwitch = false;
      isActiveSwitch = true;
    }

    final isCurrentUser = user?.uid == widget.currentUser.uid;

    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: dialogBg.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: isDark ? primaryColor.withOpacity(0.3) : Colors.transparent)
              ),
              title: Text(
                  user == null ? "Add User" : (isCurrentUser ? "Edit Profile" : "Edit User"), 
                  style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: textColor)
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    _buildDialogField(nameCtrl, "Name", Icons.person_outline, isDark, primaryColor, textColor),
                    const SizedBox(height: 12),
                    _buildDialogField(emailCtrl, "Email", Icons.email_outlined, isDark, primaryColor, textColor),
                    if (user == null) ...[
                      const SizedBox(height: 12),
                      _buildDialogField(passwordCtrl, "Password", Icons.lock_outline, isDark, primaryColor, textColor, isPassword: true),
                    ],
                    const SizedBox(height: 12),
                    _buildDialogField(phoneCtrl, "Phone", Icons.phone_outlined, isDark, primaryColor, textColor),
                    if (user == null) ...[
                      const SizedBox(height: 12),
                      _buildDialogField(uidCtrl, "UID (Optional)", Icons.key_outlined, isDark, primaryColor, textColor),
                    ],
                    const SizedBox(height: 16),
                    _buildDialogSwitch("Administrator", isAdminSwitch, isCurrentUser ? null : (val) => setDialogState(() => isAdminSwitch = val), textColor, primaryColor),
                    _buildDialogSwitch("Active Account", isActiveSwitch, isCurrentUser ? null : (val) => setDialogState(() => isActiveSwitch = val), textColor, primaryColor),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: textColor.withOpacity(0.6))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _saveUser(user);
                  },
                  child: const Text("Save"),
                )
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildDialogField(TextEditingController ctrl, String label, IconData icon, bool isDark, Color primaryColor, Color textColor, {bool isPassword = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        prefixIcon: Icon(icon, size: 20, color: primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textColor.withOpacity(0.2))
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor)
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDialogSwitch(String label, bool value, Function(bool)? onChanged, Color textColor, Color activeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 14, color: textColor)),
        Switch(
            value: value, 
            onChanged: onChanged, 
            activeColor: activeColor,
            activeTrackColor: activeColor.withOpacity(0.5),
        ),
      ],
    );
  }

  Future<void> _saveUser(User? existingUser) async {
    try {
      final String uid = existingUser?.uid ?? 
          (uidCtrl.text.isNotEmpty ? uidCtrl.text : DateTime.now().millisecondsSinceEpoch.toString());
      
      final newUser = User(
        uid: uid,
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        phoneNumber: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
        isAdmin: isAdminSwitch,
        isActive: isActiveSwitch,
        role: isAdminSwitch ? 'admin' : 'user', // Explicitly sync role with isAdmin switch
        totalExpenses: existingUser?.totalExpenses ?? 0,
        groupsJoined: existingUser?.groupsJoined ?? 0,
        createdAt: existingUser?.createdAt ?? DateTime.now(),
        lastLoginAt: existingUser?.lastLoginAt,
      );

      final Map<String, dynamic> userData = newUser.toMap();

      await usersCollection.doc(uid).set(userData, SetOptions(merge: true));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User profile sync complete")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _deleteUser(String uid) async {
    try {
      if (uid == widget.currentUser.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot delete yourself!")),
        );
        return;
      }
      await usersCollection.doc(uid).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User Removed Successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showUserActivities(User user) {
      // Dynamic styling
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = const Color(0xFFFFD700);

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: dialogBg.withOpacity(0.9),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: isDark ? primaryColor.withOpacity(0.3) : Colors.transparent)
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                          Text("Activity Stream", style: GoogleFonts.manrope(fontSize: 12, color: textColor.withOpacity(0.6))),
                        ],
                      ),
                    ),
                    IconButton(icon: Icon(Icons.close_rounded, color: textColor), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                Divider(height: 32, color: textColor.withOpacity(0.1)),
                Expanded(
                  child: StreamBuilder<List<UserActivity>>(
                    stream: UserActivityService.getUserActivities(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: textColor)));
                      if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: primaryColor));

                      final activities = snapshot.data ?? [];
                      if (activities.isEmpty) return Center(child: Text('No trackable activity found', style: TextStyle(color: textColor.withOpacity(0.6))));

                      return ListView.builder(
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final activity = activities[index];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(UserActivity.getActivityIconData(activity.action), size: 18, color: primaryColor),
                            ),
                            title: Text(activity.details, style: GoogleFonts.manrope(fontSize: 14, color: textColor)),
                            subtitle: Text(_formatTimestamp(activity.timestamp), style: GoogleFonts.manrope(fontSize: 11, color: textColor.withOpacity(0.5))),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  void _logoutConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AlertDialog(
          backgroundColor: dialogBg.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("System Logout", style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: textColor)),
          content: Text("Are you ready to terminate the current administrative session?", style: GoogleFonts.manrope(color: textColor)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), 
                child: Text("Stay", style: TextStyle(color: textColor.withOpacity(0.6)))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                await auth.FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthWrapper()),
                    (route) => false,
                  );
                }
              },
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFFFD700);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text("Control Panel", style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: textColor, fontSize: 24)),
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.campaign_rounded, color: primaryColor),
            tooltip: "Broadcast Notices",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminAnnouncementsScreen(currentUser: widget.currentUser)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.support_agent_rounded, color: Color(0xFF27C46E)),
            tooltip: "Support Tickets",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminSupportManagementScreen(currentUser: widget.currentUser)),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 13),
          labelColor: primaryColor,
          unselectedLabelColor: textColor.withValues(alpha: 0.5),
          tabs: const [
            Tab(text: "Users"),
            Tab(text: "Groups"),
            Tab(text: "Insights"),
            Tab(text: "Logs"),
            Tab(text: "Profile"),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0 || _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () => _tabController.index == 0 ? _showUserDialog() : _showCreateGroupDialog(context),
              backgroundColor: primaryColor,
              child: Icon(_tabController.index == 0 ? Icons.add_rounded : Icons.group_add_rounded, color: Colors.black),
            )
          : null,
      body: Stack(
        children: [
          // Background
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
          TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildGroupsTab(),
                AdminAnalyticsScreen(currentUser: widget.currentUser),
                _buildActivityTab(),
                _buildProfileTab(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = const Color(0xFFFFD700);
    final textColor = isDark ? Colors.white : Colors.black87;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1C).withOpacity(0.6) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
              ]
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor, width: 2),
                    boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 20)],
                    color: Colors.black,
                  ),
                  child: Center(
                    child: Text(
                      widget.currentUser.name.isNotEmpty ? widget.currentUser.name[0].toUpperCase() : "A",
                      style: GoogleFonts.cinzel(fontSize: 40, color: primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(widget.currentUser.name, 
                  style: GoogleFonts.cinzel(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)
                ),
                Text("System Administrator", 
                  style: GoogleFonts.manrope(fontSize: 14, color: primaryColor)
                ),
                const SizedBox(height: 24),
                Divider(color: textColor.withOpacity(0.1)),
                const SizedBox(height: 24),
                 // Theme Switch
                 Container(
                   margin: const EdgeInsets.only(bottom: 16),
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   decoration: BoxDecoration(
                     color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                     borderRadius: BorderRadius.circular(16),
                   ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: primaryColor, size: 20),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text("Dark Appearance",
                                  style: GoogleFonts.manrope(fontSize: 14, color: textColor, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isDark,
                          activeColor: primaryColor,
                          activeTrackColor: primaryColor.withValues(alpha: 0.5),
                          onChanged: (val) => themeProvider.toggleTheme(val),
                        ),
                      ],
                    ),
                 ),

                 _buildProfileItem(Icons.email_outlined, "Email", widget.currentUser.email, textColor, primaryColor),
                 _buildProfileItem(Icons.calendar_today_outlined, "Joined", _formatDate(widget.currentUser.createdAt), textColor, primaryColor),
                 if (widget.currentUser.lastLoginAt != null)
                   _buildProfileItem(Icons.history_toggle_off_rounded, "Last Session", _formatDate(widget.currentUser.lastLoginAt!), textColor, primaryColor),
                 
                 const SizedBox(height: 16),
                 Divider(color: textColor.withOpacity(0.1)),
                 const SizedBox(height: 16),
                 
                 Row(
                   children: [
                     Expanded(child: _buildAdminStatCard("Total Managed", "\$${widget.currentUser.totalExpenses}", Icons.account_balance_wallet, primaryColor, textColor, isDark)),
                     const SizedBox(width: 12),
                     Expanded(child: _buildAdminStatCard("Active Groups", "${widget.currentUser.groupsJoined}", Icons.groups_rounded, primaryColor, textColor, isDark)),
                   ],
                 ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Admin Command Services
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1C).withOpacity(0.6) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Command Services", style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: primaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.campaign_rounded, color: primaryColor, size: 22),
                  ),
                  title: Text("Broadcast Announcements", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                  subtitle: Text("Publish urgent notices & updates", style: GoogleFonts.manrope(fontSize: 12, color: textColor.withOpacity(0.6))),
                  trailing: Icon(Icons.chevron_right_rounded, color: primaryColor),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminAnnouncementsScreen(currentUser: widget.currentUser)),
                  ),
                ),
                Divider(color: textColor.withOpacity(0.08), height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF27C46E).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.support_agent_rounded, color: Color(0xFF27C46E), size: 22),
                  ),
                  title: Text("Support Console", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                  subtitle: Text("Resolve user tickets & inquiries", style: GoogleFonts.manrope(fontSize: 12, color: textColor.withOpacity(0.6))),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF27C46E)),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminSupportManagementScreen(currentUser: widget.currentUser)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showUserDialog(user: widget.currentUser),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text("Edit Profile"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                    foregroundColor: textColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _logoutConfirmation,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text("System Logout"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value, Color textColor, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.manrope(fontSize: 12, color: textColor.withOpacity(0.5))),
                Text(value, style: GoogleFonts.manrope(fontSize: 15, color: textColor, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildUsersTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFFFD700);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: TextField(
                controller: searchCtrl,
                style: GoogleFonts.manrope(fontSize: 14, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search identifiers...',
                  hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: primaryColor),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: usersCollection.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: textColor)));
              if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) return Center(child: CircularProgressIndicator(color: primaryColor));

              var docs = snapshot.data!.docs.toList();
              // Sort and filter logic
              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                return (bData['createdAt'] ?? 0).compareTo(aData['createdAt'] ?? 0);
              });
              
              if (searchQuery.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final user = User.fromMap(data);
                  return user.name.toLowerCase().contains(searchQuery) || user.email.toLowerCase().contains(searchQuery);
                }).toList();
              }

              if (docs.isEmpty) return Center(child: Text("No records match your query", style: TextStyle(color: textColor.withOpacity(0.6))));

              return ListView.builder(
                itemCount: docs.length,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final user = User.fromMap(data);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1C1C1C).withOpacity(0.6) : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? primaryColor.withOpacity(0.15) : Colors.grey.withOpacity(0.2)),
                          ),
                          child: ExpansionTile(
                            iconColor: primaryColor,
                            collapsedIconColor: textColor.withOpacity(0.5),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (user.isAdmin ? primaryColor : Colors.grey).withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: (user.isAdmin ? primaryColor : Colors.grey).withOpacity(0.5))
                              ),
                              child: Icon(
                                user.isAdmin ? Icons.verified_user_rounded : Icons.person_rounded,
                                color: user.isAdmin ? primaryColor : (isDark ? Colors.white70 : Colors.black54),
                                size: 20,
                              ),
                            ),
                            title: Text(user.name, 
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16, color: textColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(user.email, 
                              style: GoogleFonts.manrope(fontSize: 12, color: textColor.withOpacity(0.6)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: Icon(Icons.edit_note_rounded, color: primaryColor, size: 22), onPressed: () => _showUserDialog(user: user)),
                                IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 22), onPressed: () => _confirmDelete(user)),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow('Level', user.isAdmin ? 'Global Admin' : 'Standard User', textColor),
                                    _buildInfoRow('State', user.isActive ? 'Active' : 'Restricted', textColor),
                                    _buildInfoRow('Registered', _formatDate(user.createdAt), textColor),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showUserActivities(user),
                                        icon: const Icon(Icons.history_rounded, size: 18),
                                        label: Text("History Logs", style: GoogleFonts.outfit()),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor.withOpacity(0.1),
                                          foregroundColor: primaryColor,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: primaryColor.withOpacity(0.5))),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFFFD700);
    final textColor = isDark ? Colors.white : Colors.black87;
    final db = Provider.of<DatabaseService>(context, listen: false);

    return StreamBuilder<List<User>>(
      stream: db.streamUsers(),
      builder: (context, userSnapshot) {
        final allUsers = userSnapshot.data ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('groups').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: textColor)));
            if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: primaryColor));

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) return Center(child: Text("No groups found", style: TextStyle(color: textColor.withOpacity(0.6))));

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final group = Group.fromMap(data, docs[index].id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.2))
                  ),
                  child: ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupDetailScreen(
                          group: group,
                          groupExpenses: const [],
                          groupBalances: const [],
                          allUsers: allUsers,
                          currentUserUid: widget.currentUser.uid,
                          isDarkMode: isDark,
                          onAddMember: (mUid, adderUid) async {
                            final updatedMembers = [...group.members, mUid];
                            final updatedAddedBy = Map<String, String>.from(group.memberAddedBy);
                            updatedAddedBy[mUid] = adderUid;
                            await db.updateGroup(group.copyWith(members: updatedMembers, memberAddedBy: updatedAddedBy));
                          },
                          onRemoveMember: (mUid) async {
                            final updatedMembers = group.members.where((m) => m != mUid).toList();
                            final updatedAddedBy = Map<String, String>.from(group.memberAddedBy);
                            updatedAddedBy.remove(mUid);
                            await db.updateGroup(group.copyWith(members: updatedMembers, memberAddedBy: updatedAddedBy));
                          },
                          onAddExpense: (expense) async {
                            await db.addExpense(expense);
                          },
                        ),
                      ),
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.groups_rounded, color: primaryColor, size: 20),
                    ),
                    title: Text(group.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    subtitle: Text("${group.members.length} Members • ${group.type}", style: GoogleFonts.manrope(fontSize: 12, color: textColor.withOpacity(0.6))),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      onPressed: () => _confirmDeleteGroup(group),
                    ),
                  ),
                );
              },
            );
          },
        );
      }
    );
  }

  void _confirmDeleteGroup(Group group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1C1C) : Colors.white,
        title: Text("Delete Group?", style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete '${group.name}'? This action is permanent.", style: GoogleFonts.manrope()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteGroup(group.id!);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup(String groupId) async {
    try {
      await FirebaseFirestore.instance.collection('groups').doc(groupId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Group deleted successfully")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting group: $e"), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _showCreateGroupDialog(BuildContext context) async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final created = await Navigator.push<Group?>(
      context,
      MaterialPageRoute(builder: (context) => CreateGroupScreen(currentUserUid: widget.currentUser.uid, isDarkMode: isDark))
    );

    if (created != null && mounted) {
      try {
        await db.createGroup(created.copyWith(
          members: [widget.currentUser.uid, ...created.members],
          createdBy: widget.currentUser.uid,
          memberAddedBy: created.memberAddedBy,
          createdAt: DateTime.now(),
        ));
        await UserActivityService.logGroupCreated(widget.currentUser.uid, widget.currentUser.name, created.name);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Group '${created.name}' created successfully")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error creating group: $e"), backgroundColor: Colors.redAccent));
        }
      }
    }
  }

  Widget _buildActivityTab() { 
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFFFD700);
    final textColor = isDark ? Colors.white : Colors.black87;

    return StreamBuilder<List<UserActivity>>(
      stream: UserActivityService.getAllActivities(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: textColor)));
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: primaryColor));

        final activities = snapshot.data ?? [];
        if (activities.isEmpty) return Center(child: Text('System logs are empty', style: TextStyle(color: textColor.withOpacity(0.6))));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Audit Logs (${activities.length})",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmClearAllLogs(),
                    icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18),
                    label: Text(
                      "Clear All Logs",
                      style: GoogleFonts.manrope(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18, 
                          backgroundColor: primaryColor.withOpacity(0.2), 
                          child: Text(
                            activity.userName.isNotEmpty ? activity.userName[0].toUpperCase() : '?',
                            style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(activity.userName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                              Text(activity.details, style: GoogleFonts.manrope(fontSize: 12, color: textColor.withOpacity(0.7))),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_formatTimestamp(activity.timestamp), style: GoogleFonts.manrope(fontSize: 10, color: textColor.withOpacity(0.5))),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _confirmDeleteSingleLog(activity),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent.withOpacity(0.85)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteSingleLog(UserActivity activity) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Log Entry", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        content: Text("Are you sure you want to delete this log entry?\n\n\"${activity.details}\"",
            style: GoogleFonts.manrope(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await UserActivityService.deleteActivity(activity.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? "Log entry deleted." : "Failed to delete log entry."),
                    backgroundColor: success ? const Color(0xFF1E2230) : Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAllLogs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Clear All Logs", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        content: Text("Are you sure you want to permanently delete all audit logs? This action cannot be undone.",
            style: GoogleFonts.manrope(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await UserActivityService.clearAllActivities();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? "All audit logs cleared successfully." : "Failed to clear audit logs."),
                    backgroundColor: success ? const Color(0xFF1E2230) : Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text("Clear All", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text('$label:', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 12, color: textColor.withOpacity(0.5)))),
          Expanded(child: Text(value, style: GoogleFonts.manrope(fontSize: 12, color: textColor))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  void _confirmDelete(User user) {
     final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1A2E).withOpacity(0.9) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("Confirm Removal", style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: Colors.redAccent)),
          content: Text("Are you absolutely sure you want to remove ${user.name} from the system?", 
              style: GoogleFonts.manrope(color: isDark ? Colors.white70 : Colors.black87)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), 
                child: const Text("Cancel")
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                Navigator.pop(ctx);
                _deleteUser(user.uid);
              },
              child: const Text("Terminate"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminStatCard(String label, String value, IconData icon, Color primaryColor, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          Text(label, style: GoogleFonts.manrope(fontSize: 10, color: textColor.withOpacity(0.5))),
        ],
      ),
    );
  }
}
