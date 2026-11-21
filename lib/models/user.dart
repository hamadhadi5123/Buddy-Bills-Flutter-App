

class User {
  String uid;
  String name;
  String email;
  bool isAdmin;
  bool isActive;
  String? phoneNumber;
  String? profilePictureUrl;
  String role; // "user" or "admin"
  int totalExpenses;
  int groupsJoined;
  DateTime createdAt;
  DateTime? lastLoginAt;
  bool isOnline;
  DateTime? lastSeen;

  User({
    required this.uid,
    required this.name,
    required this.email,
    this.isAdmin = false,
    this.isActive = true,
    this.phoneNumber,
    this.profilePictureUrl,
    this.role = 'user',
    this.totalExpenses = 0,
    this.groupsJoined = 0,
    required this.createdAt,
    this.lastLoginAt,
    this.isOnline = false,
    this.lastSeen,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'isAdmin': isAdmin,
      'isActive': isActive,
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
      'role': role,
      'totalExpenses': totalExpenses,
      'groupsJoined': groupsJoined,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
    };
  }

  factory User.fromMap(Map<String, dynamic> map, [String? id]) {
    return User(
      uid: id ?? map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      isActive: map['isActive'] ?? true,
      phoneNumber: map['phoneNumber'],
      profilePictureUrl: map['profilePictureUrl'],
      role: map['role'] ?? (map['isAdmin'] == true ? 'admin' : 'user'),
      totalExpenses: map['totalExpenses'] ?? 0,
      groupsJoined: map['groupsJoined'] ?? 0,
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) 
          : DateTime.now(),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLoginAt'])
          : null,
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen']) 
          : null,
    );
  }

  // Helper method to get user status
  String get statusText => isActive ? 'Active' : 'Inactive';
  
  // Helper method to get role text
  String get roleText => role == 'admin' ? 'Admin' : 'User';
  
  // Helper method to update last login
  User updateLastLogin() {
    return User(
      uid: uid,
      name: name,
      email: email,
      isAdmin: isAdmin,
      isActive: isActive,
      phoneNumber: phoneNumber,
      profilePictureUrl: profilePictureUrl,
      role: role,
      totalExpenses: totalExpenses,
      groupsJoined: groupsJoined,
      createdAt: createdAt,
      lastLoginAt: DateTime.now(),
    );
  }
}
