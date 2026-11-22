import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../services/theme_provider.dart';
import '../services/user_activity_service.dart';
import '../models/user_activity.dart';
import '../models/user.dart' as model;
import '../models/group.dart';
import '../models/expense.dart';
import '../models/payment.dart';
import '../models/balance.dart';
import './auth_wrapper.dart';
import './groups_screen.dart';
import './friends_screen.dart';
import './activity_screen.dart';
import './account_screen.dart';
import './inbox_screen.dart';
import './create_group_screen.dart';
import './group_detail_screen.dart';
import './add_expense_screen.dart';
import '../widgets/glass_widgets.dart';

class HomeNavigation extends StatefulWidget {
  final model.User user;
  const HomeNavigation({super.key, required this.user});

  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _currentIndex = 0;
  bool get isDarkMode => Provider.of<ThemeProvider>(context).isDarkMode;


  void _logout(BuildContext context) async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    await db.updateUserPresence(widget.user.uid, false);
    await fb.FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  // Helper to calculate total balances from expenses and payments
  List<Balance> _calculateTotalBalances(List<Expense> expenses, List<Payment> payments, List<model.User> allUsers) {
    final Map<String, double> balanceMap = {};
    for (var u in allUsers) {
      if (u.uid != widget.user.uid) {
        balanceMap[u.uid] = 0.0;
      }
    }

    // Process expenses
    for (var exp in expenses) {
      // 1. Calculate WHO PAID (Credit)
      final Map<String, double> payers = {};
      if (exp.multiplePayers != null && exp.multiplePayers!.isNotEmpty) {
        payers.addAll(exp.multiplePayers!);
      } else {
        payers[exp.paidBy] = exp.amount;
      }

      // 2. Calculate WHO OWES (Debt)
      final Map<String, double> owes = {};
      if (exp.splitType == 'equally') {
        final share = exp.amount / (exp.involvedMembers.isEmpty ? 1 : exp.involvedMembers.length);
        for (var m in exp.involvedMembers) {
          owes[m] = share;
        }
      } else if (exp.splitType == 'unequally' && exp.unequalAmounts != null) {
        owes.addAll(exp.unequalAmounts!);
      }

      // 3. Update Balance relative to Current User
      // If I paid: Others owe me (+)
      // If Others paid: I owe them (-)
      
      final myPaid = payers[widget.user.uid] ?? 0.0;
      final myOwe = owes[widget.user.uid] ?? 0.0;

      // Distribution of my credit to others
      if (myPaid > 0) {
        // I contributed. Others who owe money for this expense owe me their portion.
        // Actually, simpler: my net contribution for this expense relative to each other person.
        // This is tricky for multi-payer. 
        // Let's use the DebtCalculator logic approach: simplify to net balance.
      }

      // Actually, for individual balances:
      // A's balance to B = (A's contribution to B's share) - (B's contribution to A's share)
      // This is exactly what DebtCalculator does.
      
      // Let's use a simpler net balance approach:
      // For each user 'U', their balance relative to me is:
      // (My Contribution to U's Debt) - (U's Contribution to My Debt)
      
      for (var u in balanceMap.keys) {
        final uPaid = payers[u] ?? 0.0;
        final uOwe = owes[u] ?? 0.0;
        
        // This expense total
        if (exp.amount > 0) {
           // My portion of U's debt: (MyPaid / TotalPaid) * U'sOwe
           final myPortionOfUOwe = (myPaid / exp.amount) * uOwe;
           final uPortionOfMyOweCorrect = (uPaid / exp.amount) * myOwe;
           
           balanceMap[u] = balanceMap[u]! + myPortionOfUOwe - uPortionOfMyOweCorrect;
        }
      }
    }

    // Process payments (settlements)
    for (var pay in payments) {
      if (pay.from == widget.user.uid) {
        if (balanceMap.containsKey(pay.to)) {
          balanceMap[pay.to] = balanceMap[pay.to]! + pay.amount;
        }
      } else if (pay.to == widget.user.uid) {
        if (balanceMap.containsKey(pay.from)) {
          balanceMap[pay.from] = balanceMap[pay.from]! - pay.amount;
        }
      }
    }

    return balanceMap.entries
        .map((e) {
          final user = allUsers.firstWhere(
            (u) => u.uid == e.key, 
            orElse: () => model.User(
              uid: e.key, 
              name: e.key.length > 5 ? "Member ${e.key.substring(e.key.length - 4)}" : "Member ${e.key}", 
              email: '', 
              createdAt: DateTime.now()
            )
          );
          return Balance(member: user.name, amount: e.value);
        })
        .where((b) => b.amount.abs() > 0.01)
        .toList();
  }



