
class Payment {
  final String? id;
  final String from; // UID of payer
  final String to;   // UID of receiver
  final List<String> involvedUsers; // UIDs of both from and to
  final double amount;
  final String? groupId;
  final DateTime timestamp;
  final String status; // 'pending', 'approved', 'rejected'
  final String? requestedBy;

  Payment({
    this.id,
    required this.from,
    required this.to,
    required this.involvedUsers,
    required this.amount,
    this.groupId,
    required this.timestamp,
    this.status = 'approved',
    this.requestedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'from': from,
      'to': to,
      'involvedUsers': involvedUsers,
      'amount': amount,
      'groupId': groupId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
      if (requestedBy != null) 'requestedBy': requestedBy,
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
      status: map['status'] ?? 'approved',
      requestedBy: map['requestedBy'],
    );
  }

  Payment copyWith({
    String? id,
    String? from,
    String? to,
    List<String>? involvedUsers,
    double? amount,
    String? groupId,
    DateTime? timestamp,
    String? status,
    String? requestedBy,
  }) {
    return Payment(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      involvedUsers: involvedUsers ?? this.involvedUsers,
      amount: amount ?? this.amount,
      groupId: groupId ?? this.groupId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      requestedBy: requestedBy ?? this.requestedBy,
    );
  }
}
