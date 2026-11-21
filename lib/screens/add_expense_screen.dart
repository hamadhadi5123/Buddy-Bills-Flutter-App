import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/expense.dart';
import '../models/user.dart' as model;
import '../widgets/glass_widgets.dart';

class AddExpenseScreen extends StatefulWidget {
  final List<model.User> availableMembers;
  final bool isFromGroup;
  final String currentUserUid;
  final bool isDarkMode; 

  const AddExpenseScreen({
    super.key,
    required this.availableMembers,
    required this.isFromGroup,
    required this.currentUserUid,
    this.isDarkMode = true, 
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  String? paidByUid;
  bool isMultiplePayers = false;
  String splitType = "equally";
  Map<String, bool> selectedMembers = {};
  Map<String, TextEditingController> amountControllers = {};
  Map<String, TextEditingController> multiplePayerControllers = {};
  String selectedCategory = 'Food';

  final List<Map<String, dynamic>> categories = [
    {'name': 'Food', 'icon': Icons.fastfood_rounded, 'color': const Color(0xFFFF9F1C)},
    {'name': 'Travel', 'icon': Icons.airplanemode_active_rounded, 'color': const Color(0xFF2EC4B6)},
    {'name': 'Home', 'icon': Icons.home_rounded, 'color': const Color(0xFFE71D36)},
    {'name': 'Fun', 'icon': Icons.celebration_rounded, 'color': const Color(0xFF9C27B0)},
    {'name': 'Other', 'icon': Icons.auto_awesome_rounded, 'color': const Color(0xFF607D8B)},
  ];

  @override
  void initState() {
    super.initState();
    paidByUid = widget.currentUserUid;
    
    // Include all members (admins can participate too)
    final nonAdminMembers = widget.availableMembers.toList();
    
    for (var member in nonAdminMembers) {
      selectedMembers[member.uid] = true;
      amountControllers[member.uid] = TextEditingController();
      multiplePayerControllers[member.uid] = TextEditingController();
    }
  }

  @override
  void dispose() {
    descCtrl.dispose();
    amountCtrl.dispose();
    for (var controller in amountControllers.values) {
      controller.dispose();
    }
    for (var controller in multiplePayerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void toggleMember(String memberUid) {
    setState(() {
      selectedMembers[memberUid] = !(selectedMembers[memberUid] ?? false);
      if (splitType == "equally") calculateEqualAmounts();
    });
  }

  void calculateEqualAmounts() {
    if (amountCtrl.text.isEmpty) return;
    final total = double.tryParse(amountCtrl.text) ?? 0;
    final involved = selectedMembers.entries.where((e) => e.value).map((e) => e.key).toList();
    if (involved.isEmpty) return;
    final equalAmount = total / involved.length;
    for (var member in selectedMembers.keys) {
      amountControllers[member]?.text = involved.contains(member) ? equalAmount.toStringAsFixed(2) : "0.00";
    }
  }

  Expense? createExpense() {
    final desc = descCtrl.text.trim();
    final amt = double.tryParse(amountCtrl.text) ?? 0;
    if (desc.isEmpty) { _snack("What was this for?"); return null; }
    if (amt <= 0) { _snack("Please enter an amount"); return null; }
    
    final involved = selectedMembers.entries.where((e) => e.value).map((e) => e.key).toList();
    if (involved.isEmpty) { _snack("Who's splitting this?"); return null; }

    Map<String, double> finalUnequalAmounts = {};
    if (splitType == "unequally") {
        double totalCheck = 0;
        for (var member in involved) {
          final m = double.tryParse(amountControllers[member]?.text ?? "0") ?? 0;
          finalUnequalAmounts[member] = m;
          totalCheck += m;
        }
        if ((totalCheck - amt).abs() > 1.0) {
          _snack("Split total doesn't match PKR $amt (Off by ${(amt - totalCheck).abs().toStringAsFixed(2)})");
          return null;
        }
    }

    Map<String, double>? finalMultiplePayers;
    if (isMultiplePayers) {
      finalMultiplePayers = {};
      double paidTotal = 0;
      for (var controllerEntry in multiplePayerControllers.entries) {
        final val = double.tryParse(controllerEntry.value.text) ?? 0;
        if (val > 0) {
          finalMultiplePayers[controllerEntry.key] = val;
          paidTotal += val;
        }
      }
      if ((paidTotal - amt).abs() > 1.0) {
        _snack("Total paid must match PKR $amt (Paid: $paidTotal)");
        return null;
      }
      if (finalMultiplePayers.isEmpty) {
        _snack("At least one person must pay!");
        return null;
      }
    }

    final allParticipantsSet = <String>{...involved};
    if (isMultiplePayers && finalMultiplePayers != null) {
      allParticipantsSet.addAll(finalMultiplePayers.keys);
    } else {
      allParticipantsSet.add(paidByUid ?? widget.currentUserUid);
    }

    return Expense(
      description: desc,
      paidBy: isMultiplePayers ? "" : (paidByUid ?? widget.currentUserUid),
      multiplePayers: isMultiplePayers ? finalMultiplePayers : null,
      amount: amt,
      involvedMembers: involved,
      allParticipants: allParticipantsSet.toList(),
      splitType: splitType,
      unequalAmounts: splitType == "unequally" ? finalUnequalAmounts : null,
      category: selectedCategory,
      timestamp: DateTime.now(),
    );
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(m, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF6C63FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    )
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6C63FF);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: FittedBox(fit: BoxFit.scaleDown, child: Text("Add Expense", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GlassButton(
              onPressed: () {
                final e = createExpense();
                if (e != null) Navigator.pop(context, e);
              },
              label: "SAVE",
              color: const Color(0xFF27C46E),
              isDarkMode: isDark,
            ),
          ),
        ],
      ),
      body: GlassBackground(
        isDarkMode: isDark,
        child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount & Description Card
                  GlassCard(
                    isDarkMode: isDark,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        TextField(
                          controller: descCtrl,
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                          cursorColor: primaryColor,
                          decoration: InputDecoration(
                            hintText: "What's this for?",
                            hintStyle: GoogleFonts.poppins(color: textColor.withValues(alpha: 0.3)),
                            prefixIcon: Icon(Icons.edit_note_rounded, color: primaryColor, size: 28),
                            border: InputBorder.none,
                          ),
                        ).animate().fadeIn().slideX(begin: -0.1),
                        Divider(color: textColor.withValues(alpha: 0.1), height: 32),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: 100, maxWidth: MediaQuery.of(context).size.width - 100),
                            child: IntrinsicWidth(
                              child: TextField(
                                controller: amountCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) { if (splitType == "equally") calculateEqualAmounts(); },
                                style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: textColor),
                                textAlign: TextAlign.center,
                                cursorColor: primaryColor,
                                decoration: InputDecoration(
                                  hintText: "0.00",
                                  hintStyle: TextStyle(color: textColor.withValues(alpha: 0.1)),
                                  prefixText: "PKR ",
                                  prefixStyle: GoogleFonts.outfit(fontSize: 20, color: textColor.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                        ).animate().scale(delay: 100.ms),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Text("Category", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 16),
                  _buildCategorySelector(textColor),
                  
                  const SizedBox(height: 32),
                  Text("Transaction Details", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 16),
                  
                  GlassCard(
                    isDarkMode: isDark,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildPaddedRow(
                          icon: Icons.payments_rounded,
                          label: "Multiple Payers",
                          textColor: textColor,
                          trailing: Switch.adaptive(
                            value: isMultiplePayers,
                            activeColor: primaryColor,
                            onChanged: (val) => setState(() => isMultiplePayers = val),
                          ),
                        ),
                        if (!isMultiplePayers) ...[
                          Divider(height: 32, thickness: 1, color: textColor.withValues(alpha: 0.05)),
                          _buildPaddedRow(
                            icon: Icons.person_rounded,
                            label: "Paid by",
                            textColor: textColor,
                            trailing: Container(
                              constraints: const BoxConstraints(maxWidth: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(color: primaryColor.withValues(alpha: isDark ? 0.1 : 0.05), borderRadius: BorderRadius.circular(12)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: paidByUid,
                                  isExpanded: false,
                                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
                                  dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                                  items: widget.availableMembers
                                    .map((u) => DropdownMenuItem(
                                    value: u.uid,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 90),
                                      child: Text(
                                        u.name,
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  )).toList(),
                                  onChanged: (val) => setState(() => paidByUid = val),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (isMultiplePayers) ...[
                          Divider(height: 32, thickness: 1, color: textColor.withValues(alpha: 0.05)),
                          Column(
                            children: widget.availableMembers
                              .map((u) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: primaryColor.withValues(alpha: 0.2),
                                      child: Text(u.name[0].toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(u.name, style: GoogleFonts.poppins(fontSize: 12, color: textColor))),
                                    Container(
                                      width: 80,
                                      height: 35,
                                      child: TextField(
                                        controller: multiplePayerControllers[u.uid],
                                        keyboardType: TextInputType.number,
                                        style: GoogleFonts.outfit(fontSize: 12, color: textColor),
                                        decoration: InputDecoration(
                                          hintText: "0",
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                          filled: true,
                                          fillColor: textColor.withValues(alpha: 0.05),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )).toList(),
                          ),
                        ],
                        Divider(height: 32, thickness: 1, color: textColor.withValues(alpha: 0.05)),
                        Row(
                          children: [
                            _buildSplitButton("Equally", splitType == "equally", primaryColor, isDark),
                            const SizedBox(width: 12),
                            _buildSplitButton("Unequally", splitType == "unequally", primaryColor, isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
    
                  const SizedBox(height: 32),
                  Text("Split Summary", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 16),
                  
                  GlassCard(
                    isDarkMode: isDark,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: widget.availableMembers
                          .map<Widget>((u) {
                        final isSelected = selectedMembers[u.uid] ?? false;
                        return _buildMemberTile(u, isSelected, textColor, primaryColor, isDark);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildPaddedRow({required IconData icon, required String label, required Color textColor, required Widget trailing}) {
    return Row(
      children: [
        Icon(icon, color: textColor.withValues(alpha: 0.4), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label, 
            style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          )
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    );
  }

  Widget _buildSplitButton(String label, bool isSelected, Color primary, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          splitType = label.toLowerCase();
          if (splitType == "equally") calculateEqualAmounts();
        }),
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? primary : (isDark ? Colors.white.withValues(alpha: 0.05) : primary.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? primary : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent)),
          ),
          child: Center(
            child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white70 : primary))),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(Color textColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategory == cat['name'];
          final Color color = cat['color'];
          return GestureDetector(
            onTap: () => setState(() => selectedCategory = cat['name']),
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.only(right: 16),
              width: 85,
              decoration: BoxDecoration(
                color: isSelected ? color : (isDark ? color.withValues(alpha: 0.1) : color.withValues(alpha: 0.08)),
                borderRadius: BorderRadius.circular(24),
                boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: isDark ? 0.3 : 0.5), blurRadius: 12, offset: const Offset(0, 6))] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat['icon'], color: isSelected ? Colors.white : color, size: 28),
                  const SizedBox(height: 8),
                  Text(cat['name'], style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : color)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemberTile(model.User u, bool isSelected, Color textColor, Color primary, bool isDark) {
    return ListTile(
      onTap: () => toggleMember(u.uid),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: AnimatedContainer(
        duration: 200.ms,
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? primary : textColor.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Center(child: Icon(isSelected ? Icons.check_rounded : Icons.add_rounded, size: 20, color: isSelected ? Colors.white : textColor.withValues(alpha: 0.3))),
      ),
      title: Text(u.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: textColor.withValues(alpha: isSelected ? 1 : 0.4))),
      trailing: splitType == "unequally" && isSelected
      ? Container(
          width: 110,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : primary.withValues(alpha: 0.05), 
            borderRadius: BorderRadius.circular(12)
          ),
          child: TextField(
            controller: amountControllers[u.uid],
            keyboardType: TextInputType.number,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
            decoration: InputDecoration(
              border: InputBorder.none, 
              prefixText: "PKR ",
              prefixStyle: TextStyle(color: textColor.withValues(alpha: 0.5))
            ),
          ),
        )
      : Text(isSelected ? "PKR ${amountControllers[u.uid]?.text ?? '0'}" : "Exclude", 
          style: GoogleFonts.outfit(
            fontSize: 13, 
            fontWeight: FontWeight.bold, 
            color: isSelected 
              ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669)) 
              : textColor.withValues(alpha: 0.15)
          )),
    );
  }
}
