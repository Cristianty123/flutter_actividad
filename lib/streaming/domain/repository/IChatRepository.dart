import 'package:flutter_actividad/streaming/domain/model/Message.dart';

abstract class IChatRepository {
  Stream<Message> get messageStream;
  Future<void> sendMessage(Message message);
  Future<void> startServer();
  Future<void> connectToServer(String ipAddress);
  Future<void> disconnect();
}