class Group {
  final String? id;
  final String name;
  final String type;
  final List<String> members; // UIDs of members
  final String createdBy; // UID of the creator
  final Map<String, String> memberAddedBy; // Member UID -> Adder UID
  final DateTime createdAt;

  Group({
    this.id,
    required this.name,
    required this.type,
    required this.members,
    required this.createdBy,
    required this.memberAddedBy,
    required this.createdAt,
  });

  Group copyWith({
    String? id,
    String? name,
    String? type,
    List<String>? members,
    String? createdBy,
    Map<String, String>? memberAddedBy,
    DateTime? createdAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      members: members ?? List.from(this.members),
      createdBy: createdBy ?? this.createdBy,
      memberAddedBy: memberAddedBy ?? Map.from(this.memberAddedBy),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'members': members,
      'createdBy': createdBy,
      'memberAddedBy': memberAddedBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map, String id) {
    return Group(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      createdBy: map['createdBy'] ?? '',
      memberAddedBy: Map<String, String>.from(map['memberAddedBy'] ?? {}),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }
}
