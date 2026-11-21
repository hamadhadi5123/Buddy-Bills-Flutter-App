

class Announcement {
  String id;
  String title;
  String message;
  String priority; // 'info', 'important', 'urgent'
  String createdBy; // Admin user ID
  String createdByName; // Admin name
  DateTime createdAt;
  bool isActive;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    this.priority = 'info',
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'priority': priority,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      priority: map['priority'] ?? 'info',
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? 'Admin',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  // Get color based on priority
  static int getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return 0xFFE74C3C; // Red
      case 'important':
        return 0xFFF39C12; // Orange
      default:
        return 0xFF3498DB; // Blue
    }
  }

  // Get icon based on priority
  static int getPriorityIcon(String priority) {
    switch (priority) {
      case 'urgent':
        return 0xe645; // Icons.error
      case 'important':
        return 0xe88e; // Icons.warning
      default:
        return 0xe88f; // Icons.info
    }
  }
}
