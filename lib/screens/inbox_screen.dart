import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../widgets/glass_widgets.dart';
import 'private_chat_screen.dart';
import 'package:intl/intl.dart';

class InboxScreen extends StatelessWidget {
  final User currentUser;
  final bool isDarkMode;

  const InboxScreen({
    super.key,
    required this.currentUser,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
    const primaryColor = Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Messages", style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: db.streamRecentConversations(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final conversations = snapshot.data ?? [];
          
          if (conversations.isEmpty) {
            return _buildEmptyState(textColor, primaryColor);
          }

          return StreamBuilder<List<User>>(
            stream: db.streamUsers(),
            builder: (context, userSnapshot) {
              final allUsers = userSnapshot.data ?? [];
              
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conv = conversations[index];
                  final List participants = conv['participants'];
                  final otherUid = participants.firstWhere((id) => id != currentUser.uid);
                  final otherUser = allUsers.firstWhere((u) => u.uid == otherUid, orElse: () => User(uid: otherUid, name: 'Unknown', email: '', createdAt: DateTime.now()));
                  
                  return _buildConversationCard(context, conv, otherUser, textColor, primaryColor);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationCard(BuildContext context, Map<String, dynamic> conv, User otherUser, Color textColor, Color primaryColor) {
    final lastTimestamp = DateTime.fromMillisecondsSinceEpoch(conv['lastTimestamp'] ?? 0);
    final timeStr = DateFormat.jm().format(lastTimestamp);
    final unreadCount = (conv['unread_${currentUser.uid}'] as num?)?.toInt() ?? 
        (conv['lastSenderId'] != currentUser.uid ? 1 : 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDarkMode: isDarkMode,
        padding: EdgeInsets.zero,
        borderRadius: 20,
        child: ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PrivateChatScreen(recipient: otherUser, currentUser: currentUser)),
            );
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.7)]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(otherUser.name[0].toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            ),
          ),
          title: Text(
            otherUser.name, 
            style: GoogleFonts.poppins(
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600, 
              color: textColor
            )
          ),
          subtitle: Text(
            conv['lastMessage'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13, 
              fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
              color: unreadCount > 0 ? textColor : textColor.withOpacity(0.5)
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr, 
                style: GoogleFonts.poppins(
                  fontSize: 10, 
                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  color: unreadCount > 0 ? primaryColor : textColor.withOpacity(0.4)
                )
              ),
              const SizedBox(height: 6),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: primaryColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text("No messages yet", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.6))),
          const SizedBox(height: 8),
          Text("Start a conversation with your friends!", style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.4))),
        ],
      ),
    );
  }
}
