enum MessageType { text, audio, system }

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final MessageType type;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
  });

  // para enviar por Sockets TCP
  Map<String, dynamic> toMap() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'type': type.index,
  };

  // para recibir de Sockets TCP

  factory Message.fromMap(Map<String, dynamic> map) => Message(
    id: map['id'],
    senderId: map['senderId'],
    senderName: map['senderName'],
    content: map['content'],
    timestamp: DateTime.parse(map['timestamp']),
    type: MessageType.values[map['type']],
  );
}