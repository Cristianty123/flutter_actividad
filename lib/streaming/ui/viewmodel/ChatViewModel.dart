import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../application/chat/SendMessageUseCase.dart';
import '../../application/chat/WatchMessagesUseCase.dart';
import '../../application/chat/SendTypingStatusUseCase.dart';
import '../../application/audio/StartVoiceStreamUseCase.dart';
import '../../application/audio/StopVoiceStreamUseCase.dart';
import '../../domain/model/Message.dart';
import '../theme/P5Theme.dart';

const double _kMinLineShift = 16.0;
const double _kMaxLineShift = 48.0;

class ChatMessageUi {
  final String id;
  final String text;
  final String senderName;
  final String? avatarPath;
  final bool isMe;
  final bool isSystem;
  final Color accentColor;
  final double lineShift;

  ChatMessageUi({
    required this.id,
    required this.text,
    required this.senderName,
    this.avatarPath,
    required this.isMe,
    required this.isSystem,
    required this.accentColor,
    this.lineShift = 0.0,
  });
}

class ChatViewModel extends ChangeNotifier {
  final SendMessageUseCase _sendMessage;
  final WatchMessagesUseCase _watchMessages;
  final SendTypingStatusUseCase _sendTypingStatus;
  final StartVoiceStreamUseCase _startVoice;
  final StopVoiceStreamUseCase _stopVoice;

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

  // Llamada entrante — usamos un flag de un solo disparo
  bool incomingCall = false;
  String incomingCallerName = '';
  String incomingCallerInitial = '';
  Color incomingCallerColor = kPersonaRed;

  final Map<String, Color> _userColors = {};
  final List<Color> _colorPalette = const [
    Color(0xFFFE93C9),
    Color(0xFFF0EA40),
    Color(0xFF1BC8F9),
    Color(0xFF7CFC00),
    Color(0xFFFF8C00),
  ];
  int _colorIndex = 0;
  final _rng = Random();

  StreamSubscription? _messageSubscription;
  Timer? _typingTimer;
  bool _isTyping = false;

  void init({String? updatedIp}) {
    if (updatedIp != null && updatedIp.isNotEmpty) myIp = updatedIp;
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _messageSubscription =
        _watchMessages.execute().listen(_handleIncomingMessage);
  }

  void reset() {
    messages.clear();
    someoneIsTyping = false;
    typingUserName = null;
    isInCall = false;
    incomingCall = false;
    errorMessage = null;
    _messageSubscription?.cancel();
    _messageSubscription = null;
  }

  double _computeLineShift(int messageIndex) {
    if (messageIndex == 0) return 0.0;
    final direction = (messageIndex % 2 == 0) ? 1.0 : -1.0;
    final magnitude =
        _kMinLineShift + _rng.nextDouble() * (_kMaxLineShift - _kMinLineShift);
    return magnitude * direction;
  }

  void _handleIncomingMessage(Message message) {
    if (message.type == MessageType.text) {
      if (typingUserName == message.senderName) {
        someoneIsTyping = false;
        typingUserName = null;
      }
      final idx = messages.length;
      messages.add(ChatMessageUi(
        id: message.id,
        text: message.content,
        senderName: message.senderName,
        isMe: message.senderId == myIp,
        isSystem: false,
        accentColor: _colorForUser(message.senderId),
        lineShift: _computeLineShift(idx),
      ));
      notifyListeners();
      return;
    }

    if (message.type == MessageType.system ||
        message.type == MessageType.audio) {
      switch (message.content) {
        case 'TYPING_START':
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
        // FIX Bug 2 y 3:
        // Solo marcamos llamada ENTRANTE si NO somos nosotros quienes la
        // iniciamos. El inyección local de sendMessage hace que el propio
        // llamante reciba su propio CALL_START — lo ignoramos para no
        // retroalimentar el flujo.
          if (message.senderId != myIp) {
            // Evitar abrir CallScreen varias veces si llegan múltiples
            // CALL_START del mismo emisor (p.ej. reintentos)
            if (!incomingCall && !isInCall) {
              incomingCall = true;
              incomingCallerName = message.senderName;
              incomingCallerInitial = message.senderName.isNotEmpty
                  ? message.senderName[0]
                  : '?';
              incomingCallerColor = _colorForUser(message.senderId);
            }
          }
          isInCall = true;
          messages.add(ChatMessageUi(
            id: message.id,
            text: message.senderId == myIp
                ? 'Iniciaste una llamada'
                : '${message.senderName} inició una llamada',
            senderName: 'Sistema',
            isMe: false,
            isSystem: true,
            accentColor: kPersonaRed,
          ));
          notifyListeners();
          break;

        case 'CALL_END':
          isInCall = false;
          incomingCall = false;
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

  /// Aceptar llamada entrante.
  /// FIX: NO llama a startVoice.execute() completo porque eso enviaría
  /// otro CALL_START por la red, creando un bucle.
  /// Solo arranca el audio local (player + recorder) sin notificar.
  Future<void> acceptCall() async {
    // Limpiar flag ANTES de cualquier await para que el listener del
    // ChatScreen no vuelva a abrir otra CallScreen.
    incomingCall = false;
    notifyListeners();

    // Solo iniciar el audio en este dispositivo — el CALL_START ya fue
    // enviado por quien llamó, no necesitamos enviarlo de nuevo.
    try {
      await _startVoice.executeAudioOnly();
    } catch (e) {
      errorMessage = 'Error al aceptar llamada: $e';
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