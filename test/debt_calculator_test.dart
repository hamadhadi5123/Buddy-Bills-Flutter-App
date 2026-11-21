import 'package:flutter_test/flutter_test.dart';
import 'package:buddy_bills/models/expense.dart';
import 'package:buddy_bills/models/payment.dart';
import 'package:buddy_bills/utils/debt_calculator.dart';

void main() {
  group('DebtCalculator Tests', () {
    test('Calculates equal split debts correctly with 3 members', () {
      final List<Expense> expenses = [
        Expense(
          id: 'exp1',
          description: 'Dinner',
          amount: 3000.0,
          paidBy: 'user1',
          involvedMembers: ['user1', 'user2', 'user3'],
          splitType: 'equally',
          timestamp: DateTime.now(),
        ),
      ];

      final debts = DebtCalculator.calculateDebts(
        expenses,
        [],
        ['user1', 'user2', 'user3'],
      );

      expect(debts.length, 2);
      final debt2 = debts.firstWhere((d) => d.from == 'user2');
      expect(debt2.to, 'user1');
      expect(debt2.amount, closeTo(1000.0, 0.01));

      final debt3 = debts.firstWhere((d) => d.from == 'user3');
      expect(debt3.to, 'user1');
      expect(debt3.amount, closeTo(1000.0, 0.01));
    });

    test('Calculates unequal split correctly', () {
      final List<Expense> expenses = [
        Expense(
          id: 'exp2',
          description: 'Shopping',
          amount: 3000.0,
          paidBy: 'user1',
          involvedMembers: ['user1', 'user2', 'user3'],
          splitType: 'unequally',
          unequalAmounts: {
            'user1': 1500.0,
            'user2': 1000.0,
            'user3': 500.0,
          },
          timestamp: DateTime.now(),
        ),
      ];

      final debts = DebtCalculator.calculateDebts(
        expenses,
        [],
        ['user1', 'user2', 'user3'],
      );

      final debt2 = debts.firstWhere((d) => d.from == 'user2');
      expect(debt2.to, 'user1');
      expect(debt2.amount, closeTo(1000.0, 0.01));

      final debt3 = debts.firstWhere((d) => d.from == 'user3');
      expect(debt3.to, 'user1');
      expect(debt3.amount, closeTo(500.0, 0.01));
    });

    test('Factors in settlement payments', () {
      final List<Expense> expenses = [
        Expense(
          id: 'exp3',
          description: 'Lunch',
          amount: 2000.0,
          paidBy: 'user1',
          involvedMembers: ['user1', 'user2'],
          splitType: 'equally',
          timestamp: DateTime.now(),
        ),
      ];

      final List<Payment> payments = [
        Payment(
          id: 'pay1',
          from: 'user2',
          to: 'user1',
          involvedUsers: ['user1', 'user2'],
          amount: 400.0,
          timestamp: DateTime.now(),
        ),
      ];

      final debts = DebtCalculator.calculateDebts(
        expenses,
        payments,
        ['user1', 'user2'],
      );

      expect(debts.length, 1);
      expect(debts.first.from, 'user2');
      expect(debts.first.to, 'user1');
      expect(debts.first.amount, closeTo(600.0, 0.01));
    });
  });
}
