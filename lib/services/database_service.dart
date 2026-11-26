import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../models/expense.dart';
import '../models/payment.dart';
import '../models/chat_message.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DatabaseService();

  // ================= USER OPERATIONS =================
  Stream<User?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return User.fromMap(doc.data()!, doc.id);
      }
      return null;
    }).handleError((error) {
      debugPrint('Error streaming user: $error');
      return null;
    });
  }

  Future<void> saveUser(User user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving user: $e');
      rethrow;
    }
  }

  Future<void> updateUserPresence(String uid, bool isOnline) async {
    try {
      await _db.collection('users').doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Error updating user presence: $e');
    }
  }

  Future<User?> findUserByEmail(String email) async {
    try {
      final query = await _db.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (query.docs.isNotEmpty) {
        return User.fromMap(query.docs.first.data(), query.docs.first.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error finding user by email: $e');
      return null;
    }
  }

  Stream<List<User>> streamUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => User.fromMap(doc.data(), doc.id)).toList();
    }).handleError((error) {
      debugPrint('Error streaming users: $error');
      return <User>[];
    });
  }

  // ================= GROUP OPERATIONS =================
  Stream<List<Group>> streamGroups(String userUid) {
    return _db
        .collection('groups')
        .where('members', arrayContains: userUid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Group.fromMap(doc.data(), doc.id)).toList();
    }).handleError((error) {
      debugPrint('Error streaming groups: $error');
      return <Group>[];
    });
  }

  Future<String> createGroup(Group group) async {
    try {
      final docRef = await _db.collection('groups').add(group.toMap());
      
      // Increment group counts for all members
      for (String uid in group.members) {
        await _db.collection('users').doc(uid).update({
          'groupsJoined': FieldValue.increment(1),
        });
      }
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating group: $e');
      rethrow;
    }
  }

  Future<void> updateGroup(Group group) async {
    if (group.id == null) return;
    try {
      await _db.collection('groups').doc(group.id).update(group.toMap());
    } catch (e) {
      debugPrint('Error updating group: $e');
      rethrow;
    }
  }

  Stream<Group?> streamGroup(String id) {
    return _db.collection('groups').doc(id).snapshots().map((doc) {
      if (doc.exists) return Group.fromMap(doc.data()!, doc.id);
      return null;
    }).handleError((error) {
      debugPrint('Error streaming group: $error');
      return null;
    });
  }


  // ================= EXPENSE OPERATIONS =================
  Stream<List<Expense>> streamExpenses({String? groupId, String? userUid}) {
    Query query = _db.collection('expenses');

    if (groupId != null) {
      query = query.where('groupId', isEqualTo: groupId);
    } else if (userUid != null) {
      query = query.where('allParticipants', arrayContains: userUid);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }).handleError((error) {
      debugPrint('Error streaming expenses: $error');
      return <Expense>[];
    });
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _db.collection('expenses').add(expense.toMap());
      
      // Increment total expenses for the person who paid
      await _db.collection('users').doc(expense.paidBy).update({
        'totalExpenses': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error adding expense: $e');
      rethrow;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      final doc = await _db.collection('expenses').doc(expenseId).get();
      if (doc.exists) {
        final paidBy = doc.data()?['paidBy'];
        await _db.collection('expenses').doc(expenseId).delete();
        
        // Decrement total expenses
        if (paidBy != null) {
          await _db.collection('users').doc(paidBy).update({
            'totalExpenses': FieldValue.increment(-1),
          });
        }
      }
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      rethrow;
    }
  }

  Future<void> incrementUserGroupsJoined(String uid) async {
    await _db.collection('users').doc(uid).update({
      'groupsJoined': FieldValue.increment(1),
    });
  }

  Future<void> decrementUserGroupsJoined(String uid) async {
    await _db.collection('users').doc(uid).update({
      'groupsJoined': FieldValue.increment(-1),
    });
  }

  Stream<List<Expense>> streamGroupExpenses(String groupId) {
    return _db
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Expense.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }).handleError((error) {
      debugPrint('Error streaming group expenses: $error');
      return <Expense>[];
    });
  }

  // ================= PAYMENT OPERATIONS =================
  Future<void> addPayment(Payment payment) async {
    try {
      // Ensure involvedUsers is populated if it's empty
      final updatedPayment = payment.involvedUsers.isEmpty 
        ? Payment(
            id: payment.id,
            from: payment.from,
            to: payment.to,
            involvedUsers: [payment.from, payment.to],
            amount: payment.amount,
            groupId: payment.groupId,
            timestamp: payment.timestamp,
          )
        : payment;
      await _db.collection('payments').add(updatedPayment.toMap());
    } catch (e) {
      debugPrint('Error adding payment: $e');
      rethrow;
    }
  }

  Future<void> updatePaymentStatus(String paymentId, String status) async {
    try {
      await _db.collection('payments').doc(paymentId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      rethrow;
    }
  }

  Future<void> deletePayment(String paymentId) async {
    try {
      await _db.collection('payments').doc(paymentId).delete();
    } catch (e) {
      debugPrint('Error deleting payment: $e');
      rethrow;
    }
  }

  Stream<List<Payment>> streamPayments({String? groupId, String? userUid}) {
    Query query = _db.collection('payments');

    if (groupId != null) {
      query = query.where('groupId', isEqualTo: groupId);
    } else if (userUid != null) {
      query = query.where('involvedUsers', arrayContains: userUid);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => Payment.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }).handleError((error) {
      debugPrint('Error streaming payments: $error');
      return <Payment>[];
    });
  }

  Stream<List<Payment>> streamGroupPayments(String groupId) {
    return _db
        .collection('payments')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Payment.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }).handleError((error) {
      debugPrint('Error streaming group payments: $error');
      return <Payment>[];
    });
  }

  // ================= CHAT OPERATIONS =================
  Future<void> sendMessage(String groupId, ChatMessage message) async {
    try {
      final docRef = _db
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc();
      final readByList = message.readBy.contains(message.senderId)
          ? message.readBy
          : [...message.readBy, message.senderId];
      final msgWithId = ChatMessage(
        id: docRef.id,
        senderId: message.senderId,
        senderName: message.senderName,
        content: message.content,
        timestamp: message.timestamp,
        type: message.type,
        readBy: readByList,
      );
      await docRef.set(msgWithId.toMap());

      // Update group with last message for quick reference
      await _db.collection('groups').doc(groupId).set({
        'lastMessage': message.content,
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
        'lastSenderId': message.senderId,
        'lastSenderName': message.senderName,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> markMessageAsRead(String groupId, String messageId, String userId) async {
    if (messageId.isEmpty) return;
    try {
      await _db
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  Stream<int> streamGroupUnreadCount(String groupId, String userId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        final senderId = data['senderId'] ?? '';
        final readBy = List<String>.from(data['readBy'] ?? []);
        return senderId != userId && !readBy.contains(userId);
      }).length;
    }).handleError((error) {
      debugPrint('Error streaming group unread: $error');
      return 0;
    });
  }

  Stream<List<ChatMessage>> streamChatMessages(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }).handleError((error) {
      debugPrint('Error streaming chat messages: $error');
      return <ChatMessage>[];
    });
  }

  // ================= PRIVATE CHAT OPERATIONS =================
  String getConversationId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort(); // Consistent ID regardless of who starts
    return ids.join('_');
  }

  Future<void> sendPrivateMessage(
      String recipientId, String currentUserId, ChatMessage message) async {
    try {
      final convId = getConversationId(currentUserId, recipientId);
      final docRef = _db
          .collection('private_chats')
          .doc(convId)
          .collection('messages')
          .doc();

      final readByList = message.readBy.contains(currentUserId)
          ? message.readBy
          : [...message.readBy, currentUserId];

      final msgWithId = ChatMessage(
        id: docRef.id,
        senderId: message.senderId,
        senderName: message.senderName,
        content: message.content,
        timestamp: message.timestamp,
        type: message.type,
        readBy: readByList,
      );

      // 1. Add message with ID to the subcollection
      await docRef.set(msgWithId.toMap());

      // 2. Update conversation summary/metadata with unread counter
      await _db.collection('conversations').doc(convId).set({
        'participants': [currentUserId, recipientId],
        'lastMessage': message.content,
        'lastTimestamp': message.timestamp.millisecondsSinceEpoch,
        'lastSenderId': currentUserId,
        'conversationId': convId,
        'unread_$recipientId': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error sending private message: $e');
      rethrow;
    }
  }

  Stream<List<ChatMessage>> streamPrivateMessages(String convId) {
    return _db
        .collection('private_chats')
        .doc(convId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }).handleError((error) {
      debugPrint('Error streaming private messages: $error');
      return <ChatMessage>[];
    });
  }

  Future<void> markPrivateMessageAsRead(String convId, String messageId, String userId) async {
    if (messageId.isEmpty) return;
    try {
      await _db
          .collection('private_chats')
          .doc(convId)
          .collection('messages')
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error marking private message as read: $e');
    }
  }

  Future<void> markConversationAsRead(String convId, String userId) async {
    try {
      await _db.collection('conversations').doc(convId).set({
        'unread_$userId': 0,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error clearing conversation unread count: $e');
    }
  }

  Stream<int> streamTotalUnreadMessages(String userId) {
    return _db
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unread = (data['unread_$userId'] as num?)?.toInt() ?? 0;
        count += unread;
      }
      return count;
    }).handleError((error) {
      debugPrint('Error streaming total unread: $error');
      return 0;
    });
  }

  Stream<int> streamConversationUnread(String convId, String userId) {
    return _db
        .collection('conversations')
        .doc(convId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return 0;
      final data = doc.data() as Map<String, dynamic>;
      return (data['unread_$userId'] as num?)?.toInt() ?? 0;
    }).handleError((error) {
      debugPrint('Error streaming conv unread: $error');
      return 0;
    });
  }

  Stream<List<Map<String, dynamic>>> streamRecentConversations(String userUid) {
    return _db
        .collection('conversations')
        .where('participants', arrayContains: userUid)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.map((doc) => doc.data()).toList();
      // Sort client-side to avoid needing a composite index
      docs.sort((a, b) => (b['lastTimestamp'] ?? 0).compareTo(a['lastTimestamp'] ?? 0));
      return docs;
    }).handleError((error) {
      debugPrint('Error streaming recent conversations: $error');
      return <Map<String, dynamic>>[];
    });
  }

  // ================= TYPING STATUS =================
  Future<void> updateTypingStatus(String convId, String userId, bool isTyping) async {
    try {
      await _db.collection('conversations').doc(convId).update({
        'typingStatus.$userId': isTyping,
      });
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }

  Stream<bool> streamTypingStatus(String convId, String otherUserId) {
    return _db.collection('conversations').doc(convId).snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final typingStatus = data['typingStatus'] as Map<String, dynamic>?;
        return typingStatus?[otherUserId] ?? false;
      }
      return false;
    });
  }
}
