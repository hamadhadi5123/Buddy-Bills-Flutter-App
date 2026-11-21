import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/announcement.dart';
import '../models/user.dart';
import '../widgets/glass_widgets.dart';

class UserAnnouncementsScreen extends StatelessWidget {
  final User currentUser;
  const UserAnnouncementsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Broadcasting', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GlassBackground(
        isDarkMode: isDark,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('announcements')
              .where('isActive', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            
            final docs = snapshot.data!.docs.toList();
            docs.sort((a,b) => (b.data() as Map)['createdAt'].compareTo((a.data() as Map)['createdAt']));
            
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.campaign_outlined, size: 80, color: textColor.withOpacity(0.1)),
                    const SizedBox(height: 24),
                    Text('No active broadcasts', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    Text('Stay tuned for future updates.', style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.5))),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 20),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final announcement = Announcement.fromMap(docs[index].data() as Map<String, dynamic>);
                final priorityColor = Color(Announcement.getPriorityColor(announcement.priority));
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    isDarkMode: isDark,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Announcement.getPriorityIconData(announcement.priority), color: priorityColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(announcement.title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(announcement.message, style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.8))),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${announcement.createdAt.day}/${announcement.createdAt.month}/${announcement.createdAt.year}',
                              style: GoogleFonts.poppins(fontSize: 11, color: textColor.withOpacity(0.4)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
