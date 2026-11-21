import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/group.dart';
import '../services/database_service.dart';
import '../models/user.dart' as model;
import '../widgets/premium_background.dart';

class CreateGroupScreen extends StatefulWidget {
  final bool isDarkMode;
  final String currentUserUid;
  const CreateGroupScreen({super.key, required this.currentUserUid, this.isDarkMode = true});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController groupNameCtrl = TextEditingController();
  final TextEditingController memberEmailCtrl = TextEditingController();
  String selectedType = "Trip";
  final List<model.User> selectedUsers = [];
  bool isSearching = false;

  final List<Map<String, dynamic>> groupTypes = [
    {'name': 'Trip', 'icon': Icons.terrain_rounded, 'color': const Color(0xFFFFD700)}, // Gold
    {'name': 'Home', 'icon': Icons.cottage_rounded, 'color': const Color(0xFFC0C0C0)}, // Silver
    {'name': 'Couple', 'icon': Icons.favorite_rounded, 'color': const Color(0xFFFF69B4)},
    {'name': 'Work', 'icon': Icons.business_center_rounded, 'color': const Color(0xFF4169E1)},
    {'name': 'Other', 'icon': Icons.dashboard_customize_rounded, 'color': const Color(0xFF607D8B)},
  ];

  void addMemberByEmail() async {
    final email = memberEmailCtrl.text.trim();
    if (email.isEmpty) return;

    setState(() => isSearching = true);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final user = await db.findUserByEmail(email);
    setState(() => isSearching = false);

    if (!mounted) return;
    if (user == null) {
      _snack("Hmm, we couldn't find anyone with that email.");
      return;
    }
    if (user.uid == widget.currentUserUid) {
      _snack("You are automatically included as the group creator!");
      return;
    }
    if (selectedUsers.any((u) => u.uid == user.uid)) {
      _snack("This person is already in the list!");
      return;
    }
    if (user.role == 'admin') {
      _snack("Cannot add admin users to groups.");
      return;
    }
    setState(() {
      selectedUsers.add(user);
      memberEmailCtrl.clear();
    });
  }

  void doneCreate() {
    final name = groupNameCtrl.text.trim();
    if (name.isEmpty) { _snack("Give your group a fun name!"); return; }
    if (selectedUsers.isEmpty) { _snack("Groups are better with friends! Add at least one."); return; }

    final Map<String, String> memberAddedBy = {
      for (var u in selectedUsers) u.uid: widget.currentUserUid,
      widget.currentUserUid: widget.currentUserUid, // Creator added themselves
    };

    final g = Group(
      name: name,
      type: selectedType,
      members: selectedUsers.map((u) => u.uid).toList(),
      createdBy: widget.currentUserUid,
      memberAddedBy: memberAddedBy,
      createdAt: DateTime.now(),
    );
    Navigator.pop(context, g);
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(m, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFFFFD700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    )
  );

