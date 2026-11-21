import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/group.dart';
import '../models/expense.dart';
import '../models/balance.dart';
import '../models/payment.dart';
import '../utils/debt_calculator.dart';
import 'add_expense_screen.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/user_activity_service.dart';
import '../widgets/add_member_dialog.dart';
import '../widgets/glass_widgets.dart';
import '../models/user.dart' as model;
import 'activity_history_screen.dart';
import 'group_chat_screen.dart';
import 'private_chat_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;
  final List<Expense> groupExpenses;
  final List<Balance> groupBalances;
  final void Function(String, String) onAddMember;
  final void Function(String)? onRemoveMember;
  final void Function(Expense)? onAddExpense;
  final List<model.User> allUsers;
  final String currentUserUid;
  final bool isDarkMode;

  const GroupDetailScreen({
    super.key,
    required this.group,
    required this.onAddMember,
    this.onRemoveMember,
    this.onAddExpense,
    required this.groupExpenses,
    required this.groupBalances,
    required this.allUsers,
    required this.currentUserUid,
    this.isDarkMode = true,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {

  @override
  void initState() {
    super.initState();
    // darkMode was unused, removed.
  }

  Color get accentGreen => const Color(0xFF27C46E);
  final Color primaryBrandColor = const Color(0xFF6C63FF);

  final List<Map<String, dynamic>> categories = [
    {'name': 'Food', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'name': 'Travel', 'icon': Icons.flight, 'color': Colors.blue},
    {'name': 'Home', 'icon': Icons.home, 'color': Colors.green},
    {'name': 'Utilities', 'icon': Icons.electric_bolt, 'color': Colors.amber},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    final double horizontalPadding = isSmallScreen ? 16.0 : 24.0;
    final Color textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E);

    return StreamBuilder<Group?>(
      stream: db.streamGroup(widget.group.id!),
      builder: (context, groupSnap) {
        final currentGroup = groupSnap.data ?? widget.group;
        final bool isCreator = currentGroup.createdBy == widget.currentUserUid;
        final currentUser = widget.allUsers.firstWhere(
          (u) => u.uid == widget.currentUserUid,
          orElse: () => model.User(uid: widget.currentUserUid, name: "User", email: "", createdAt: DateTime.now()),
        );
        final bool isPlatformAdmin = currentUser.isAdmin || currentUser.role.toLowerCase() == 'admin' || currentUser.email == 'admin@buddybills.com';
        final bool hasAdminRights = isCreator || isPlatformAdmin;

        return StreamBuilder<List<Expense>>(
          stream: db.streamGroupExpenses(currentGroup.id!),
          builder: (context, expenseSnap) {
            final expenses = expenseSnap.data ?? [];

            return StreamBuilder<List<Payment>>(
              stream: db.streamGroupPayments(currentGroup.id!),
              builder: (context, paymentSnap) {
                final payments = paymentSnap.data ?? [];
                
                // Use the new DebtCalculator for P2P insights
                final List<Debt> debts = DebtCalculator.calculateDebts(
                  expenses, 
                  payments, 
                  currentGroup.members
                );

                return GlassBackground(
                  isDarkMode: widget.isDarkMode,
                  child: Scaffold(
                    extendBody: true,
                    backgroundColor: Colors.transparent,
                    appBar: AppBar(
                      leading: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      title: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(currentGroup.name, 
                          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)
                        ),
                      ),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      actions: [
                        if (hasAdminRights)
                          IconButton(
                            icon: Icon(Icons.edit_rounded, color: primaryBrandColor),
                            tooltip: "Edit Group",
                            onPressed: () => _showEditGroupDialog(currentGroup),
                          ),
                        IconButton(
                          icon: Icon(Icons.forum_outlined, color: primaryBrandColor),
                          tooltip: "Group Chat",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GroupChatScreen(
                                  group: currentGroup,
                                  currentUser: currentUser,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.person_add_rounded, color: primaryBrandColor),
                          tooltip: "Add Member",
                          onPressed: () => _showAddMemberDialog(currentGroup),
                        ),
                        if (hasAdminRights)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            tooltip: "Delete Group",
                            onPressed: () => _showDeleteGroupDialog(currentGroup),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.exit_to_app_rounded, color: Colors.orangeAccent),
                            tooltip: "Leave Group",
                            onPressed: () => _showLeaveGroupDialog(currentGroup, debts),
                          ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    body: RefreshIndicator(
                      onRefresh: () async => setState(() {}),
                      color: primaryBrandColor,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        child: Padding(
                          padding: EdgeInsets.all(horizontalPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10), // Space for AppBar
                              _buildGlassHeader(currentGroup, textColor, isSmallScreen, isCreator, isPlatformAdmin),
                              const SizedBox(height: 24),
                              
                              if (debts.isNotEmpty) ...[
                                _buildP2PDebtsSection(debts, textColor, isSmallScreen),
                                const SizedBox(height: 24),
                              ],
  
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildGlassActionButton(
                                      onPressed: () => _addExpense(currentGroup),
                                      icon: Icons.add_rounded,
                                      label: "Add Expense",
                                      color: primaryBrandColor,
                                    ),
                                  ),
                                  if (debts.any((d) => d.from == widget.currentUserUid || d.to == widget.currentUserUid)) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildGlassActionButton(
                                        onPressed: () => _showSettleUpBottomSheet(debts),
                                        icon: Icons.check_circle_rounded,
                                        label: "Settle Up",
                                        color: accentGreen,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              
                              const SizedBox(height: 32),
                              _buildTransactionHistory(expenses, payments, textColor, isSmallScreen, currentGroup, hasAdminRights),
                              const SizedBox(height: 32),
                              _buildMembersGrid(currentGroup, textColor, isSmallScreen, isCreator, hasAdminRights, debts),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            );
          },
        );
      },
    );
  }

  Widget _buildGlassHeader(Group group, Color textColor, bool isSmall, bool isCreator, bool isPlatformAdmin) {
    return GlassCard(
      isDarkMode: widget.isDarkMode,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, 
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)
                    ),
                    const SizedBox(height: 4),
                    Text("${group.type} • ${group.members.length} members", 
                      style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.6))
                    ),
                    if (isCreator) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Color(0xFFD4AF37), size: 14),
                            const SizedBox(width: 4),
                            Text("Group Admin", style: GoogleFonts.poppins(color: const Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ] else if (isPlatformAdmin) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.admin_panel_settings_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text("Platform Admin", style: GoogleFonts.poppins(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryBrandColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.groups_rounded, color: primaryBrandColor, size: 30),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildP2PDebtsSection(List<Debt> debts, Color textColor, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Who owes Whom", 
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: textColor)
        ),
        const SizedBox(height: 12),
        ...debts.map((debt) {
          final fromUser = widget.allUsers.firstWhere(
            (u) => u.uid == debt.from, 
            orElse: () => model.User(
              uid: debt.from, 
              name: debt.from.length > 5 ? "Member ${debt.from.substring(debt.from.length - 4)}" : "Member ${debt.from}", 
              email: "", 
              createdAt: DateTime.now()
            )
          );
          final toUser = widget.allUsers.firstWhere(
            (u) => u.uid == debt.to, 
            orElse: () => model.User(
              uid: debt.to, 
              name: debt.to.length > 5 ? "Member ${debt.to.substring(debt.to.length - 4)}" : "Member ${debt.to}", 
              email: "", 
              createdAt: DateTime.now()
            )
          );

          final iOwe = debt.from == widget.currentUserUid;
          final owesMe = debt.to == widget.currentUserUid;
          final displayAmount = debt.amount.toStringAsFixed(0);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (iOwe || owesMe) ? primaryBrandColor.withOpacity(0.08) : textColor.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (iOwe || owesMe) ? primaryBrandColor.withOpacity(0.2) : Colors.transparent),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: (iOwe ? Colors.redAccent : accentGreen).withOpacity(0.1),
                  child: Icon(
                    iOwe ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                    color: iOwe ? Colors.redAccent : accentGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(color: textColor, fontSize: 13),
                          children: [
                            TextSpan(text: iOwe ? "You owe " : "${fromUser.name} owes "),
                            TextSpan(
                              text: owesMe ? "you" : toUser.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Text("PKR $displayAmount", 
                        style: GoogleFonts.outfit(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          color: iOwe ? Colors.redAccent : accentGreen
                        )
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildGlassActionButton({required VoidCallback onPressed, required IconData icon, required String label, required Color color}) {
    return GlassButton(
      onPressed: onPressed,
      label: label,
      icon: icon,
      color: color,
      isDarkMode: widget.isDarkMode,
    );
  }

  Widget _buildTransactionHistory(List<Expense> expenses, List<Payment> payments, Color textColor, bool isSmall, Group group, bool hasAdminRights) {
    // Combine and sort by date
    List<dynamic> combined = [...expenses, ...payments];
    combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final display = combined.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Recent Activity", 
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: textColor)
            ),
            if (combined.length > 5)
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ActivityHistoryScreen(
                      expenses: expenses,
                      payments: payments,
                      allUsers: widget.allUsers,
                      isDarkMode: widget.isDarkMode,
                    )
                  ));
                }, 
                child: Text("See All", style: TextStyle(color: primaryBrandColor))
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (combined.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text("No transactions yet", style: TextStyle(color: textColor.withOpacity(0.4))),
            ),
          ),
        ...display.map((item) {
          bool isExpense = item is Expense;
          final cat = isExpense ? categories.firstWhere((c) => c['name'] == item.category, orElse: () => categories.last) : null;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isExpense ? () => _showExpenseDetailsBottomSheet(item, group, hasAdminRights) : null,
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                isDarkMode: widget.isDarkMode,
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
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isExpense 
                              ? (item.multiplePayers != null && item.multiplePayers!.isNotEmpty
                                  ? "Paid by ${item.multiplePayers!.entries.map((e) => "${widget.allUsers.firstWhere((u) => u.uid == e.key, orElse: () => model.User(uid: e.key, name: e.key.length > 5 ? "Member ${e.key.substring(e.key.length - 4)}" : "Member ${e.key}", email: "", createdAt: DateTime.now())).name}: ${e.value.toStringAsFixed(0)}").join(", ")}"
                                  : "Paid by ${widget.allUsers.firstWhere((u) => u.uid == item.paidBy, orElse: () => model.User(uid: item.paidBy, name: item.paidBy.length > 5 ? "Member ${item.paidBy.substring(item.paidBy.length - 4)}" : "Member ${item.paidBy}", email: "", createdAt: DateTime.now())).name}")
                              : "${widget.allUsers.firstWhere((u) => u.uid == item.from, orElse: () => model.User(uid: item.from, name: item.from.length > 5 ? "Member ${item.from.substring(item.from.length - 4)}" : "Member ${item.from}", email: "", createdAt: DateTime.now())).name} paid ${widget.allUsers.firstWhere((u) => u.uid == item.to, orElse: () => model.User(uid: item.to, name: item.to.length > 5 ? "Member ${item.to.substring(item.to.length - 4)}" : "Member ${item.to}", email: "", createdAt: DateTime.now())).name}",
                            style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.5)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                        if (isExpense)
                          Text("Details", style: GoogleFonts.poppins(fontSize: 10, color: primaryBrandColor.withOpacity(0.8), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMembersGrid(Group group, Color textColor, bool isSmall, bool isCreator, bool hasAdminRights, List<Debt> debts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Participants (${group.members.length})", 
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: textColor)
            ),
            TextButton.icon(
              onPressed: () => _showAddMemberDialog(group),
              icon: Icon(Icons.person_add_rounded, size: 18, color: primaryBrandColor),
              label: Text("Add Member", style: GoogleFonts.poppins(color: primaryBrandColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isSmall ? 4 : 6,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.78,
          ),
          itemCount: group.members.length + 1,
          itemBuilder: (context, index) {
            // First item is Add Member shortcut button
            if (index == 0) {
              return GestureDetector(
                onTap: () => _showAddMemberDialog(group),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primaryBrandColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryBrandColor.withOpacity(0.4), width: 1.5),
                      ),
                      child: Icon(Icons.add_rounded, color: primaryBrandColor, size: 26),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Add",
                      maxLines: 1,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: primaryBrandColor),
                    ),
                  ],
                ),
              );
            }

            final uid = group.members[index - 1];
            final user = widget.allUsers.firstWhere(
              (u) => u.uid == uid, 
              orElse: () => model.User(uid: uid, name: "Member $index", email: "", createdAt: DateTime.now())
            );
            final bool isMe = uid == widget.currentUserUid;
            final bool isGroupAdmin = uid == group.createdBy;
            final bool canRemove = !isMe && !isGroupAdmin && hasAdminRights;

            return GestureDetector(
              onTap: () {
                _showMemberOptionsBottomSheet(user, isMe, canRemove, group, debts, isGroupAdmin, hasAdminRights);
              },
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isMe ? const Color(0xFFD4AF37) : (isGroupAdmin ? const Color(0xFF27C46E) : Colors.grey.withOpacity(0.2)),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : "U", 
                          style: TextStyle(
                            color: isMe ? const Color(0xFF0F172A) : Colors.white, 
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          )
                        ),
                      ),
                      if (isGroupAdmin)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD4AF37),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.star_rounded, size: 12, color: Colors.black),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isMe ? "You" : user.name.split(' ')[0], 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: isMe || isGroupAdmin ? FontWeight.w600 : FontWeight.normal, color: textColor.withOpacity(0.85))
                  ),
                  if (isGroupAdmin)
                    Text("Admin", style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showSettleUpBottomSheet(List<Debt> debts) {
    final myDebts = debts.where((d) => d.from == widget.currentUserUid || d.to == widget.currentUserUid).toList();
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Text("Settle Up", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Text("Select a person to settle your debt with", style: GoogleFonts.poppins(color: textColor.withOpacity(0.6))),
                const SizedBox(height: 24),
                if (myDebts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text("You are all settled up!", style: GoogleFonts.poppins(color: textColor.withOpacity(0.5)))),
                  ),
                ...myDebts.map((debt) {
                  final otherUid = debt.from == widget.currentUserUid ? debt.to : debt.from;
                  final user = widget.allUsers.firstWhere((u) => u.uid == otherUid);
                  bool iOwe = debt.from == widget.currentUserUid;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: primaryBrandColor.withOpacity(0.1), 
                        child: Text(user.name[0].toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: primaryBrandColor))
                      ),
                      title: Text(
                        user.name, 
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        iOwe ? "You owe PKR ${debt.amount}" : "Owes you PKR ${debt.amount}", 
                        style: TextStyle(color: iOwe ? Colors.redAccent : accentGreen),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () => _performSettlement(debt, otherUid, iOwe),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentGreen, 
                            foregroundColor: Colors.white, 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 12)
                          ),
                          child: const Text("Pay", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _performSettlement(Debt debt, String otherUid, bool iOwe) async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    
    final payment = Payment(
      from: iOwe ? widget.currentUserUid : otherUid,
      to: iOwe ? otherUid : widget.currentUserUid,
      involvedUsers: [widget.currentUserUid, otherUid],
      amount: debt.amount,
      groupId: widget.group.id,
      timestamp: DateTime.now(),
    );

    await db.addPayment(payment);
    final currentUser = widget.allUsers.firstWhere((u) => u.uid == widget.currentUserUid, orElse: () => model.User(uid: widget.currentUserUid, name: "User", email: "", createdAt: DateTime.now()));
    await UserActivityService.logPaymentCreated(widget.currentUserUid, currentUser.name, debt.amount, payment.from, payment.to);
    
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Settlement recorded successfully!"), backgroundColor: accentGreen)
    );
  }

  void _showRemoveMemberDialog(String name, String uid, List<Debt> debts) {
    final bool hasUnsettledDebt = debts.any((d) => d.from == uid || d.to == uid);
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
    showDialog(
      context: context,
      builder: (_) => GlassDialog(
        isDarkMode: widget.isDarkMode,
        title: "Remove Member",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Are you sure you want to remove $name from this group?",
                style: TextStyle(color: textColor)),
            if (hasUnsettledDebt) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "$name has unsettled balance in this group. Past transactions remain recorded, but they will be excluded from future expenses.",
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.orangeAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: textColor.withOpacity(0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            onPressed: () {
              widget.onRemoveMember?.call(uid);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$name removed from group"), backgroundColor: Colors.redAccent)
              );
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }
  void _showAddMemberDialog(Group group) {
    showDialog(
      context: context,
      builder: (_) => AddMemberDialog(
        onAddMember: (mUid) => widget.onAddMember(mUid, widget.currentUserUid),
        isDarkMode: widget.isDarkMode,
        existingMembers: group.members,
      ),
    );
  }

  void _addExpense(Group group) async {
    final expense = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          availableMembers: widget.allUsers.where((u) => group.members.contains(u.uid)).toList(),
          isFromGroup: true,
          currentUserUid: widget.currentUserUid,
        ),
      ),
    );
    if (expense != null) {
      widget.onAddExpense?.call(expense);
      await UserActivityService.logExpenseCreated(widget.currentUserUid, "User", expense.description, expense.amount);
      if (!mounted) return;
    }
  }

  void _showMemberOptionsBottomSheet(
    model.User user, 
    bool isMe, 
    bool canRemove, 
    Group group, 
    List<Debt> debts, 
    bool isTargetAdmin, 
    bool hasAdminRights,
  ) {
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF1E2230) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 30,
                backgroundColor: primaryBrandColor.withOpacity(0.15),
                child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : "U", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBrandColor)),
              ),
              const SizedBox(height: 12),
              Text(user.name, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
              if (user.email.isNotEmpty)
                Text(user.email, style: GoogleFonts.poppins(fontSize: 13, color: textColor.withOpacity(0.5))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (isTargetAdmin ? const Color(0xFFD4AF37) : (user.isAdmin || user.role.toLowerCase() == 'admin' ? Colors.amber : const Color(0xFF27C46E))).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (isTargetAdmin ? const Color(0xFFD4AF37) : (user.isAdmin || user.role.toLowerCase() == 'admin' ? Colors.amber : const Color(0xFF27C46E))).withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTargetAdmin ? Icons.shield_rounded : (user.isAdmin || user.role.toLowerCase() == 'admin' ? Icons.admin_panel_settings_rounded : Icons.person_rounded),
                      size: 14,
                      color: isTargetAdmin ? const Color(0xFFD4AF37) : (user.isAdmin || user.role.toLowerCase() == 'admin' ? Colors.amber : const Color(0xFF27C46E)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isTargetAdmin ? "Group Creator (Admin)" : (user.isAdmin || user.role.toLowerCase() == 'admin' ? "Platform Admin" : "Group Member"),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isTargetAdmin ? const Color(0xFFD4AF37) : (user.isAdmin || user.role.toLowerCase() == 'admin' ? Colors.amber : const Color(0xFF27C46E)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!isMe) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF27C46E).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF27C46E)),
                  ),
                  title: Text("Direct Message", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor)),
                  subtitle: Text("Chat 1-on-1 with ${user.name}", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrivateChatScreen(
                          recipient: user,
                          currentUser: widget.allUsers.firstWhere(
                            (u) => u.uid == widget.currentUserUid,
                            orElse: () => model.User(uid: widget.currentUserUid, name: "You", email: "", createdAt: DateTime.now()),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
              if (isMe && !isTargetAdmin)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.exit_to_app_rounded, color: Colors.orangeAccent),
                  ),
                  title: Text("Leave Group", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.orangeAccent)),
                  subtitle: Text("Exit this group voluntarily", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showLeaveGroupDialog(group, debts);
                  },
                ),
              if (canRemove)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.person_remove_rounded, color: Colors.redAccent),
                  ),
                  title: Text("Remove from Group", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                  subtitle: Text("Remove ${user.name} from this group", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showRemoveMemberDialog(user.name, user.uid, debts);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showLeaveGroupDialog(Group group, List<Debt> debts) {
    final myDebts = debts.where((d) => d.from == widget.currentUserUid).toList();
    final double totalOwed = myDebts.fold(0.0, (sum, d) => sum + d.amount);
    final hasPendingDues = totalOwed > 0;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E2230) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.exit_to_app_rounded, color: Colors.orangeAccent),
            const SizedBox(width: 8),
            Text("Leave Group", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Are you sure you want to leave '${group.name}'?", style: GoogleFonts.poppins(color: textColor.withOpacity(0.8), fontSize: 14)),
            if (hasPendingDues) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "You currently owe PKR ${totalOwed.toStringAsFixed(2)} in this group. It is recommended to settle up before leaving.",
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: textColor.withOpacity(0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(ctx);
              widget.onRemoveMember?.call(widget.currentUserUid);
              await UserActivityService.logGroupJoined(widget.currentUserUid, "User", "${group.name} (Left)");
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("You have left '${group.name}'", style: GoogleFonts.poppins()),
                    backgroundColor: Colors.orangeAccent,
                  ),
                );
              }
            },
            child: const Text("Leave", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog(Group group) {
    final nameCtrl = TextEditingController(text: group.name);
    String selectedType = group.type;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF1E2230) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("Edit Group Details", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.poppins(color: textColor),
                decoration: InputDecoration(
                  labelText: "Group Name",
                  labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                  filled: true,
                  fillColor: textColor.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: ["Trip", "Home", "Couple", "Event", "Other"].contains(selectedType) ? selectedType : "Other",
                dropdownColor: widget.isDarkMode ? const Color(0xFF1E2230) : Colors.white,
                style: GoogleFonts.poppins(color: textColor),
                decoration: InputDecoration(
                  labelText: "Category / Type",
                  labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                  filled: true,
                  fillColor: textColor.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: "Trip", child: Text("Trip / Travel")),
                  DropdownMenuItem(value: "Home", child: Text("Home / Flatmates")),
                  DropdownMenuItem(value: "Couple", child: Text("Couple")),
                  DropdownMenuItem(value: "Event", child: Text("Event / Party")),
                  DropdownMenuItem(value: "Other", child: Text("Other")),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedType = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: TextStyle(color: textColor.withOpacity(0.5))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBrandColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                if (newName.isNotEmpty) {
                  final db = Provider.of<DatabaseService>(context, listen: false);
                  await db.updateGroup(group.copyWith(name: newName, type: selectedType));
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Group updated successfully!"), backgroundColor: Color(0xFF27C46E)),
                    );
                  }
                }
              },
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteGroupDialog(Group group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E2230) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Group?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        content: Text("Are you sure you want to permanently delete \"${group.name}\"? This action cannot be undone.", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final db = Provider.of<DatabaseService>(context, listen: false);
              for (var m in group.members) {
                await db.decrementUserGroupsJoined(m);
              }
              await FirebaseFirestore.instance.collection('groups').doc(group.id).delete();
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Group \"${group.name}\" deleted"), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showExpenseDetailsBottomSheet(Expense expense, Group group, bool hasAdminRights) {
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
    final payer = widget.allUsers.firstWhere(
      (u) => u.uid == expense.paidBy,
      orElse: () => model.User(uid: expense.paidBy, name: expense.paidBy.length > 5 ? "Member ${expense.paidBy.substring(expense.paidBy.length - 4)}" : "Member ${expense.paidBy}", email: "", createdAt: DateTime.now()),
    );
    final cat = categories.firstWhere((c) => c['name'] == expense.category, orElse: () => categories.last);
    final bool canDelete = expense.paidBy == widget.currentUserUid || hasAdminRights;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF1E2230) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (cat['color'] as Color).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(expense.description, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                        Text("${expense.category} • ${expense.timestamp.day}/${expense.timestamp.month}/${expense.timestamp.year}",
                            style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.5))),
                      ],
                    ),
                  ),
                  Text("PKR ${expense.amount.toStringAsFixed(0)}", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF27C46E))),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Paid By", style: GoogleFonts.poppins(fontSize: 13, color: textColor.withOpacity(0.6))),
                        Text(payer.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Split Among", style: GoogleFonts.poppins(fontSize: 13, color: textColor.withOpacity(0.6))),
                        Text("${expense.involvedMembers.length} participants", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: expense.involvedMembers.map((uid) {
                        final u = widget.allUsers.firstWhere(
                          (usr) => usr.uid == uid,
                          orElse: () => model.User(uid: uid, name: uid.length > 5 ? "User ${uid.substring(uid.length - 4)}" : "User $uid", email: "", createdAt: DateTime.now()),
                        );
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryBrandColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(u.name.split(' ')[0], style: GoogleFonts.poppins(fontSize: 11, color: primaryBrandColor, fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (canDelete)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.15),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: Text("Delete Expense", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDeleteExpense(expense);
                    },
                  ),
                )
              else
                Center(
                  child: Text(
                    "Only the payer (${payer.name}) or group admin can delete this expense.",
                    style: GoogleFonts.poppins(fontSize: 11, color: textColor.withOpacity(0.4)),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteExpense(Expense expense) {
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E2230) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Expense?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        content: Text("Are you sure you want to permanently delete \"${expense.description}\"? All debts and balances will be recalculated.",
            style: GoogleFonts.poppins(fontSize: 13, color: textColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final db = Provider.of<DatabaseService>(context, listen: false);
              await db.deleteExpense(expense.id!);
              final currentUser = widget.allUsers.firstWhere((u) => u.uid == widget.currentUserUid, orElse: () => model.User(uid: widget.currentUserUid, name: "User", email: "", createdAt: DateTime.now()));
              await UserActivityService.logExpenseDeleted(widget.currentUserUid, currentUser.name, expense.description, expense.amount);
              if (mounted) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Expense \"${expense.description}\" deleted successfully"), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Removed unused methods: _showMemberDetailsDialog, _showSettleUpDialog, _showAllExpensesDialog
}
