/// 教务系统账号模型
class Account {
  final int? id;
  final String username;
  final String password;
  final String? nickname;
  final int? scheduleId;
  final DateTime createdAt;
  final DateTime? lastSyncAt;

  Account({
    this.id,
    required this.username,
    required this.password,
    this.nickname,
    this.scheduleId,
    DateTime? createdAt,
    this.lastSyncAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      nickname: map['nickname'],
      scheduleId: map['scheduleId'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      lastSyncAt: map['lastSyncAt'] != null
          ? DateTime.parse(map['lastSyncAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'nickname': nickname,
      'scheduleId': scheduleId,
      'createdAt': createdAt.toIso8601String(),
      'lastSyncAt': lastSyncAt?.toIso8601String(),
    };
  }

  Account copyWith({
    int? id,
    String? username,
    String? password,
    String? nickname,
    int? scheduleId,
    DateTime? createdAt,
    DateTime? lastSyncAt,
  }) {
    return Account(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      nickname: nickname ?? this.nickname,
      scheduleId: scheduleId ?? this.scheduleId,
      createdAt: createdAt ?? this.createdAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  String get displayName => nickname ?? username;
}
