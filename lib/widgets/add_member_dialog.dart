import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../widgets/glass_widgets.dart';

class AddMemberDialog extends StatefulWidget {
  final Function(String) onAddMember;
  final bool isDarkMode;
  const AddMemberDialog({super.key, required this.onAddMember, required this.isDarkMode});

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

    widget.onAddMember(user.uid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sucessfully added ${user.name}"), backgroundColor: const Color(0xFF27C46E)));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
    const primaryBrandColor = Color(0xFF6C63FF);

    return GlassDialog(
      isDarkMode: widget.isDarkMode,
      title: "Add Participant",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Find friends by their email address to join the group.",
            style: GoogleFonts.poppins(fontSize: 13, color: textColor.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            style: GoogleFonts.poppins(color: textColor),
            decoration: InputDecoration(
              hintText: "example@mail.com",
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _searchAndAdd(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: TextStyle(color: textColor.withOpacity(0.5))),
        ),
        SizedBox(
          width: 100,
          child: GlassButton(
            onPressed: isLoading ? () {} : _searchAndAdd,
            label: isLoading ? "..." : "Add",
            color: primaryBrandColor,
            isDarkMode: widget.isDarkMode,
          ),
        ),
      ],
    );
  }
}
