import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/announcement.dart';
import '../models/user.dart';
import '../widgets/glass_widgets.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  final User currentUser;
  const AdminAnnouncementsScreen({super.key, required this.currentUser});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final CollectionReference announcementsCollection = FirebaseFirestore.instance.collection('announcements');
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController messageCtrl = TextEditingController();
  String selectedPriority = 'info';

  void _showCreateAnnouncementDialog() {
    titleCtrl.clear();
    messageCtrl.clear();
    selectedPriority = 'info';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        isDarkMode: isDark,
        title: 'Broadcast Message',
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Headline', 
                  labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                  filled: true, 
                  fillColor: Colors.white.withOpacity(0.05), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageCtrl,
                maxLines: 4,
                style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Transmission content', 
                  labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                  filled: true, 
                  fillColor: Colors.white.withOpacity(0.05), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Criticality Level', 
                  labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
                items: const [
                  DropdownMenuItem(value: 'info', child: Text('Standard')),
                  DropdownMenuItem(value: 'important', child: Text('Important')),
                  DropdownMenuItem(value: 'urgent', child: Text('Flash Alert')),
                ],
                onChanged: (value) => selectedPriority = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54))),
          GlassButton(
            onPressed: () {
              Navigator.pop(context);
              _createAnnouncement();
            },
            label: 'Initiate Broadcast',
            color: const Color(0xFF6C63FF),
            isDarkMode: isDark,
          ),
        ],
      ),
    );
  }

  Future<void> _createAnnouncement() async {
    if (titleCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) return;
    try {
      final announcementId = announcementsCollection.doc().id;
      final announcement = Announcement(
        id: announcementId,
        title: titleCtrl.text.trim(),
        message: messageCtrl.text.trim(),
        priority: selectedPriority,
        createdBy: widget.currentUser.uid,
        createdByName: widget.currentUser.name,
        createdAt: DateTime.now(),
      );
      await announcementsCollection.doc(announcementId).set(announcement.toMap());
      _snack('Broadcast transmitted successfully.');
    } catch (e) {
      _snack('Broadcast error: $e');
    }
  }

  Future<void> _toggleAnnouncementStatus(Announcement announcement) async {
    try {
      await announcementsCollection.doc(announcement.id).update({'isActive': !announcement.isActive});
    } catch (e) {
      _snack('State toggle failure: $e');
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    try {
      await announcementsCollection.doc(id).delete();
      _snack('Broadcast record expunged.');
    } catch (e) {
      _snack('Erasure failure: $e');
    }
  }

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
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateAnnouncementDialog,
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.campaign_rounded, color: Colors.white),
      ),
      body: GlassBackground(
        isDarkMode: isDark,
        child: StreamBuilder<QuerySnapshot>(
          stream: announcementsCollection.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            
            final docs = snapshot.data!.docs.toList();
            docs.sort((a,b) => (b.data() as Map)['createdAt'].compareTo((a.data() as Map)['createdAt']));
            if (docs.isEmpty) return _buildEmptyState(textColor);
  
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
                            Icon(IconData(Announcement.getPriorityIcon(announcement.priority), fontFamily: 'MaterialIcons'), color: priorityColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(announcement.title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor))),
                            _statusBadge(announcement.isActive),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(announcement.message, style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.8))),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Admin: ${announcement.createdByName}', style: GoogleFonts.poppins(fontSize: 11, color: textColor.withOpacity(0.4))),
                            Row(
                              children: [
                                Switch(value: announcement.isActive, onChanged: (_) => _toggleAnnouncementStatus(announcement), activeColor: const Color(0xFF27C46E)),
                                IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 22), onPressed: () => _deleteAnnouncement(announcement.id)),
                              ],
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

  Widget _statusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: (isActive ? const Color(0xFF27C46E) : Colors.grey).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(isActive ? 'LIVE' : 'IDLE', style: TextStyle(color: isActive ? const Color(0xFF27C46E) : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState(Color textColor) => Center(child: Text('No broadcasts in system', style: GoogleFonts.outfit(color: textColor.withOpacity(0.3))));
  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFF6C63FF)));
}
