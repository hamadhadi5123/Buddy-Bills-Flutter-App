// Removed unused cloud_firestore import

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final String type; // text, image

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.type = 'text',
    this.readBy = const [],
  });

  final List<String> readBy;

  bool isReadBy(String userId) => readBy.contains(userId);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type,
      'readBy': readBy,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, [String? id]) {
    return ChatMessage(
      id: id ?? map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      type: map['type'] ?? 'text',
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }
}
