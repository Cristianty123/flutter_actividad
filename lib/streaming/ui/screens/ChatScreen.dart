import 'package:flutter/material.dart';
import '../../AppDependencies.dart';
import '../theme/P5Theme.dart';
import '../viewmodel/ChatViewModel.dart';
import '../widgets/P5ConfirmDialog.dart';
import '../widgets/P5MessageEntry.dart';
import '../widgets/P5MessageReply.dart';
import '../widgets/P5NavButton.dart';
import '../widgets/P5TypingIndicator.dart';
import '../widgets/P5BackgroundParticles.dart';
import 'CallState.dart';
import 'DiscoveryScreen.dart';

class ChatScreen extends StatefulWidget {
  final AppDependencies deps;
  const ChatScreen({super.key, required this.deps});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initChatWithCurrentIp();
    widget.deps.chatVm.addListener(_scrollToBottom);
  }

  void _openCallScreen({required bool incoming}) {
    final vm = widget.deps.chatVm;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callerName: incoming
              ? vm.incomingCallerName
              : 'Tú',
          callerInitial: incoming
              ? vm.incomingCallerInitial
              : (vm.myIp.isNotEmpty ? vm.myIp[0] : '?'),
          callerColor: incoming
              ? vm.incomingCallerColor
              : kPersonaRed,
          initialState: incoming
              ? CallState.incoming
              : CallState.calling,
          onHangUp: () async {
            await vm.endCall();
            if (mounted) Navigator.pop(context);
          },
          onAccept: incoming
              ? () => vm.acceptCall()
              : null,
        ),
      ),
    ).then((_) {
      // Al volver del CallScreen, si la llamada sigue activa, colgarla
      if (vm.isInCall) vm.endCall();
    });

    // Si somos nosotros quien llama, iniciar el audio
    if (!incoming) vm.startCall();
  }

  Future<void> _initChatWithCurrentIp() async {
    final ip = await widget.deps.userRepo.getIpAddress();
    widget.deps.chatVm.init(updatedIp: ip);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    await widget.deps.chatVm.sendMessage(text);
  }

  Future<void> _confirmExit() async {
    final confirm = await P5ConfirmDialog.show(
      context,
      title: 'SALIR DEL CHAT',
      message: 'Se cerrará la conexión con todos los dispositivos.',
      confirmLabel: 'SALIR',
      cancelLabel: 'QUEDARSE',
    );

    if (confirm && mounted) {
      widget.deps.chatVm.reset();
      await widget.deps.discoveryVm.disconnect();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DiscoveryScreen(deps: widget.deps)),
      );
    }
  }

  @override
  void dispose() {
    widget.deps.chatVm.removeListener(_scrollToBottom);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPersonaRed,
      body: Stack(
        children: [
          const Positioned.fill(child: P5BackgroundParticles()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListenableBuilder(
                    listenable: widget.deps.chatVm,
                    builder: (_, __) => _buildMessageList(),
                  ),
                ),
                ListenableBuilder(
                  listenable: widget.deps.chatVm,
                  builder: (_, __) => P5TypingIndicator(
                    visible: widget.deps.chatVm.someoneIsTyping,
                  ),
                ),
                _buildInputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: kPersonaBlack,
        border: Border(bottom: BorderSide(color: kPersonaRed, width: 2)),
      ),
      child: Row(
        children: [
          P5NavButton(pointsLeft: true, onTap: _confirmExit),
          const SizedBox(width: 16),
          const Expanded(
            child: Text('PHANTOM CHAT',
                style: TextStyle(
                    color: kPersonaWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 2)),
          ),
          ListenableBuilder(
            listenable: widget.deps.chatVm,
            builder: (_, __) {
              final inCall = widget.deps.chatVm.isInCall;
              final incoming = widget.deps.chatVm.incomingCall;

              // Si hay llamada entrante, mostrar banner y abrir CallScreen
              if (incoming) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && widget.deps.chatVm.incomingCall) {
                    widget.deps.chatVm.incomingCall = false; // evitar loop
                    _openCallScreen(incoming: true);
                  }
                });
              }

              return GestureDetector(
                onTap: inCall ? widget.deps.chatVm.endCall : () => _openCallScreen(incoming: false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: inCall ? Colors.green.shade700 : kPersonaRed,
                    border: Border.all(color: kPersonaWhite, width: 2),
                    boxShadow: const [
                      BoxShadow(color: kPersonaWhite, offset: Offset(2, 2))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(inCall ? Icons.call_end : Icons.call,
                          color: kPersonaWhite, size: 18),
                      const SizedBox(width: 6),
                      Text(inCall ? 'COLGAR' : 'LLAMAR',
                          style: const TextStyle(
                              color: kPersonaWhite,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final messages = widget.deps.chatVm.messages;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];

        // Buscar el siguiente mensaje real (saltar banners de sistema)
        ChatMessageUi? nextMsg;
        for (int j = i + 1; j < messages.length; j++) {
          if (!messages[j].isSystem) {
            nextMsg = messages[j];
            break;
          }
        }

        // Widget base del mensaje
        Widget msgWidget;
        if (msg.isSystem) {
          msgWidget = _SystemBanner(text: msg.text);
        } else if (msg.isMe) {
          msgWidget = P5MessageReply(text: msg.text);
        } else {
          msgWidget = P5MessageEntry(
            text: msg.text,
            senderName: msg.senderName,
            avatarPath: msg.avatarPath,
            accentColor: msg.accentColor,
          );
        }

        // Envolver con la línea conectora si hay un siguiente mensaje
        if (!msg.isSystem && nextMsg != null) {
          msgWidget = CustomPaint(
            // painter (no foregroundPainter) → dibuja DETRÁS de las burbujas
            painter: _ConnectingLinePainter(
              isMe: msg.isMe,
              nextIsMe: nextMsg.isMe,
              // El shift del punto SUPERIOR viene del mensaje actual
              topShift: msg.lineShift,
              // El shift del punto INFERIOR viene del mensaje siguiente
              bottomShift: nextMsg.lineShift,
            ),
            child: msgWidget,
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: kEntrySpacing),
          child: msgWidget,
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: kPersonaBlack,
        border: Border(top: BorderSide(color: kPersonaRed, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Transform.rotate(
              angle: 0.005,
              child: Container(
                decoration: BoxDecoration(
                  color: kPersonaWhite,
                  border: Border.all(color: kPersonaBlack, width: 2),
                  boxShadow: const [
                    BoxShadow(color: kPersonaRed, offset: Offset(3, 3))
                  ],
                ),
                child: TextField(
                  controller: _textController,
                  onChanged: widget.deps.chatVm.onTextChanged,
                  style: const TextStyle(
                      color: kPersonaBlack, fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(
                    hintText: 'MESSAGE...',
                    hintStyle: TextStyle(color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPersonaRed,
                border: Border.all(color: kPersonaWhite, width: 2),
                boxShadow: const [
                  BoxShadow(color: kPersonaWhite, offset: Offset(2, 2))
                ],
              ),
              child: const Icon(Icons.send, color: kPersonaWhite, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// Eso hace que la banda se incline en distintas direcciones según qué tan
// -------------------------------------------------------------------
class _ConnectingLinePainter extends CustomPainter {
  final bool isMe;
  final bool nextIsMe;
  final double topShift;    // shift del punto superior (de este mensaje)
  final double bottomShift; // shift del punto inferior (del siguiente mensaje)

  // Constantes de TranscriptSizes
  static const double _avatarWidth   = 110.0;
  static const double _avatarHeight  = 90.0;
  static const double _lineWidth     = 52.0;
  static const double _entrySpacing  = 16.0;
  static const double _renCenterX    = 60.0; // RenMessageCenter.x

  const _ConnectingLinePainter({
    required this.isMe,
    required this.nextIsMe,
    required this.topShift,
    required this.bottomShift,
  });

  /// Centro horizontal base del ancla, sin aplicar shift.
  double _baseCenterX({required bool fromRight, required double totalWidth}) {
    return fromRight
        ? totalWidth - _renCenterX   // Reply: anclado a la derecha
        : _avatarWidth / 2;          // Entry: anclado al centro del avatar
  }

  /// Par de puntos (izquierdo, derecho) del trapecio a una altura [y],
  /// con el centro desplazado [shift] respecto al ancla base.
  (Offset, Offset) _points({
    required bool fromRight,
    required double y,
    required double totalWidth,
    required double shift,
  }) {
    final cx = _baseCenterX(fromRight: fromRight, totalWidth: totalWidth) + shift;
    return (
    Offset(cx - _lineWidth / 2, y),
    Offset(cx + _lineWidth / 2, y),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Puntos superiores — mitad vertical del mensaje actual
    final (topLeft, topRight) = _points(
      fromRight: isMe,
      y: _avatarHeight / 2,
      totalWidth: size.width,
      shift: topShift,
    );

    // Puntos inferiores — mitad vertical del mensaje siguiente
    final double bottomY = size.height + _entrySpacing + _avatarHeight / 2;
    final (bottomLeft, bottomRight) = _points(
      fromRight: nextIsMe,
      y: bottomY,
      totalWidth: size.width,
      shift: bottomShift,
    );

    final path = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();

    // Sombra difuminada desplazada 16px hacia abajo
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.save();
    canvas.translate(0, 16);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Trapecio negro
    canvas.drawPath(path, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(_ConnectingLinePainter old) =>
      old.isMe != isMe ||
          old.nextIsMe != nextIsMe ||
          old.topShift != topShift ||
          old.bottomShift != bottomShift;
}

// -------------------------------------------------------------------
// Banner de sistema
// -------------------------------------------------------------------
class _SystemBanner extends StatelessWidget {
  final String text;
  const _SystemBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.rotate(
        angle: -0.02,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: kPersonaBlack,
            border: Border.all(color: kPersonaRed, width: 1),
          ),
          child: Text(
            text.toUpperCase(),
            style: const TextStyle(
              color: kPersonaRed,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}