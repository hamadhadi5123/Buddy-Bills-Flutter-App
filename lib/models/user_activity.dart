

import 'package:flutter/material.dart';

class UserActivity {
  String id;
  String userId;
  String userName;
  String action; // 'login', 'expense_created', 'group_created', 'group_joined', 'profile_updated'
  String details;
  Map<String, dynamic>? metadata;
  DateTime timestamp;

  UserActivity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.details,
    this.metadata,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'action': action,
      'details': details,
      'metadata': metadata,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory UserActivity.fromMap(Map<String, dynamic> map) {
    DateTime parseTimestamp(dynamic ts) {
      if (ts == null) return DateTime.now();
      if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
      try {
        if (ts.runtimeType.toString() == 'Timestamp' || ts.toString().contains('Timestamp')) {
          return (ts as dynamic).toDate();
        }
      } catch (_) {}
      if (ts is DateTime) return ts;
      return DateTime.now();
    }

    return UserActivity(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      action: map['action'] ?? '',
      details: map['details'] ?? '',
      metadata: map['metadata'],
      timestamp: parseTimestamp(map['timestamp']),
    );
  }

  // Get icon for activity type
  static IconData getActivityIconData(String action) {
    switch (action) {
      case 'login':
        return Icons.login_rounded;
      case 'expense_created':
        return Icons.attach_money_rounded;
      case 'group_created':
        return Icons.group_add_rounded;
      case 'group_joined':
        return Icons.groups_rounded;
      case 'profile_updated':
        return Icons.person_rounded;
      default:
        return Icons.local_activity_rounded;
    }
  }

  static int getActivityIcon(String action) {
    switch (action) {
      case 'login':
        return 0xe3a7; // Icons.login
      case 'expense_created':
        return 0xe25a; // Icons.attach_money
      case 'group_created':
        return 0xe7ef; // Icons.group_add
      case 'group_joined':
        return 0xe7ee; // Icons.group
      case 'profile_updated':
        return 0xe3c9; // Icons.person
      default:
        return 0xe86f; // Icons.activity
    }
  }
}
