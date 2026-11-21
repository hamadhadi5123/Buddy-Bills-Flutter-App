import 'dart:ui';
import 'package:flutter/material.dart';
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
                        IconButton(
                          icon: Icon(Icons.forum_outlined, color: primaryBrandColor),
                          onPressed: () {
                            final currentUser = widget.allUsers.firstWhere((u) => u.uid == widget.currentUserUid);
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
                          onPressed: _showAddMemberDialog,
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
                              _buildGlassHeader(currentGroup, textColor, isSmallScreen),
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
                              _buildTransactionHistory(expenses, payments, textColor, isSmallScreen, currentGroup),
                              const SizedBox(height: 32),
                              _buildMembersGrid(currentGroup, textColor, isSmallScreen, isCreator),
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

  Widget _buildGlassHeader(Group group, Color textColor, bool isSmall) {
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

  Widget _buildTransactionHistory(List<Expense> expenses, List<Payment> payments, Color textColor, bool isSmall, Group group) {
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
                  Text("PKR ${item.amount.toStringAsFixed(0)}", 
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMembersGrid(Group group, Color textColor, bool isSmall, bool isCreator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Participants", 
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: textColor)
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isSmall ? 4 : 6,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: group.members.length,
          itemBuilder: (context, index) {
            final uid = group.members[index];
            final user = widget.allUsers.firstWhere((u) => u.uid == uid, orElse: () => model.User(uid: uid, name: "User", email: "", createdAt: DateTime.now()));
            final bool isMe = uid == widget.currentUserUid;

            return GestureDetector(
              onTap: () {
                if (!isMe) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrivateChatScreen(
                        recipient: user,
                        currentUser: widget.allUsers.firstWhere((u) => u.uid == widget.currentUserUid),
                      ),
                    ),
                  );
                }
              },
              onLongPress: () {
                final String? addedBy = group.memberAddedBy[uid];
                final bool iAddedThem = addedBy == widget.currentUserUid;

                if (!isMe && (isCreator || iAddedThem)) {
                  _showRemoveMemberDialog(user.name, uid);
                }
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isMe ? primaryBrandColor : Colors.grey.withOpacity(0.2),
                    child: Text(user.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  Text(user.name.split(' ')[0], 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 10, color: textColor.withOpacity(0.7))
                  ),
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

  void _showRemoveMemberDialog(String name, String uid) {
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
    showDialog(
      context: context,
      builder: (_) => GlassDialog(
        isDarkMode: widget.isDarkMode,
        title: "Remove Member",
        content: Text("Are you sure you want to remove $name from this group?",
            style: TextStyle(color: textColor)),
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
  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (_) => AddMemberDialog(
        onAddMember: (mUid) => widget.onAddMember(mUid, widget.currentUserUid),
        isDarkMode: widget.isDarkMode,
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

  // Removed unused methods: _showMemberDetailsDialog, _showSettleUpDialog, _showAllExpensesDialog
}
