import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/support_request.dart';
import '../models/user.dart';
import '../widgets/glass_widgets.dart';

class AdminSupportManagementScreen extends StatefulWidget {
  final User currentUser;
  const AdminSupportManagementScreen({super.key, required this.currentUser});

  @override
  State<AdminSupportManagementScreen> createState() => _AdminSupportManagementScreenState();
}

class _AdminSupportManagementScreenState extends State<AdminSupportManagementScreen> {
  final CollectionReference supportCollection = FirebaseFirestore.instance.collection('support_requests');
  String filterStatus = 'all';

  void _showRespondDialog(SupportRequest request) {
    final responseCtrl = TextEditingController(text: request.adminResponse ?? '');
    String selectedStatus = request.status;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        isDarkMode: isDark,
        title: 'Official Response',
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User: ${request.userName}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6C63FF))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                child: Text(request.message, style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Status State', 
                  labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                  filled: true, 
                  fillColor: Colors.white.withOpacity(0.05), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending Review')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                ],
                onChanged: (value) => selectedStatus = value!,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: responseCtrl,
                maxLines: 4,
                style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Final Resolution', 
                  labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                  filled: true, 
                  fillColor: Colors.white.withOpacity(0.05), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Discard', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54))),
          GlassButton(
            onPressed: () {
              Navigator.pop(context);
              _respondToRequest(request.id, selectedStatus, responseCtrl.text.trim());
            },
            label: 'Commit Response',
            color: const Color(0xFF6C63FF),
            isDarkMode: isDark,
          ),
        ],
      ),
    );
  }

  Future<void> _respondToRequest(String requestId, String status, String response) async {
    try {
      await supportCollection.doc(requestId).update({
        'status': status,
        'adminResponse': response.isEmpty ? null : response,
        'respondedBy': widget.currentUser.uid,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      _snack('Ledger updated with resolution.');
    } catch (e) {
      _snack('Sync failure: $e');
    }
  }

  Future<void> _deleteRequest(String id) async {
    try {
      await supportCollection.doc(id).delete();
      _snack('Record expunged from database.');
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
        title: Text('Concierge Admin', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('all', 'Universal'),
                    const SizedBox(width: 8),
                    _filterChip('pending', 'Pending'),
                    const SizedBox(width: 8),
                    _filterChip('in_progress', 'Live'),
                    const SizedBox(width: 8),
                    _filterChip('resolved', 'Resolved'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: supportCollection.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  
                  var docs = snapshot.data!.docs.toList();
                  docs.sort((a, b) => (b.data() as Map)['createdAt'].compareTo((a.data() as Map)['createdAt']));
                  if (filterStatus != 'all') {
                    docs = docs.where((doc) => (doc.data() as Map)['status'] == filterStatus).toList();
                  }

                  if (docs.isEmpty) return _buildEmptyState(textColor);

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final request = SupportRequest.fromMap(docs[index].data() as Map<String, dynamic>);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          isDarkMode: isDark,
                          padding: EdgeInsets.zero,
                          child: ExpansionTile(
                            leading: CircleAvatar(backgroundColor: Color(SupportRequest.getStatusColor(request.status)).withOpacity(0.2), child: Icon(Icons.support_rounded, color: Color(SupportRequest.getStatusColor(request.status)), size: 18)),
                            title: Text(request.subject, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16, color: textColor)),
                            subtitle: Text('User: ${request.userName} • ${request.statusText} • ${_formatDate(request.createdAt)}', style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.5))),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.reply_rounded, color: Colors.blueAccent, size: 22), onPressed: () => _showRespondDialog(request)),
                                IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 22), onPressed: () => _confirmDelete(request)),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ORIGINAL TRANSMISSION:', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.4))),
                                    const SizedBox(height: 8),
                                    Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)), child: Text(request.message, style: GoogleFonts.poppins(fontSize: 13, color: textColor.withOpacity(0.8)))),
                                    if (request.adminResponse != null) ...[
                                      const SizedBox(height: 16),
                                      Text('YOUR SYSTEM RESPONSE:', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF27C46E))),
                                      const SizedBox(height: 8),
                                      Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF27C46E).withOpacity(0.05), borderRadius: BorderRadius.circular(12)), child: Text(request.adminResponse!, style: GoogleFonts.poppins(fontSize: 13, color: textColor.withOpacity(0.8)))),
                                    ],
                                    const SizedBox(height: 12),
                                    Text('Identity: ${request.userEmail}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.blueAccent)),
                                  ],
                                ),
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
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String status, String label) {
    bool isSelected = filterStatus == status;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: isSelected ? Colors.white : Colors.grey)),
      selected: isSelected,
      selectedColor: const Color(0xFF6C63FF),
      backgroundColor: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
      onSelected: (_) => setState(() => filterStatus = status),
    );
  }

  Widget _buildEmptyState(Color textColor) => Center(child: Text('Console is currently clear', style: GoogleFonts.outfit(color: textColor.withOpacity(0.3))));
  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFF6C63FF)));
  void _confirmDelete(SupportRequest request) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Request?'), content: Text('Remove support ticket from ${request.userName}?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () { Navigator.pop(ctx); _deleteRequest(request.id); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('Delete'))],
    ));
  }
}
