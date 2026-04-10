import 'dart:async';
import 'package:flutter/material.dart';
import '../../application/chat/SendMessageUseCase.dart';
import '../../application/chat/WatchMessagesUseCase.dart';
import '../../application/chat/SendTypingStatusUseCase.dart';
import '../../application/audio/StartVoiceStreamUseCase.dart';
import '../../application/audio/StopVoiceStreamUseCase.dart';
import '../../domain/model/Message.dart';
import '../theme/P5Theme.dart';

class ChatMessageUi {
  final String id;
  final String text;
  final String senderName;
  final String? avatarPath;
  final bool isMe;
  final bool isSystem;
  final Color accentColor;

  ChatMessageUi({
    required this.id,
    required this.text,
    required this.senderName,
    this.avatarPath,
    required this.isMe,
    required this.isSystem,
    required this.accentColor,
  });
}

class ChatViewModel extends ChangeNotifier {
  final SendMessageUseCase _sendMessage;
  final WatchMessagesUseCase _watchMessages;
  final SendTypingStatusUseCase _sendTypingStatus;
  final StartVoiceStreamUseCase _startVoice;
  final StopVoiceStreamUseCase _stopVoice;

  // Mutable — se actualiza después del handshake Wi-Fi Direct
  String myIp;

  ChatViewModel({
    required SendMessageUseCase sendMessage,
    required WatchMessagesUseCase watchMessages,
    required SendTypingStatusUseCase sendTypingStatus,
    required StartVoiceStreamUseCase startVoice,
    required StopVoiceStreamUseCase stopVoice,
    required this.myIp,
  })  : _sendMessage = sendMessage,
        _watchMessages = watchMessages,
        _sendTypingStatus = sendTypingStatus,
        _startVoice = startVoice,
        _stopVoice = stopVoice;

  final List<ChatMessageUi> messages = [];
  bool someoneIsTyping = false;
  String? typingUserName;
  bool isInCall = false;
  String? errorMessage;

  final Map<String, Color> _userColors = {};
  final List<Color> _colorPalette = const [
    Color(0xFFFE93C9),
    Color(0xFFF0EA40),
    Color(0xFF1BC8F9),
    Color(0xFF7CFC00),
    Color(0xFFFF8C00),
  ];
  int _colorIndex = 0;

  StreamSubscription? _messageSubscription;
  Timer? _typingTimer;
  bool _isTyping = false;

  // Llamar UNA sola vez al entrar al chat.
  // Si ya hay suscripción activa, la cancela y crea una nueva
  // (por si el IP cambió tras reconexión).
  void init({String? updatedIp}) {
    if (updatedIp != null && updatedIp.isNotEmpty) {
      myIp = updatedIp;
    }

    // Cancelar suscripción previa — evita escuchar el stream dos veces
    _messageSubscription?.cancel();
    _messageSubscription = null;

    _messageSubscription = _watchMessages.execute().listen((message) {
      _handleIncomingMessage(message);
    });
  }

  // Limpiar mensajes al salir del chat para que al volver no aparezcan los anteriores
  void reset() {
    messages.clear();
    someoneIsTyping = false;
    typingUserName = null;
    isInCall = false;
    errorMessage = null;
    _messageSubscription?.cancel();
    _messageSubscription = null;
  }

  void _handleIncomingMessage(Message message) {
    if (message.type == MessageType.text) {
      if (typingUserName == message.senderName) {
        someoneIsTyping = false;
        typingUserName = null;
      }

      messages.add(ChatMessageUi(
        id: message.id,
        text: message.content,
        senderName: message.senderName,
        isMe: message.senderId == myIp,
        isSystem: false,
        accentColor: _colorForUser(message.senderId),
      ));
      notifyListeners();
      return;
    }

    if (message.type == MessageType.system ||
        message.type == MessageType.audio) {
      switch (message.content) {
        case 'TYPING_START':
        // No mostrar el indicador para los propios mensajes de typing
          if (message.senderId != myIp) {
            someoneIsTyping = true;
            typingUserName = message.senderName;
            notifyListeners();
          }
          break;

        case 'TYPING_STOP':
          someoneIsTyping = false;
          typingUserName = null;
          notifyListeners();
          break;

        case 'JOIN':
          messages.add(ChatMessageUi(
            id: message.id,
            text: '${message.senderName} se unió a la sala',
            senderName: 'Sistema',
            isMe: false,
            isSystem: true,
            accentColor: kPersonaRed,
          ));
          notifyListeners();
          break;

        case 'CALL_START':
          isInCall = true;
          messages.add(ChatMessageUi(
            id: message.id,
            text: '${message.senderName} inició una llamada',
            senderName: 'Sistema',
            isMe: false,
            isSystem: true,
            accentColor: kPersonaRed,
          ));
          notifyListeners();
          break;

        case 'CALL_END':
          isInCall = false;
          messages.add(ChatMessageUi(
            id: message.id,
            text: 'La llamada ha terminado',
            senderName: 'Sistema',
            isMe: false,
            isSystem: true,
            accentColor: kPersonaRed,
          ));
          notifyListeners();
          break;
      }
    }
  }

  void onTextChanged(String text) {
    if (text.isEmpty) {
      _stopTyping();
      return;
    }
    if (!_isTyping) {
      _isTyping = true;
      _sendTypingStatus.execute(true).catchError((_) {});
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), _stopTyping);
  }

  void _stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      _typingTimer?.cancel();
      _sendTypingStatus.execute(false).catchError((_) {});
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _stopTyping();
    errorMessage = null;
    try {
      await _sendMessage.execute(text.trim());
    } catch (e) {
      errorMessage = 'Error al enviar: $e';
      notifyListeners();
    }
  }

  Future<void> startCall() async {
    if (isInCall) return;
    try {
      await _startVoice.execute();
    } catch (e) {
      errorMessage = 'Error al iniciar llamada: $e';
      notifyListeners();
    }
  }

  Future<void> endCall() async {
    if (!isInCall) return;
    try {
      await _stopVoice.execute();
    } catch (e) {
      errorMessage = 'Error al terminar llamada: $e';
      notifyListeners();
    }
  }

  Color _colorForUser(String ip) {
    if (!_userColors.containsKey(ip)) {
      _userColors[ip] = _colorPalette[_colorIndex % _colorPalette.length];
      _colorIndex++;
    }
    return _userColors[ip]!;
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }
}