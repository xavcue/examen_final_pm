class MessageModel {
  final String id;
  final String senderUid;
  final String senderRole;
  final String content;
  final int timestamp;

  MessageModel({
    required this.id,
    required this.senderUid,
    required this.senderRole,
    required this.content,
    required this.timestamp,
  });

  factory MessageModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return MessageModel(
      id: id,
      senderUid: (map['senderUid'] ?? '').toString(),
      senderRole: (map['senderRole'] ?? 'USER').toString(),
      content: (map['content'] ?? '').toString(),
      timestamp: (map['timestamp'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderUid': senderUid,
      'senderRole': senderRole,
      'content': content,
      'timestamp': timestamp,
    };
  }
}
