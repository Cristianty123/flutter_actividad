import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';

import '../../domain/exceptions/NetworkException.dart';

class AudioService {
  final _recorder = FlutterSoundRecorder();
  final _player = FlutterSoundPlayer();
  final _audioController = StreamController<Uint8List>.broadcast();

  // Dos sockets separados: uno para enviar (streaming) y otro para recibir (listening)
  RawDatagramSocket? _sendSocket;
  RawDatagramSocket? _receiveSocket;

  bool _isPlayerStreaming = false;

  Stream<Uint8List> get incomingAudioStream => _audioController.stream;

  Future<void> initialize() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  Future<void> startStreaming(String targetIp, int targetPort) async {
    // Crear socket de envío si no existe (puerto efímero)
    _sendSocket ??= await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    await _recorder.startRecorder(
      toStream: _audioController,
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
    );

    // Escuchar los bytes del micrófono y enviarlos por UDP
    _audioController.stream.listen((bytes) {
      _sendSocket?.send(bytes, InternetAddress(targetIp), targetPort);
    });
  }

  Future<void> startListening(int port) async {
    // Iniciar el player en modo stream (solo una vez)
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

    // Crear socket de recepción en el puerto indicado
    _receiveSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);

    // Escuchar datagramas entrantes y alimentar al player
    _receiveSocket!.listen((event) async {
      if (event == RawSocketEvent.read) {
        final datagram = _receiveSocket!.receive();
        if (datagram != null) {
          _receiveSocket!.readEventsEnabled = false;
          try {
            await _player.feedUint8FromStream(datagram.data);
          } catch (e) {
            // 1. El player se detuvo o el buffer falló
            if (!_isPlayerStreaming) {
              throw AudioStreamException("El streaming de audio se detuvo inesperadamente.");
            }
            // 2. Error genérico de la librería de sonido
            throw AudioStreamException("Error en el buffer de reproducción: $e");
          } finally {
            _receiveSocket!.readEventsEnabled = true;
          }
        }
      }
    }, onError: (error) {
      throw ConnectionLostException("Se perdió la conexión UDP de escucha.");
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
    // Detener ambas funcionalidades
    await stopListening();
    await stopStreaming();
    // Cerrar recursos del sistema
    await _recorder.closeRecorder();
    await _player.closePlayer();
    await _audioController.close();
  }
}