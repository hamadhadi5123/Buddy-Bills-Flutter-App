
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

    // 1. Process expenses
    for (var exp in expenses) {
      // 1. Handle WHO PAID (The Credit)
      if (exp.multiplePayers != null && exp.multiplePayers!.isNotEmpty) {
        for (var entry in exp.multiplePayers!.entries) {
          balances[entry.key] = (balances[entry.key] ?? 0.0) + entry.value;
        }
      } else {
        balances[exp.paidBy] = (balances[exp.paidBy] ?? 0.0) + exp.amount;
      }

      // 2. Handle WHO OWES (The Debt / Share)
      if (exp.splitType == 'equally') {
        final count = exp.involvedMembers.isEmpty ? 1 : exp.involvedMembers.length;
        final share = exp.amount / count;
        for (var m in exp.involvedMembers) {
          balances[m] = (balances[m] ?? 0.0) - share;
        }
      } else if (exp.splitType == 'unequally' && exp.unequalAmounts != null) {
        for (var entry in exp.unequalAmounts!.entries) {
          balances[entry.key] = (balances[entry.key] ?? 0.0) - entry.value;
        }
      }
    }

    // 2. Process payments (settlements)
    // When 'from' pays 'to':
    // 'from' gave money, so their debt decreases / balance increases (+amount)
    // 'to' received money, so their credit decreases / balance decreases (-amount)
    // Only approved payments are processed; pending requests do not settle debt until accepted
    for (var pay in payments) {
      if (pay.status == 'approved' || pay.status.isEmpty) {
        balances[pay.from] = (balances[pay.from] ?? 0.0) + pay.amount;
        balances[pay.to] = (balances[pay.to] ?? 0.0) - pay.amount;
      }
    }

    // 3. Separate members into Debtors and Creditors
    // Positive balance (> 0.01) = Creditor (is owed money, should receive)
    // Negative balance (< -0.01) = Debtor (owes money, should give)
    List<MapEntry<String, double>> debtors = [];
    List<MapEntry<String, double>> creditors = [];

    balances.forEach((uid, balance) {
      // Round to 2 decimals to prevent floating point inaccuracies
      final rounded = double.parse(balance.toStringAsFixed(2));
      if (rounded < -0.01) {
        debtors.add(MapEntry(uid, -rounded)); // Positive amount owed
      } else if (rounded > 0.01) {
        creditors.add(MapEntry(uid, rounded)); // Positive amount to receive
      }
    });

    // 4. Greedy Debt Minimization (Standard Splitwise Algorithm)
    // Sort descending by amount to minimize total number of transactions
    debtors.sort((a, b) => b.value.compareTo(a.value));
    creditors.sort((a, b) => b.value.compareTo(a.value));

    int dIdx = 0;
    int cIdx = 0;
    List<Debt> debts = [];

    while (dIdx < debtors.length && cIdx < creditors.length) {
      final debtor = debtors[dIdx];
      final creditor = creditors[cIdx];

      final double settleAmount = debtor.value < creditor.value ? debtor.value : creditor.value;

      if (settleAmount > 0.01) {
        debts.add(Debt(from: debtor.key, to: creditor.key, amount: settleAmount));
      }

      debtors[dIdx] = MapEntry(debtor.key, debtor.value - settleAmount);
      creditors[cIdx] = MapEntry(creditor.key, creditor.value - settleAmount);

      if (debtors[dIdx].value <= 0.01) {
        dIdx++;
      }
      if (creditors[cIdx].value <= 0.01) {
        cIdx++;
      }
    }

    return debts;
  }
}