  List<Balance> _calculateGroupBalances(List<Expense> expenses, List<Payment> payments, Group group, List<model.User> allUsers) {
    final Map<String, double> balanceMap = {for (var m in group.members) m: 0.0};
    
    // Process expenses within the group
    for (var exp in expenses) { 
      // 1. Calculate WHO PAID (Credit)
      final Map<String, double> payers = {};
      if (exp.multiplePayers != null && exp.multiplePayers!.isNotEmpty) {
        payers.addAll(exp.multiplePayers!);
      } else {
        payers[exp.paidBy] = exp.amount;
      }

      // 2. Calculate WHO OWES (Debt)
      final Map<String, double> owes = {};
      if (exp.splitType == 'equally') {
        final share = exp.amount / (exp.involvedMembers.isEmpty ? 1 : exp.involvedMembers.length);
        for (var m in exp.involvedMembers) {
          owes[m] = share;
        }
      } else if (exp.splitType == 'unequally' && exp.unequalAmounts != null) {
        owes.addAll(exp.unequalAmounts!);
      }

      // 3. Update Individual Net Balances for everyone in the group
      for (var member in balanceMap.keys) {
        final mPaid = payers[member] ?? 0.0;
        final mOwe = owes[member] ?? 0.0;
        
        // Net change for this member = Contribution - Debt
        // (This is the group-centric view where sum of all balances = 0)
        balanceMap[member] = balanceMap[member]! + mPaid - mOwe;
      }
    }

    // Process payments within the group
    for (var pay in payments) {
      if (pay.groupId == group.id) {
        if (balanceMap.containsKey(pay.from)) {
          balanceMap[pay.from] = balanceMap[pay.from]! + pay.amount;
        }
        if (balanceMap.containsKey(pay.to)) {
          balanceMap[pay.to] = balanceMap[pay.to]! - pay.amount;
        }
      }
    }

    return balanceMap.entries.map((e) {
      final user = allUsers.firstWhere(
        (u) => u.uid == e.key, 
        orElse: () => model.User(
          uid: e.key, 
          name: e.key.length > 5 ? "Member ${e.key.substring(e.key.length - 4)}" : "Member ${e.key}", 
          email: '', 
          createdAt: DateTime.now()
        )
      );
      return Balance(member: user.name, amount: e.value);
    }).toList();
  }

