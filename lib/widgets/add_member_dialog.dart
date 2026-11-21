import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../widgets/glass_widgets.dart';
import '../models/user.dart';

class AddMemberDialog extends StatefulWidget {
  final Function(String) onAddMember;
  final bool isDarkMode;
  final List<String> existingMembers;
  const AddMemberDialog({
    super.key,
    required this.onAddMember,
    required this.isDarkMode,
    this.existingMembers = const [],
  });

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool isLoading = false;

  void _searchAndAdd() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => isLoading = true);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final user = await db.findUserByEmail(email);
    setState(() => isLoading = false);

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account not found for this email"), backgroundColor: Colors.redAccent));
      return;
    }

    if (user.role.toLowerCase() == 'admin' || user.isAdmin) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot add admin users to groups"), backgroundColor: Colors.redAccent));
      return;
    }

    if (widget.existingMembers.contains(user.uid)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("This user is already a member of this group"), backgroundColor: Colors.orangeAccent));
      return;
    }

    widget.onAddMember(user.uid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Successfully added ${user.name}"), backgroundColor: const Color(0xFF27C46E)));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
    final db = Provider.of<DatabaseService>(context, listen: false);
    const primaryBrandColor = Color(0xFFD4AF37); // Century Gold

    return GlassDialog(
      isDarkMode: widget.isDarkMode,
      title: "Add Participant",
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Find friends by email or select from registered buddies below.",
              style: GoogleFonts.poppins(fontSize: 13, color: textColor.withOpacity(0.6)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              style: GoogleFonts.poppins(color: textColor),
              decoration: InputDecoration(
                hintText: "buddy@mail.com",
                hintStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.3), fontSize: 14),
                labelText: "Friend's Email",
                labelStyle: GoogleFonts.poppins(color: primaryBrandColor, fontSize: 13),
                prefixIcon: const Icon(Icons.alternate_email_rounded, color: primaryBrandColor, size: 20),
                filled: true,
                fillColor: widget.isDarkMode ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.transparent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: primaryBrandColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => _searchAndAdd(),
            ),
            const SizedBox(height: 16),
            Text(
              "Registered Buddies:",
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: StreamBuilder<List<User>>(
                stream: db.streamUsers(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
                  final users = snap.data!
                      .where((u) => !u.isAdmin && u.role.toLowerCase() != 'admin' && !widget.existingMembers.contains(u.uid))
                      .toList();
                  if (users.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text("No other users registered yet", style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 12)),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: users.length,
                    itemBuilder: (context, i) {
                      final u = users[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: primaryBrandColor.withOpacity(0.2),
                              child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : "U", style: const TextStyle(color: primaryBrandColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.name, style: GoogleFonts.poppins(color: textColor, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                  Text(u.email, style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 11), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                widget.onAddMember(u.uid);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added ${u.name}!"), backgroundColor: const Color(0xFF27C46E)));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF27C46E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                minimumSize: const Size(48, 28),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Add", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: TextStyle(color: textColor.withOpacity(0.5))),
        ),
        SizedBox(
          width: 100,
          child: ElevatedButton(
            onPressed: isLoading ? null : _searchAndAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27C46E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isLoading ? "..." : "Search", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
