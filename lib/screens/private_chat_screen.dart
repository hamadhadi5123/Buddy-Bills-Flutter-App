import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../models/chat_message.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/chat_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivateChatScreen extends StatefulWidget {
  final User recipient;
  final User currentUser;

  const PrivateChatScreen({
    super.key,
    required this.recipient,
    required this.currentUser,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTypingChanged(String text) {
    if (!_isTyping && text.isNotEmpty) {
      _setTyping(true);
    } else if (_isTyping && text.isEmpty) {
      _setTyping(false);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) _setTyping(false);
    });
  }

  void _setTyping(bool typing) {
    setState(() => _isTyping = typing);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final convId = db.getConversationId(widget.currentUser.uid, widget.recipient.uid);
    db.updateTypingStatus(convId, widget.currentUser.uid, typing);
  }

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
    _setTyping(false);
    
    await db.sendPrivateMessage(widget.recipient.uid, widget.currentUser.uid, message);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _launchWhatsApp() async {
    if (widget.recipient.phoneNumber == null || widget.recipient.phoneNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User has no phone number linked"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Standard WhatsApp URL format
    final whatsappUrl = "https://wa.me/${widget.recipient.phoneNumber?.replaceAll(RegExp(r'[^0-9]'), '')}";
    final Uri uri = Uri.parse(whatsappUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Cannot launch WhatsApp';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open WhatsApp: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final convId = db.getConversationId(widget.currentUser.uid, widget.recipient.uid);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    const primaryBrandColor = Color(0xFF6C63FF);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primaryBrandColor, Color(0xFF8E84FF)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: primaryBrandColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Center(
                child: Text(widget.recipient.name[0].toUpperCase(), 
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<User?>(
                stream: db.streamUser(widget.recipient.uid),
                builder: (context, snapshot) {
                  final user = snapshot.data ?? widget.recipient;
                  
                  return StreamBuilder<bool>(
                    stream: db.streamTypingStatus(convId, widget.recipient.uid),
                    builder: (context, typingSnapshot) {
                      final isOtherTyping = typingSnapshot.data ?? false;
                      final isOnline = user.isOnline;
                      final lastSeen = user.lastSeen;
                      
                      String statusText = isOnline ? 'Online' : 'Offline';
                      if (isOtherTyping) {
                        statusText = 'typing...';
                      } else if (!isOnline && lastSeen != null) {
                        final timeDiff = DateTime.now().difference(lastSeen);
                        if (timeDiff.inMinutes < 60) {
                          statusText = 'Last seen ${timeDiff.inMinutes}m ago';
                        } else if (timeDiff.inHours < 24) {
                          statusText = 'Last seen ${timeDiff.inHours}h ago';
                        } else {
                          statusText = 'Last seen recently';
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                          Text(statusText, style: GoogleFonts.poppins(
                            fontSize: 11, 
                            fontWeight: isOtherTyping ? FontWeight.bold : FontWeight.normal,
                            color: (isOnline || isOtherTyping) ? const Color(0xFF27C46E) : textColor.withOpacity(0.5)
                          )),
                        ],
                      );
                    },
                  );
                }
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
           IconButton(
            icon: Icon(Icons.chat_rounded, color: const Color(0xFF25D366)), // Traditional WhatsApp Green
            tooltip: 'Chat on WhatsApp',
            onPressed: _launchWhatsApp,
          ),
          const SizedBox(width: 8),
        ],
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
                stream: db.streamPrivateMessages(convId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  
                  final messages = snapshot.data ?? [];
                  
                  // Batch mark messages as read
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    for (var msg in messages) {
                      if (msg.senderId != widget.currentUser.uid && !msg.isReadBy(widget.currentUser.uid)) {
                        db.markPrivateMessageAsRead(convId, msg.id, widget.currentUser.uid);
                      }
                    }
                    db.markConversationAsRead(convId, widget.currentUser.uid);
                  });
                  
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == widget.currentUser.uid;
                      
                      // Check if a date separator is needed
                      bool showDateSeparator = false;
                      if (index == messages.length - 1) {
                        showDateSeparator = true;
                      } else {
                        final nextMessage = messages[index + 1];
                        if (!_isSameDay(message.timestamp, nextMessage.timestamp)) {
                          showDateSeparator = true;
                        }
                      }

                      return Column(
                        children: [
                          if (showDateSeparator) 
                            ChatWidgets.buildDateSeparator(message.timestamp, isDark, textColor),
                          ChatWidgets.buildMessageBubble(
                            context: context,
                            message: message,
                            isMe: isMe,
                            isDark: isDark,
                            textColor: textColor,
                            recipientId: widget.recipient.uid,
                          ),
                        ],
                      );
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

  Widget _buildMessageInput(bool isDark, Color textColor, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              isDarkMode: isDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: 28,
              child: TextField(
                controller: _messageController,
                onChanged: _onTypingChanged,
                style: GoogleFonts.manrope(color: textColor, fontSize: 15),
                maxLines: 5,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: "Message",
                  hintStyle: GoogleFonts.manrope(color: textColor.withOpacity(0.3), fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
