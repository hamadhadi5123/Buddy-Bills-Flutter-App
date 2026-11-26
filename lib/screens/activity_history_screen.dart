import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/expense.dart';
import '../models/payment.dart';
import '../models/user.dart' as model;
import '../widgets/glass_widgets.dart';

class ActivityHistoryScreen extends StatelessWidget {
  final List<Expense> expenses;
  final List<Payment> payments;
  final List<model.User> allUsers;
  final bool isDarkMode;

  const ActivityHistoryScreen({
    super.key,
    required this.expenses,
    required this.payments,
    required this.allUsers,
    this.isDarkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
    final accentGreen = const Color(0xFF27C46E);
    // Removed unused primaryBrandColor

    // Combine and sort by date
    List<dynamic> combined = [...expenses, ...payments];
    combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final List<Map<String, dynamic>> categories = [
      {'name': 'Food', 'icon': Icons.restaurant, 'color': Colors.orange},
      {'name': 'Travel', 'icon': Icons.flight, 'color': Colors.blue},
      {'name': 'Home', 'icon': Icons.home, 'color': Colors.green},
      {'name': 'Utilities', 'icon': Icons.electric_bolt, 'color': Colors.amber},
      {'name': 'Other', 'icon': Icons.more_horiz, 'color': Colors.grey},
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Activity History", 
          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GlassBackground(
        isDarkMode: isDarkMode,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 20),
          itemCount: combined.length,
          itemBuilder: (context, index) {
            final item = combined[index];
            bool isExpense = item is Expense;
            final cat = isExpense ? categories.firstWhere((c) => c['name'] == item.category, orElse: () => categories.last) : null;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                isDarkMode: isDarkMode,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isExpense ? (cat!['color'] as Color).withOpacity(0.1) : accentGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isExpense ? cat!['icon'] as IconData : Icons.handshake_rounded, 
                        color: isExpense ? cat!['color'] as Color : accentGreen,
                        size: 22
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isExpense ? item.description : "Settlement", 
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor)
                          ),
                          Text(
                            isExpense 
                              ? (item.multiplePayers != null && item.multiplePayers!.isNotEmpty
                                  ? "Paid by ${item.multiplePayers!.entries.map((e) => "${allUsers.firstWhere((u) => u.uid == e.key, orElse: () => model.User(uid: e.key, name: e.key.length > 5 ? "Member ${e.key.substring(e.key.length - 4)}" : "Member ${e.key}", email: "", createdAt: DateTime.now())).name}: ${e.value.toStringAsFixed(0)}").join(", ")}"
                                  : "Paid by ${allUsers.firstWhere((u) => u.uid == item.paidBy, orElse: () => model.User(uid: item.paidBy, name: item.paidBy.length > 5 ? "Member ${item.paidBy.substring(item.paidBy.length - 4)}" : "Member ${item.paidBy}", email: "", createdAt: DateTime.now())).name}")
                              : "${allUsers.firstWhere((u) => u.uid == item.from, orElse: () => model.User(uid: item.from, name: item.from.length > 5 ? "Member ${item.from.substring(item.from.length - 4)}" : "Member ${item.from}", email: "", createdAt: DateTime.now())).name} paid ${allUsers.firstWhere((u) => u.uid == item.to, orElse: () => model.User(uid: item.to, name: item.to.length > 5 ? "Member ${item.to.substring(item.to.length - 4)}" : "Member ${item.to}", email: "", createdAt: DateTime.now())).name}",
                            style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.5))
                          ),
                          Text(
                            "${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year} at ${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}",
                            style: GoogleFonts.poppins(fontSize: 10, color: textColor.withOpacity(0.4))
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("PKR ${item.amount.toStringAsFixed(0)}", 
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)
                        ),
                        if (!isExpense)
                          Text(
                            (item as Payment).status == 'pending' ? "Pending" : ((item).status == 'rejected' ? "Rejected" : "Settled"),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: (item as Payment).status == 'pending' ? Colors.orange : ((item).status == 'rejected' ? Colors.redAccent : accentGreen),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
