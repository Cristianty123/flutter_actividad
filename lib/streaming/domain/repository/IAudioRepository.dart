import 'dart:typed_data';

abstract class IAudioRepository {
  Stream<Uint8List> get incomingAudioStream; // bytes que recibes
  Future<void> startStreaming(String targetIp, int port); // para empezar a grabar y enviar
  Future<void> stopStreaming();
  Future<void> startListening(int port);     // abrir el socket UDP para recibir
  Future<void> stopListening();
  Future<void> setMicrophoneEnabled(bool enabled); // push-to-talk o mute
}