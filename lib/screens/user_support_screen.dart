import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/support_request.dart';
import '../models/user.dart';
import '../widgets/glass_widgets.dart';

class UserSupportScreen extends StatefulWidget {
  final User currentUser;
  const UserSupportScreen({super.key, required this.currentUser});

  @override
  State<UserSupportScreen> createState() => _UserSupportScreenState();
}

class _UserSupportScreenState extends State<UserSupportScreen> {
  final CollectionReference supportCollection = FirebaseFirestore.instance.collection('support_requests');
  final TextEditingController subjectCtrl = TextEditingController();
  final TextEditingController messageCtrl = TextEditingController();

  void _showCreateRequestDialog() {
    subjectCtrl.clear();
    messageCtrl.clear();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBrandColor = Color(0xFF6C63FF);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    showDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        isDarkMode: isDark,
        title: 'New Assistance Request',
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectCtrl,
                style: GoogleFonts.poppins(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Inquiry Subject',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageCtrl,
                maxLines: 4,
                style: GoogleFonts.poppins(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Details',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: textColor.withOpacity(0.5)))),
          GlassButton(
            onPressed: () {
              Navigator.pop(context);
              _createRequest();
            },
            label: 'Send Message',
            color: primaryBrandColor,
            isDarkMode: isDark,
          ),
        ],
      ),
    );
  }

  Future<void> _createRequest() async {
    if (subjectCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) return;
    try {
      final requestId = supportCollection.doc().id;
      final request = SupportRequest(
        id: requestId,
        userId: widget.currentUser.uid,
        userName: widget.currentUser.name,
        userEmail: widget.currentUser.email,
        subject: subjectCtrl.text.trim(),
        message: messageCtrl.text.trim(),
        createdAt: DateTime.now(),
      );
      await supportCollection.doc(requestId).set(request.toMap());
      _snack('Your request has been dispatched to our staff.');
    } catch (e) {
      _snack('Submission failed: $e');
    }
  }

  void _showRequestDetails(SupportRequest request) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    showDialog(
      context: context,
      builder: (context) => GlassDialog(
        isDarkMode: isDark,
        title: 'Inquiry Details',
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(request.subject, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textColor))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Color(SupportRequest.getStatusColor(request.status)).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text(request.statusText, style: TextStyle(color: Color(SupportRequest.getStatusColor(request.status)), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(request.message, style: GoogleFonts.poppins(fontSize: 13, color: textColor.withOpacity(0.7))),
              if (request.adminResponse != null) ...[
                const SizedBox(height: 24),
                Text('Resolution response:', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF27C46E))),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF27C46E).withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF27C46E).withOpacity(0.2))),
                  child: Text(request.adminResponse!, style: GoogleFonts.poppins(fontSize: 13, color: textColor.withOpacity(0.9))),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Dismiss", style: TextStyle(color: textColor.withOpacity(0.5)))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Concierge', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRequestDialog,
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: GlassBackground(
        isDarkMode: isDark,
        child: StreamBuilder<QuerySnapshot>(
          stream: supportCollection.where('userId', isEqualTo: widget.currentUser.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            
            final docs = snapshot.data!.docs.toList();
            // Sort by createdAt descending manually to avoid composite index requirement
            docs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              return (bData['createdAt'] ?? 0).compareTo(aData['createdAt'] ?? 0);
            });
            
            if (docs.isEmpty) return _buildEmptyState(textColor);

            return ListView.builder(
              padding: const EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 20),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final request = SupportRequest.fromMap(docs[index].data() as Map<String, dynamic>);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    isDarkMode: isDark,
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Color(SupportRequest.getStatusColor(request.status)).withOpacity(0.12), shape: BoxShape.circle),
                        child: Icon(request.status == 'resolved' ? Icons.verified_rounded : Icons.pending_actions_rounded, size: 20, color: Color(SupportRequest.getStatusColor(request.status))),
                      ),
                      title: Text(request.subject, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, color: textColor)),
                      subtitle: Text('${request.statusText} • ${_formatDate(request.createdAt)}', style: GoogleFonts.poppins(fontSize: 11, color: textColor.withOpacity(0.5))),
                      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: textColor.withOpacity(0.3)),
                      onTap: () => _showRequestDetails(request),
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

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.support_agent_rounded, size: 80, color: textColor.withOpacity(0.1)),
          const SizedBox(height: 24),
          Text('No open tickets', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          Text('Need help? Start a conversation.', style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.5))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFF6C63FF)));
}
