import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';

class ChatWidgets {
  static Widget buildDateSeparator(DateTime date, bool isDark, Color textColor) {
    String label;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) {
      label = "Today";
    } else if (msgDate == yesterday) {
      label = "Yesterday";
    } else {
      label = DateFormat('MMMM d, y').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildMessageBubble({
    required BuildContext context,
    required ChatMessage message,
    required bool isMe,
    required bool isDark,
    required Color textColor,
    required String recipientId,
  }) {
    final primaryColor = const Color(0xFF6C63FF);
    final timeStr = DateFormat('h:mm a').format(message.timestamp);
    final isRead = message.readBy.contains(recipientId);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Stack(
          children: [
            // Bubble with tail
            Padding(
              padding: EdgeInsets.only(
                left: isMe ? 0 : 10,
                right: isMe ? 10 : 0,
              ),
              child: CustomPaint(
                painter: BubblePainter(isMe: isMe, color: isMe ? primaryColor : (isDark ? const Color(0xFF262626) : Colors.white)),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: Text(
                          message.content,
                          style: GoogleFonts.manrope(
                            fontSize: 14.5,
                            color: isMe ? Colors.white : textColor,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeStr,
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              color: isMe ? Colors.white.withOpacity(0.7) : textColor.withOpacity(0.4),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all_rounded,
                              size: 15,
                              color: isRead ? const Color(0xFF4FC3F7) : Colors.white.withOpacity(0.5),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BubblePainter extends CustomPainter {
  final bool isMe;
  final Color color;

  BubblePainter({required this.isMe, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const radius = 12.0;

    if (isMe) {
      path.moveTo(radius, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height - radius);
      path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
      path.lineTo(radius, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - radius);
      path.lineTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
      
      // Tail
      path.moveTo(size.width, 10);
      path.lineTo(size.width + 8, 5);
      path.lineTo(size.width, 20);
    } else {
      path.moveTo(radius, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height - radius);
      path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
      path.lineTo(radius, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - radius);
      path.lineTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);

      // Tail
      path.moveTo(0, 10);
      path.lineTo(-8, 5);
      path.lineTo(0, 20);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
