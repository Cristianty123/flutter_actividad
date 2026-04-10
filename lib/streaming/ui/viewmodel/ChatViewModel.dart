import 'dart:async';
import 'package:flutter/material.dart';
import '../../application/chat/SendMessageUseCase.dart';
import '../../application/chat/WatchMessagesUseCase.dart';
import '../../application/chat/SendTypingStatusUseCase.dart';
import '../../application/audio/StartVoiceStreamUseCase.dart';
import '../../application/audio/StopVoiceStreamUseCase.dart';
import '../../domain/model/Message.dart';
import '../theme/P5Theme.dart';

// Modelo visual para la UI — separa la lógica de dominio de lo que dibuja la pantalla
class ChatMessageUi {
  final String id;
  final String text;
  final String senderName;
  final String? avatarPath;
  final bool isMe;
  final bool isSystem;  // para mostrar banners de JOIN, CALL_START, etc.
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
  final String myIp; // para saber cuáles mensajes son míos

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

  // Colores asignados a cada usuario por IP (como en el juego cada personaje tiene su color)
  final Map<String, Color> _userColors = {};
  final List<Color> _colorPalette = const [
    Color(0xFFFE93C9), // rosa (Ann)
    Color(0xFFF0EA40), // amarillo (Ryuji)
    Color(0xFF1BC8F9), // azul (Yusuke)
    Color(0xFF7CFC00), // verde
    Color(0xFFFF8C00), // naranja
  ];
  int _colorIndex = 0;

  StreamSubscription? _messageSubscription;

  // Debounce para el typing indicator — no spamear la red
  Timer? _typingTimer;
  bool _isTyping = false;

  void init() {
    _messageSubscription = _watchMessages.execute().listen((message) {
      _handleIncomingMessage(message);
    });
  }

  void _handleIncomingMessage(Message message) {
    // Si es un mensaje de texto normal
    if (message.type == MessageType.text) {
      // Si alguien mandó un mensaje, cancelar el typing indicator de ese usuario
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

    // Mensajes de sistema
    if (message.type == MessageType.system ||
        message.type == MessageType.audio) {
      switch (message.content) {
        case 'TYPING_START':
          someoneIsTyping = true;
          typingUserName = message.senderName;
          notifyListeners();
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

  // Llamar desde el TextField onChanged
  void onTextChanged(String text) {
    if (text.isEmpty) {
      _stopTyping();
      return;
    }

    // Si no estaba escribiendo, notificar al grupo
    if (!_isTyping) {
      _isTyping = true;
      _sendTypingStatus.execute(true).catchError((_) {});
    }

    // Resetear el timer de 2 segundos de inactividad
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

    _stopTyping(); // ya mandó el mensaje, dejar de marcar como typing
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

  // Cada usuario recibe un color fijo basado en su IP
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
