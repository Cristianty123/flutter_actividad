import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import '../../domain/exceptions/NetworkException.dart';

class AudioService {
  final _recorder = FlutterSoundRecorder();
  final _player = FlutterSoundPlayer();
  final _audioController = StreamController<Uint8List>.broadcast();

  RawDatagramSocket? _sendSocket;
  RawDatagramSocket? _receiveSocket;

  bool _isPlayerStreaming = false;

  Stream<Uint8List> get incomingAudioStream => _audioController.stream;

  Future<void> initialize() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  Future<void> startStreaming(String targetIp, int targetPort) async {
    try {
      // Crear socket de envío si no existe (puerto efímero)
      _sendSocket ??= await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    } catch (e) {
      throw MessageSendException("No se pudo abrir el canal de salida de audio.");
    }

    await _recorder.startRecorder(
      toStream: _audioController,
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
    );

    _audioController.stream.listen((bytes) {
      _sendSocket?.send(bytes, InternetAddress(targetIp), targetPort);
    });
  }

  Future<void> startListening(int port) async {
    if (!_isPlayerStreaming) {
      await _player.startPlayerFromStream(
        codec: Codec.pcm16,
        interleaved: true,
        numChannels: 1,
        sampleRate: 16000,
        bufferSize: 8192,
      );
      _isPlayerStreaming = true;
    }

    try {
      // Crear socket de recepción en el puerto indicado
      _receiveSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    } catch (e) {
      throw ConnectionRefusedException("El puerto $port está ocupado o no se puede usar.");
    }

    _receiveSocket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _receiveSocket!.receive();
        if (datagram != null) {
          try {
            // Quitamos el 'await' y el 'readEventsEnabled' para máxima fluidez
            _player.feedUint8FromStream(datagram.data);
          } catch (e) {
            // Si el player falla mientras intentamos alimentarlo
            throw AudioStreamException("Error crítico en el flujo de audio entrante.");
          }
        }
      }
    }, onError: (error) {
      throw ConnectionLostException("Se perdió la conexión del socket de audio.");
    });
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (enabled) {
      await _recorder.resumeRecorder();
    } else {
      await _recorder.pauseRecorder();
    }
  }

  Future<void> stopStreaming() async {
    await _recorder.stopRecorder();
    _sendSocket?.close();
    _sendSocket = null;
  }

  Future<void> stopListening() async {
    if (_isPlayerStreaming) {
      await _player.stopPlayer();
      _isPlayerStreaming = false;
    }
    _receiveSocket?.close();
    _receiveSocket = null;
  }

  Future<void> dispose() async {
    await stopListening();
    await stopStreaming();
    await _recorder.closeRecorder();
    await _player.closePlayer();
    await _audioController.close();
  }
}