  @override
  Widget build(BuildContext context) {
    // Force dark mode for premium theme
    const isDark = true;
    final primaryColor = const Color(0xFFFFD700); // Gold
    final textColor = Colors.white;
    final cardColor = const Color(0xFF1C1C1C).withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Create Group", style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: PremiumBackground(
        showParticles: true,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF202020).withValues(alpha: 0.95),
                        const Color(0xFF101010).withValues(alpha: 0.98),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: primaryColor.withOpacity(0.6), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.15), 
                        blurRadius: 25, 
                        offset: const Offset(0, 10)
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor.withOpacity(0.3)),
                        ),
                        child: Icon(Icons.auto_awesome_rounded, color: primaryColor, size: 24).animate().rotate(),
                      ),
                      const SizedBox(height: 16),
                      Text("New Adventure", style: GoogleFonts.cinzel(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
                      const SizedBox(height: 8),
                      Text("Start a new group to split bills easily.", style: GoogleFonts.manrope(fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1),
    
                const SizedBox(height: 32),
                _buildSectionTitle("Group Identity", primaryColor),
                const SizedBox(height: 16),
                
                _buildHappyCard(
                  color: cardColor,
                  isDark: isDark,
                  borderColor: primaryColor.withOpacity(0.3),
                  child: Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1), 
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: primaryColor.withOpacity(0.3)),
                        ),
                        child: Icon(Icons.stars_rounded, color: primaryColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: groupNameCtrl,
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                          cursorColor: primaryColor,
                          decoration: InputDecoration(
                            hintText: "Give it a fun name...",
                            hintStyle: GoogleFonts.manrope(color: textColor.withOpacity(0.3), fontWeight: FontWeight.normal),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    
                const SizedBox(height: 32),
                _buildSectionTitle("Invite Friends", primaryColor),
                const SizedBox(height: 16),
                _buildHappyCard(
                  color: cardColor,
                  isDark: isDark,
                  borderColor: primaryColor.withOpacity(0.3),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                       Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: memberEmailCtrl,
                                style: GoogleFonts.manrope(fontSize: 14, color: textColor),
                                cursorColor: primaryColor,
                                decoration: InputDecoration(
                                  hintText: "Friend's email...",
                                  hintStyle: TextStyle(color: textColor.withOpacity(0.3)),
                                  prefixIcon: Icon(Icons.alternate_email_rounded, size: 18, color: primaryColor),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.3),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16), 
                                    borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.2))
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16), 
                                    borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.6))
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            isSearching 
                              ? const SizedBox(width: 48, height: 48, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700))))
                              : Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 8)
                                    ]
                                  ),
                                  child: IconButton.filled(
                                    style: IconButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      fixedSize: const Size(48, 48),
                                    ),
                                    onPressed: addMemberByEmail,
                                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 22),
                                  ),
                                )
                          ],
                        ),
                        if (selectedUsers.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedUsers.length,
                              itemBuilder: (context, index) {
                                final user = selectedUsers[index];
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: primaryColor.withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(user.name, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => setState(() => selectedUsers.removeAt(index)),
                                        child: Icon(Icons.close_rounded, size: 16, color: primaryColor.withOpacity(0.7)),
                                      ),
                                    ],
                                  ),
                                ).animate().scale();
                              },
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
    
                const SizedBox(height: 32),
                _buildSectionTitle("Group Type", primaryColor),
                const SizedBox(height: 16),
                _buildTypeGrid(primaryColor, isDark),
    
                const SizedBox(height: 48),
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFD700),
                        Color(0xFFD4AF37),
                      ],
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: doneCreate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text("CREATE GROUP", style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(title, style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: textColor));
  }

  Widget _buildHappyCard({required Widget child, required Color color, required bool isDark, required Color borderColor, EdgeInsetsGeometry padding = const EdgeInsets.all(20)}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.05), 
                blurRadius: 20, 
                offset: const Offset(0, 8)
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTypeGrid(Color primary, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: MediaQuery.of(context).size.width < 400 ? 2.0 : 2.5,
      ),
      itemCount: groupTypes.length,
      itemBuilder: (context, index) {
        final type = groupTypes[index];
        final isSelected = selectedType == type['name'];
        
        return GestureDetector(
          onTap: () => setState(() => selectedType = type['name']),
          child: AnimatedContainer(
            duration: 200.ms,
            decoration: BoxDecoration(
              color: isSelected ? primary.withOpacity(0.2) : Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? primary : Colors.white.withOpacity(0.1), 
                width: isSelected ? 2 : 1
              ),
              boxShadow: isSelected ? [BoxShadow(color: primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(type['icon'], color: isSelected ? primary : Colors.white60, size: 24),
                const SizedBox(width: 8),
                Text(type['name'], style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: isSelected ? primary : Colors.white60)),
              ],
            ),
          ),
        );
      },
    );
  }
}
