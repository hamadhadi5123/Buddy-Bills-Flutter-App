

class SupportRequest {
  String id;
  String userId;
  String userName;
  String userEmail;
  String subject;
  String message;
  String status; // 'pending', 'in_progress', 'resolved'
  String? adminResponse;
  String? respondedBy; // Admin user ID
  DateTime createdAt;
  DateTime? updatedAt;

  SupportRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.subject,
    required this.message,
    this.status = 'pending',
    this.adminResponse,
    this.respondedBy,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'subject': subject,
      'message': message,
      'status': status,
      'adminResponse': adminResponse,
      'respondedBy': respondedBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory SupportRequest.fromMap(Map<String, dynamic> map) {
    return SupportRequest(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      subject: map['subject'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
      adminResponse: map['adminResponse'],
      respondedBy: map['respondedBy'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }

  // Get status color
  static int getStatusColor(String status) {
    switch (status) {
      case 'resolved':
        return 0xFF27AE60; // Green
      case 'in_progress':
        return 0xFFF39C12; // Orange
      default:
        return 0xFFE74C3C; // Red
    }
  }

  // Get status text
  String get statusText {
    switch (status) {
      case 'resolved':
        return 'Resolved';
      case 'in_progress':
        return 'In Progress';
      default:
        return 'Pending';
    }
  }
}
