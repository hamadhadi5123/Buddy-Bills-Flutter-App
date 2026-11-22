import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/group.dart';
import '../models/balance.dart';
import '../services/database_service.dart';
import '../widgets/glass_widgets.dart';
import '../theme/premium_theme.dart';


class GroupsScreen extends StatelessWidget {
  final List<Group> groups;
  final VoidCallback onCreateGroup;
  final Function(Group) onOpenGroup;
  final VoidCallback onAddExpense;
  final List<Balance> overallBalances;
  final String currentUser;
  final String? currentUserUid;
  final bool isDarkMode;

  const GroupsScreen({
    super.key,
    required this.groups,
    required this.onCreateGroup,
    required this.onOpenGroup,
    required this.onAddExpense,
    required this.overallBalances,
    required this.currentUser,
    this.currentUserUid,
    required this.isDarkMode,
  });

  Color get accentGreen => PremiumTheme.accentGreen;
  Color get primaryBrandColor => PremiumTheme.goldenPrimary;

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    final double horizontalPadding = isSmallScreen ? 16 : 24;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Groups", 
          style: GoogleFonts.outfit(
            color: textColor, 
            fontWeight: FontWeight.bold,
            fontSize: 24,
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.group_add_rounded, color: primaryBrandColor, size: 28),
            onPressed: onCreateGroup,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: isSmallScreen
          ? Container(
              margin: const EdgeInsets.only(bottom: 100), // Space for bottom bar
              child: FloatingActionButton.extended(
                onPressed: onAddExpense,
                elevation: 12,
                icon: Icon(Icons.add_rounded, color: primaryBrandColor.computeLuminance() > 0.45 ? const Color(0xFF0F172A) : Colors.white, size: 24),
                label: Text(
                  "Add Expense", 
                  style: GoogleFonts.poppins(
                    color: primaryBrandColor.computeLuminance() > 0.45 ? const Color(0xFF0F172A) : Colors.white, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                backgroundColor: primaryBrandColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            )
          : null,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _welcomeCard(isSmallScreen, textColor),
            const SizedBox(height: 24),


            Text(
              "Your Active Groups",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            if (groups.isEmpty)
              _emptyState(textColor)
            else
              ...groups.map((g) => _groupCard(context, g, isSmallScreen, textColor)),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _welcomeCard(bool isSmallScreen, Color textColor) {
    double bringTotal = 0;
    double giveTotal = 0;
    for (var b in overallBalances) {
      if (b.amount > 0) {
        bringTotal += b.amount;
      } else {
        giveTotal += b.amount.abs();
      }
    }

    return GlassCard(
      isDarkMode: isDarkMode,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [primaryBrandColor, primaryBrandColor.withOpacity(0.7)]),
                  boxShadow: [
                    BoxShadow(color: primaryBrandColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: CircleAvatar(
                  radius: isSmallScreen ? 26 : 32,
                  backgroundColor: Colors.transparent,
                  child: Text(
                    currentUser[0].toUpperCase(),
                    style: GoogleFonts.outfit(
                        fontSize: isSmallScreen ? 24 : 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 16 : 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, $currentUser!",
                      style: GoogleFonts.outfit(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Managing ${groups.length} active groups",
                      style: GoogleFonts.poppins(fontSize: 13, color: textColor.withOpacity(0.6)),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text("Give", style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.5))),
                      const SizedBox(height: 4),
                      Text("PKR ${giveTotal.toStringAsFixed(0)}", 
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: textColor.withOpacity(0.1)),
                Expanded(
                  child: Column(
                    children: [
                      Text("Bring", style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.5))),
                      const SizedBox(height: 4),
                      Text("PKR ${bringTotal.toStringAsFixed(0)}", 
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: accentGreen)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(Color textColor) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: primaryBrandColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.group_off_rounded, size: 80, color: primaryBrandColor.withOpacity(0.4)),
          ),
          const SizedBox(height: 24),
          Text(
            "No groups yet", 
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)
          ),
          const SizedBox(height: 12),
          Text(
            "Quickly organize expenses by\ncreating your first group.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: textColor.withOpacity(0.5), fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onCreateGroup,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text("Create a Group"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBrandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              elevation: 4,
              shadowColor: primaryBrandColor.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupCard(BuildContext context, Group group, bool isSmallScreen, Color textColor) {
    double totalGroupOwed = 0;
    for (var member in group.members) {
      final balance = overallBalances.firstWhere(
        (b) => b.member == member,
        orElse: () => Balance(member: member, amount: 0),
      );
      if (balance.amount > 0) totalGroupOwed += balance.amount;
    }

    return GestureDetector(
      onTap: () => onOpenGroup(group),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        child: GlassCard(
          isDarkMode: isDarkMode,
          padding: EdgeInsets.all(isSmallScreen ? 18 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryBrandColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(Icons.groups_rounded, color: primaryBrandColor, size: 28),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: GoogleFonts.outfit(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${group.members.length} participants",
                          style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  ),
                  if (currentUserUid != null)
                    StreamBuilder<int>(
                      stream: Provider.of<DatabaseService>(context, listen: false)
                          .streamGroupUnreadCount(group.id!, currentUserUid!),
                      builder: (context, unreadSnap) {
                        final unread = unreadSnap.data ?? 0;
                        if (unread == 0) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5252),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5252).withOpacity(0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.forum_rounded, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                unread > 99 ? '99+' : '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  Icon(Icons.arrow_forward_ios_rounded, color: textColor.withOpacity(0.2), size: 18),
                ],
              ),
              if (totalGroupOwed > 0) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.amber.shade700, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Active settlements pending in this group",
                          style: GoogleFonts.poppins(
                            fontSize: 12, 
                            color: Colors.amber.shade800, 
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Removed unused methods: _premiumBanner, _actionCards
}
