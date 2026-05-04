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
      // Tamaño máximo seguro para evitar fragmentación en UDP
      const int maxChunkSize = 1024;

      for (var i = 0; i < bytes.length; i += maxChunkSize) {
        int end = (i + maxChunkSize < bytes.length) ? i + maxChunkSize : bytes.length;
        Uint8List chunk = bytes.sublist(i, end);

        // GUARDA CRÍTICA: Asegurar que el paquete sea par para no corromper el PCM 16-bit
        if (chunk.length % 2 != 0) {
          end -= 1; // Le quitamos 1 byte para que sea par
          chunk = bytes.sublist(i, end);
        }

        if (chunk.isNotEmpty) {
          _sendSocket?.send(chunk, InternetAddress(targetIp), targetPort);
        }
      }
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
      _receiveSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    } catch (e) {
      throw ConnectionRefusedException("El puerto $port está ocupado.");
    }

    _receiveSocket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _receiveSocket!.receive();
        // Guarda crítica: verificar que el player sigue activo ANTES de alimentarlo
        if (datagram != null && _isPlayerStreaming) {
          try {
            _player.uint8ListSink?.add(datagram.data);
          } catch (_) {
            // Ignorar silenciosamente — el player puede estar cerrándose
          }
        }
      }
    }, onError: (_) {
      // No relanzar — el socket puede cerrarse durante stopListening normal
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
    try {
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
      }
    } catch (_) {}
    _sendSocket?.close();
    _sendSocket = null;
  }

  Future<void> stopListening() async {
    // Cerrar socket PRIMERO para que no lleguen más datos
    _receiveSocket?.close();
    _receiveSocket = null;

    // Pequeña pausa para que los callbacks pendientes del socket drenen
    await Future.delayed(const Duration(milliseconds: 50));

    if (_isPlayerStreaming) {
      _isPlayerStreaming = false; // marcar como inactivo ANTES de stopPlayer
      try {
        await _player.stopPlayer();
      } catch (_) {
        // Ignorar errores al parar — puede que ya esté parado
      }
    }
  }

  Future<void> dispose() async {
    await stopListening();
    await stopStreaming();
    await _recorder.closeRecorder();
    await _player.closePlayer();
    await _audioController.close();
  }
}