  Color get accentGreen => const Color(0xFF27C46E);
  Color get primaryBrandColor => const Color(0xFFD4AF37); // Golden color


  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return StreamBuilder<List<model.User>>(
      stream: db.streamUsers(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final allUsers = userSnapshot.data!;

        return StreamBuilder<List<Group>>(
          stream: db.streamGroups(widget.user.uid),
          builder: (context, groupSnapshot) {
            final groups = groupSnapshot.data ?? [];

            return StreamBuilder<List<Expense>>(
              stream: db.streamExpenses(userUid: widget.user.uid),
              builder: (context, expenseSnapshot) {
                final expenses = expenseSnapshot.data ?? [];

                return StreamBuilder<List<Payment>>(
                  stream: db.streamPayments(userUid: widget.user.uid),
                  builder: (context, paymentSnapshot) {
                    final payments = paymentSnapshot.data ?? [];
                    final overallBalances = _calculateTotalBalances(expenses, payments, allUsers);

                    return Scaffold(
                      extendBody: true,
                      backgroundColor: isDarkMode ? Colors.black : Colors.white,
                      body: GlassBackground(
                        isDarkMode: isDarkMode,
                        child: IndexedStack(
                          index: _currentIndex,
                          children: [
                            GroupsScreen(
                              groups: groups,
                              currentUser: widget.user.name,
                              currentUserUid: widget.user.uid,
                              overallBalances: overallBalances,
                              onCreateGroup: () async {
                                final created = await Navigator.push<Group?>(
                                    context,
                                    MaterialPageRoute(builder: (context) => CreateGroupScreen(currentUserUid: widget.user.uid, isDarkMode: isDarkMode)));
                                if (created != null) {
                                  await db.createGroup(created.copyWith(
                                    members: [widget.user.uid, ...created.members],
                                    createdBy: widget.user.uid,
                                    memberAddedBy: created.memberAddedBy,
                                    createdAt: DateTime.now(),
                                  ));
                                  await UserActivityService.logGroupCreated(widget.user.uid, widget.user.name, created.name);
                                }
                              },
                              onOpenGroup: (group) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GroupDetailScreen(
                                      group: group,
                                      onAddMember: (mUid, adderUid) async {
                                        if (group.members.contains(mUid)) return;
                                        final updatedMembers = [...group.members, mUid];
                                        final updatedAddedBy = Map<String, String>.from(group.memberAddedBy);
                                        updatedAddedBy[mUid] = adderUid;
                                        
                                        final invitedUser = allUsers.firstWhere((u) => u.uid == mUid, orElse: () => model.User(uid: mUid, name: "Someone", email: "", createdAt: DateTime.now()));
                                        
                                        await db.updateGroup(group.copyWith(
                                          members: updatedMembers,
                                          memberAddedBy: updatedAddedBy,
                                        ));
                                        
                                        // Update user stats
                                        await db.incrementUserGroupsJoined(mUid);
                                        await UserActivityService.logGroupJoined(mUid, invitedUser.name, group.name);
                                      },
                                      onRemoveMember: (mUid) async {
                                        final updatedMembers = group.members.where((m) => m != mUid).toList();
                                        final updatedAddedBy = Map<String, String>.from(group.memberAddedBy);
                                        updatedAddedBy.remove(mUid);

                                        await db.updateGroup(group.copyWith(
                                          members: updatedMembers,
                                          memberAddedBy: updatedAddedBy,
                                        ));
                                        
                                        // Update user stats
                                        await db.decrementUserGroupsJoined(mUid);
                                      },
                                      onAddExpense: (e) async {
                                        await db.addExpense(e.copyWith(groupId: group.id, timestamp: DateTime.now()));
                                        await UserActivityService.logExpenseCreated(widget.user.uid, widget.user.name, e.description, e.amount);
                                      },
                                      groupExpenses: expenses.where((e) => e.groupId == group.id).toList(),
                                      groupBalances: _calculateGroupBalances(
                                        expenses.where((e) => e.groupId == group.id).toList(),
                                        payments.where((p) => p.groupId == group.id).toList(),
                                        group,
                                        allUsers,
                                      ),
                                      allUsers: allUsers,
                                      currentUserUid: widget.user.uid,
                                      isDarkMode: isDarkMode,
                                    ),
                                  ),
                                );
                              },
                              onAddExpense: () async {
                                final newExpense = await Navigator.push<Expense?>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddExpenseScreen(
                                      currentUserUid: widget.user.uid,
                                      isFromGroup: false,
                                      availableMembers: allUsers,
                                    ),
                                  ),
                                );
                                if (newExpense != null) {
                                  await db.addExpense(newExpense.copyWith(timestamp: DateTime.now()));
                                  await UserActivityService.logExpenseCreated(widget.user.uid, widget.user.name, newExpense.description, newExpense.amount);
                                }
                              },
                              isDarkMode: isDarkMode,
                            ),
                            FriendsScreen(
                              allUsers: allUsers,
                              currentUser: widget.user,
                              balances: overallBalances,
                              isDarkMode: isDarkMode,
                            ),
                            InboxScreen(
                              currentUser: widget.user,
                              isDarkMode: isDarkMode,
                            ),
                            StreamBuilder<List<UserActivity>>(
                              stream: UserActivityService.getUserActivities(widget.user.uid),
                              builder: (context, activitySnapshot) {
                                return ActivityScreen(
                                  activities: activitySnapshot.data,
                                  isDarkMode: isDarkMode,
                                  error: activitySnapshot.hasError ? activitySnapshot.error.toString() : null,
                                  isLoading: activitySnapshot.connectionState == ConnectionState.waiting,
                                );
                              }
                            ),
                            AccountScreen(
                              user: widget.user,
                              onLogout: () => _logout(context),
                            ),
                          ],
                        ),
                      ),
                      bottomNavigationBar: _buildGlassNavigationBar(),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGlassNavigationBar() {
    final Color glassBorderColor = isDarkMode
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.05);
    final Color glassFillColor = isDarkMode
        ? Colors.black.withOpacity(0.4)
        : Colors.white.withOpacity(0.6);

    return Container(
      height: 85,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: glassFillColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: glassBorderColor, width: 1.5),
            ),
            child: StreamBuilder<int>(
              stream: Provider.of<DatabaseService>(context, listen: false).streamTotalUnreadMessages(widget.user.uid),
              builder: (context, unreadSnapshot) {
                final unreadCount = unreadSnapshot.data ?? 0;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.grid_view_rounded, "Groups"),
                    _buildNavItem(1, Icons.people_alt_rounded, "Friends"),
                    _buildNavItem(2, Icons.forum_rounded, "Chats", badgeCount: unreadCount),
                    _buildNavItem(3, Icons.history_rounded, "History"),
                    _buildNavItem(4, Icons.person_rounded, "Profile"),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {int badgeCount = 0}) {
    bool isSelected = _currentIndex == index;
    Color color = isSelected ? primaryBrandColor : (isDarkMode ? Colors.white38 : Colors.black38);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? primaryBrandColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 26),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5252).withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Color bgColor() => isDarkMode ? Colors.black : Colors.white;
  Color textColor() => isDarkMode ? Colors.white : Colors.black87;
  Color iconColor() => isDarkMode ? Colors.white : Colors.black87;
  Color indicatorColor() => Colors.green.shade900;
}
