

class Expense {
  final String? id;
  final String description;
  final String paidBy; // UID of payer (if single payer)
  final Map<String, double>? multiplePayers; // UID to amount (if multiple payers)
  final double amount;
  final List<String> involvedMembers; // UIDs
  final List<String> allParticipants; // Unique UIDs of everyone involved (payers + splitters)
  final String splitType;
  final Map<String, double>? unequalAmounts;
  final String? groupId;
  final String category;
  final DateTime timestamp;

  Expense({
    this.id,
    required this.description,
    required this.paidBy,
    this.multiplePayers,
    required this.amount,
    required this.involvedMembers,
    this.allParticipants = const [],
    this.splitType = 'equally',
    this.unequalAmounts,
    this.groupId,
    this.category = 'Other',
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'paidBy': paidBy,
      'multiplePayers': multiplePayers,
      'amount': amount,
      'involvedMembers': involvedMembers,
      'allParticipants': allParticipants,
      'splitType': splitType,
      'unequalAmounts': unequalAmounts,
      'groupId': groupId,
      'category': category,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map, String id) {
    return Expense(
      id: id,
      description: map['description'] ?? '',
      paidBy: map['paidBy'] ?? '',
      multiplePayers: map['multiplePayers'] != null
          ? Map<String, double>.from(map['multiplePayers'].map((k, v) => MapEntry(k, v.toDouble())))
          : null,
      amount: (map['amount'] ?? 0).toDouble(),
      involvedMembers: List<String>.from(map['involvedMembers'] ?? []),
      allParticipants: List<String>.from(map['allParticipants'] ?? []),
      splitType: map['splitType'] ?? 'equally',
      unequalAmounts: map['unequalAmounts'] != null 
          ? Map<String, double>.from(map['unequalAmounts'].map((k, v) => MapEntry(k, v.toDouble())))
          : null,
      groupId: map['groupId'],
      category: map['category'] ?? 'Other',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
    );
  }
  Expense copyWith({
    String? id,
    String? description,
    String? paidBy,
    Map<String, double>? multiplePayers,
    double? amount,
    List<String>? involvedMembers,
    List<String>? allParticipants,
    String? splitType,
    Map<String, double>? unequalAmounts,
    String? groupId,
    String? category,
    DateTime? timestamp,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      paidBy: paidBy ?? this.paidBy,
      multiplePayers: multiplePayers ?? this.multiplePayers,
      amount: amount ?? this.amount,
    involvedMembers: involvedMembers ?? this.involvedMembers,
    allParticipants: allParticipants ?? this.allParticipants,
    splitType: splitType ?? this.splitType,
      unequalAmounts: unequalAmounts ?? this.unequalAmounts,
      groupId: groupId ?? this.groupId,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
