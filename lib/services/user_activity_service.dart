import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_activity.dart';

class UserActivityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _activitiesCollection = _firestore.collection('user_activities');

  // Log user activity
  static Future<void> logActivity({
    required String userId,
    required String userName,
    required String action,
    required String details,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final activityId = _activitiesCollection.doc().id;
      final activity = UserActivity(
        id: activityId,
        userId: userId,
        userName: userName,
        action: action,
        details: details,
        metadata: metadata,
        timestamp: DateTime.now(),
      );

      await _activitiesCollection.doc(activityId).set(activity.toMap());
    } catch (e) {
      // print('Error logging activity: $e');
    }
  }

  // Get all activities (for admin)
  static Stream<List<UserActivity>> getAllActivities({int limit = 100}) {
    return _activitiesCollection
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['id'] == null || (data['id'] as String).isEmpty) {
              data['id'] = doc.id;
            }
            return UserActivity.fromMap(data);
          })
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list.take(limit).toList();
    });
  }

  // Delete single activity log (Admin only)
  static Future<bool> deleteActivity(String activityId) async {
    try {
      await _activitiesCollection.doc(activityId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting activity $activityId: $e');
      return false;
    }
  }

  // Clear all activity logs (Admin only)
  static Future<bool> clearAllActivities() async {
    try {
      final snapshot = await _activitiesCollection.get();
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error clearing activities: $e');
      return false;
    }
  }

  // Get activities for specific user
  static Stream<List<UserActivity>> getUserActivities(String userId, {int limit = 20}) {
    return _activitiesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => UserActivity.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list.take(limit).toList();
    });
  }

  // Get recent activities (last 24 hours)
  static Stream<List<UserActivity>> getRecentActivities() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));
    return _activitiesCollection
        .where('timestamp', isGreaterThan: yesterday.millisecondsSinceEpoch)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => UserActivity.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  // Get activity count by action type
  static Future<Map<String, int>> getActivityStats() async {
    try {
      final snapshot = await _activitiesCollection.get();
      final Map<String, int> stats = {};
      
      for (var doc in snapshot.docs) {
        final activity = UserActivity.fromMap(doc.data() as Map<String, dynamic>);
        stats[activity.action] = (stats[activity.action] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      debugPrint('Error getting activity stats: $e');
      return {};
    }
  }

  // Log user login
  static Future<void> logLogin(String userId, String userName) async {
    await logActivity(
      userId: userId,
      userName: userName,
      action: 'login',
      details: 'Logged in',
    );
  }

  // Log expense creation
  static Future<void> logExpenseCreated(
    String userId,
    String userName,
    String expenseDescription,
    double amount,
  ) async {
    await logActivity(
      userId: userId,
      userName: userName,
      action: 'expense_created',
      details: 'Created expense "$expenseDescription"',
      metadata: {'amount': amount, 'description': expenseDescription},
    );
  }

  // Log group creation
  static Future<void> logGroupCreated(
    String userId,
    String userName,
    String groupName,
  ) async {
    await logActivity(
      userId: userId,
      userName: userName,
      action: 'group_created',
      details: 'Created group "$groupName"',
      metadata: {'groupName': groupName},
    );
  }

  // Log group join
  static Future<void> logGroupJoined(
    String userId,
    String userName,
    String groupName,
  ) async {
    await logActivity(
      userId: userId,
      userName: userName,
      action: 'group_joined',
      details: 'Joined group "$groupName"',
      metadata: {'groupName': groupName},
    );
  }

  // Log profile update
  static Future<void> logProfileUpdated(String userId, String userName) async {
    await logActivity(
      userId: userId,
      userName: userName,
      action: 'profile_updated',
      details: 'Updated profile information',
    );
  }

  // Log payment creation (settlement)
  static Future<void> logPaymentCreated(
    String userId,
    String userName,
    double amount,
    String from,
    String to,
  ) async {
    await logActivity(
      userId: userId,
      userName: userName,
      action: 'payment_created',
      details: 'Recorded settlement of PKR $amount',
      metadata: {'amount': amount, 'from': from, 'to': to},
    );
  }
}
