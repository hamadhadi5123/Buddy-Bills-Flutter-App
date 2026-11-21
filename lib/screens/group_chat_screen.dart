import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_message.dart';
import '../models/group.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../widgets/glass_widgets.dart';

class GroupChatScreen extends StatefulWidget {
  final Group group;
  final User currentUser;

  const GroupChatScreen({
    super.key,
    required this.group,
    required this.currentUser,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final db = Provider.of<DatabaseService>(context, listen: false);
    final message = ChatMessage(
      id: '', // Firestore will generate
      senderId: widget.currentUser.uid,
      senderName: widget.currentUser.name,
      content: content,
      timestamp: DateTime.now(),
    );

    _messageController.clear();
    await db.sendMessage(widget.group.id!, message);
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    const primaryBrandColor = Color(0xFF6C63FF);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.group.name, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            Text('${widget.group.members.length} participants', style: GoogleFonts.poppins(fontSize: 11, color: textColor.withOpacity(0.5))),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GlassBackground(
        isDarkMode: isDark,
        child: Column(
          children: [
            const SizedBox(height: 100),
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: Provider.of<DatabaseService>(context).streamChatMessages(widget.group.id!),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  
                  final messages = snapshot.data ?? [];
                  
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == widget.currentUser.uid;
                      
                      // Mark as read if it's an incoming message and hasn't been read by me
                      if (!isMe && !message.isReadBy(widget.currentUser.uid)) {
                        db.markMessageAsRead(widget.group.id!, message.id, widget.currentUser.uid);
                      }
                      
                      return _buildMessageBubble(message, isMe, isDark, textColor);
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(isDark, textColor, primaryBrandColor),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe, bool isDark, Color textColor) {
    const primaryColor = Color(0xFF6C63FF);
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(message.senderName, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.5))),
              ),
            GlassCard(
              isDarkMode: isDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              borderRadius: 16,
              color: isMe ? primaryColor : null,
              child: Text(
                message.content,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isMe ? Colors.white : textColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 4, left: 4),
              child: Text(
                '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.poppins(fontSize: 9, color: textColor.withOpacity(0.3)),
              ),
            ),
            if (isMe)
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 4),
                child: Icon(
                  Icons.done_all_rounded,
                  size: 14,
                  // Blue if read by everyone else (members - 1 sender)
                  color: message.readBy.length >= (widget.group.members.length - 1) 
                      ? Colors.blue 
                      : textColor.withOpacity(0.3),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(bool isDark, Color textColor, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              isDarkMode: isDark,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: 24,
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.poppins(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.3), fontSize: 14),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF6C63FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
