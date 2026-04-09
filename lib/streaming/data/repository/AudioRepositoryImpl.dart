import 'dart:typed_data';

import '../../domain/repository/IAudioRepository.dart';
import '../../infrastructure/audio/AudioService.dart';

class AudioRepositoryImpl implements IAudioRepository {
  final AudioService _service;

  AudioRepositoryImpl(this._service);

  @override
  Stream<Uint8List> get incomingAudioStream => _service.incomingAudioStream;

  @override
  Future<void> startStreaming(String targetIp, int port) =>
      _service.startStreaming(targetIp, port);

  @override
  Future<void> stopStreaming() => _service.stopStreaming();

  @override
  Future<void> startListening(int port) => _service.startListening(port);

  @override
  Future<void> stopListening() => _service.stopListening();

  @override
  Future<void> setMicrophoneEnabled(bool enabled) =>
      _service.setMicrophoneEnabled(enabled);
}