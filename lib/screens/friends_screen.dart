import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/balance.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import 'private_chat_screen.dart';
import '../widgets/user_avatar.dart';

class FriendsScreen extends StatelessWidget {
  final List<User> allUsers;
  final User currentUser;
  final List<Balance> balances;
  final bool isDarkMode;

  const FriendsScreen({
    super.key,
    required this.allUsers,
    required this.currentUser,
    required this.balances,
    required this.isDarkMode,
  });

  Color get accentGreen => const Color(0xFF27C46E);
  final Color primaryBrandColor = const Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < 600;
    final double padding = isSmall ? 16 : 24;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF1A1A2E);

    final realFriends = allUsers.where((u) => u.uid != currentUser.uid && u.role.toLowerCase() != 'admin' && u.isAdmin == false).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Friends",
          style: GoogleFonts.outfit(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: accentGreen),
      ),
      body: realFriends.isEmpty
          ? _emptyState(textColor)
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _balanceSummary(isSmall, textColor),
                  const SizedBox(height: 32),
                  _friendsHeader(realFriends.length, textColor),
                  const SizedBox(height: 16),
                  ...realFriends
                      .map((user) => _friendCard(context, isSmall, user, textColor)),
                  const SizedBox(height: 120),
                ],
              ),
            ),
    );
  }

  Widget _emptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: primaryBrandColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline, size: 80, color: primaryBrandColor.withOpacity(0.4)),
          ),
          const SizedBox(height: 24),
          Text(
            "No friends added",
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)
          ),
          const SizedBox(height: 8),
          Text(
            "Start tracking expenses by adding balance.",
            style: GoogleFonts.poppins(color: textColor.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _balanceSummary(bool small, Color textColor) {
    final Color glassBorderColor = isDarkMode
        ? Colors.white.withOpacity(0.12)
        : Colors.white.withOpacity(0.4);
    final Color glassFillColor = isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.2);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(small ? 16 : 24),
          decoration: BoxDecoration(
            color: glassFillColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: glassBorderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Balance Summary",
                style: GoogleFonts.outfit(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18
                ),
              ),
              const SizedBox(height: 16),
              ...balances.where((b) => b.member != "You").map((b) {
                bool positive = b.amount > 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          b.member,
                          style: GoogleFonts.poppins(color: textColor.withOpacity(0.8), fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "PKR ${b.amount.abs().toStringAsFixed(2)}",
                        style: GoogleFonts.poppins(
                          color: positive ? accentGreen : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (balances.where((b) => b.member != "You").isEmpty)
                Text(
                  "All settled up!",
                  style: GoogleFonts.poppins(color: textColor.withOpacity(0.4), fontSize: 13)
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _friendsHeader(int count, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Friends ($count)",
          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 19),
        ),
        Text(
          "Tap to view details",
          style: GoogleFonts.poppins(color: textColor.withOpacity(0.4), fontSize: 12)
        ),
      ],
    );
  }

  Widget _friendCard(BuildContext context, bool small, User friend, Color textColor) {
    final name = friend.name;
    final Color glassBorderColor = isDarkMode
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.3);
    final Color glassFillColor = isDarkMode
        ? Colors.white.withOpacity(0.04)
        : Colors.white.withOpacity(0.15);

    final balance = balances.firstWhere(
      (b) => b.memberUid == friend.uid || b.member == name,
      orElse: () => Balance(member: name, memberUid: friend.uid, amount: 0),
    );

    final bool hasDebt = balance.amount.abs() > 0.01;
    final displayAmount = (balance.amount.abs() % 1 == 0)
        ? balance.amount.abs().toStringAsFixed(0)
        : balance.amount.abs().toStringAsFixed(2);
    final String subtitle = !hasDebt
        ? "All settled up!"
        : (balance.amount > 0.01
            ? "You Bring PKR $displayAmount"
            : "You Give PKR $displayAmount");

    final Color subtitleColor = !hasDebt
        ? textColor.withOpacity(0.4)
        : (balance.amount > 0.01 ? accentGreen : Colors.redAccent);

    final IconData iconLine = !hasDebt
        ? Icons.check_circle_outline_rounded
        : (balance.amount > 0.01
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: glassFillColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: glassBorderColor, width: 1.2),
            ),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PrivateChatScreen(
                      recipient: friend,
                      currentUser: currentUser,
                    ),
                  ),
                );
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryBrandColor.withOpacity(0.2), width: 1.5),
                ),
                child: UserAvatar(
                  imageUrl: friend.profilePictureUrl,
                  name: name,
                  radius: small ? 18 : 22,
                ),
              ),
              title: Text(
                name,
                style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.w600, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                subtitle,
                style: GoogleFonts.poppins(color: subtitleColor, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<int>(
                    stream: Provider.of<DatabaseService>(context, listen: false)
                        .streamConversationUnread(
                          currentUser.uid.compareTo(friend.uid) < 0 
                              ? "${currentUser.uid}_${friend.uid}" 
                              : "${friend.uid}_${currentUser.uid}", 
                          currentUser.uid
                        ),
                    builder: (context, unreadSnap) {
                      final unread = unreadSnap.data ?? 0;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryBrandColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.forum_rounded, color: primaryBrandColor, size: 18),
                          ),
                          if (unread > 0)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5252),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF5252).withOpacity(0.4),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Center(
                                  child: Text(
                                    unread > 99 ? '99+' : '$unread',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: subtitleColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconLine, color: subtitleColor, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
