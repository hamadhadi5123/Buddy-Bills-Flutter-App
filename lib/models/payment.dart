
class Payment {
  final String? id;
  final String from; // UID of payer
  final String to;   // UID of receiver
  final List<String> involvedUsers; // UIDs of both from and to
  final double amount;
  final String? groupId;
  final DateTime timestamp;

  Payment({
    this.id,
    required this.from,
    required this.to,
    required this.involvedUsers,
    required this.amount,
    this.groupId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'from': from,
      'to': to,
      'involvedUsers': involvedUsers,
      'amount': amount,
      'groupId': groupId,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map, String id) {
    return Payment(
      id: id,
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      involvedUsers: List<String>.from(map['involvedUsers'] ?? []),
      amount: (map['amount'] ?? 0).toDouble(),
      groupId: map['groupId'],
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
    );
  }
}
