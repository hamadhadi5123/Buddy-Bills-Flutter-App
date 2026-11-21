
import '../models/expense.dart';
import '../models/payment.dart';

class Debt {
  final String from;
  final String to;
  final double amount;

  Debt({required this.from, required this.to, required this.amount});
}

class DebtCalculator {
  static List<Debt> calculateDebts(List<Expense> expenses, List<Payment> payments, List<String> members) {
    Map<String, double> balances = {for (var m in members) m: 0.0};

    // process expenses
    for (var exp in expenses) {
      // 1. Handle WHO PAID (The Credit)
      if (exp.multiplePayers != null && exp.multiplePayers!.isNotEmpty) {
        // Multiple people paid
        for (var entry in exp.multiplePayers!.entries) {
          balances[entry.key] = (balances[entry.key] ?? 0) + entry.value;
        }
      } else {
        // Fallback to single payer
        balances[exp.paidBy] = (balances[exp.paidBy] ?? 0) + exp.amount;
      }

      // 2. Handle WHO OWES (The Debt)
      if (exp.splitType == 'equally') {
        final share = exp.amount / (exp.involvedMembers.isEmpty ? 1 : exp.involvedMembers.length);
        for (var m in exp.involvedMembers) {
          balances[m] = (balances[m] ?? 0) - share;
        }
      } else if (exp.splitType == 'unequally' && exp.unequalAmounts != null) {
        for (var entry in exp.unequalAmounts!.entries) {
          balances[entry.key] = (balances[entry.key] ?? 0) - entry.value;
        }
      }
    }

    // Process payments (settlements)
    for (var pay in payments) {
      balances[pay.from] = (balances[pay.from] ?? 0) + pay.amount;
      balances[pay.to] = (balances[pay.to] ?? 0) - pay.amount;
    }

    // Separate into Creditors and Debtors
    // Identify the "Hub" - the member with the largest positive balance (Primary Payer)
    String? hub;
    double maxBalance = -1.0;

    balances.forEach((uid, balance) {
      if (balance > maxBalance) {
        maxBalance = balance;
        hub = uid;
      }
    });

    if (hub == null || maxBalance <= 0.01) return [];

    List<Debt> debts = [];

    // All debtors pay the Hub directly
    balances.forEach((uid, balance) {
      if (uid == hub) return;
      
      if (balance < -0.01) {
        // Debtor owes the Hub
        debts.add(Debt(from: uid, to: hub!, amount: -balance));
      } else if (balance > 0.01) {
        // Hub owes other minor creditors
        debts.add(Debt(from: hub!, to: uid, amount: balance));
      }
    });

    return debts;
  }
}
