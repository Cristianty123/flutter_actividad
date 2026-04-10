import 'package:flutter/material.dart';
import '../../AppDependencies.dart';
import '../theme/P5Theme.dart';
import '../viewmodel/ChatViewModel.dart';
import '../widgets/P5MessageEntry.dart';
import '../widgets/P5MessageReply.dart';
import '../widgets/P5NavButton.dart';
import '../widgets/P5TypingIndicator.dart';
import '../widgets/P5BackgroundParticles.dart';
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kPersonaBlack,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: kPersonaRed, width: 2),
          borderRadius: BorderRadius.zero,
        ),
        title: const Text('SALIR DEL CHAT',
            style: TextStyle(
                color: kPersonaWhite,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic)),
        content: const Text('Se cerrará la conexión con todos los dispositivos.',
            style: TextStyle(color: kPersonaWhite)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: kPersonaWhite)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SALIR',
                style: TextStyle(color: kPersonaRed, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
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
              return GestureDetector(
                onTap: inCall
                    ? widget.deps.chatVm.endCall
                    : widget.deps.chatVm.startCall,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

        // Buscar el siguiente mensaje que NO sea de sistema
        // (la línea salta banners de sistema igual que el original)
        ChatMessageUi? nextMsg;
        for (int j = i + 1; j < messages.length; j++) {
          if (!messages[j].isSystem) {
            nextMsg = messages[j];
            break;
          }
        }

        final bool drawLine = nextMsg != null;

        // Construir widget base
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

        // Envolver con la línea conectora si corresponde
        if (!msg.isSystem && drawLine) {
          msgWidget = CustomPaint(
            painter: _ConnectingLinePainter(
              isMe: msg.isMe,
              nextIsMe: nextMsg!.isMe,
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
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

// -------------------------------------------------------------------
// Painter que dibuja el trapecio negro entre dos mensajes consecutivos
// Puerto directo de connectingLineModifier.kt
// -------------------------------------------------------------------
class _ConnectingLinePainter extends CustomPainter {
  final bool isMe;
  final bool nextIsMe;

  // Valores sacados de TranscriptSizes en TranscriptState.kt
  static const double _avatarWidth = 110.0;  // AvatarSize.width
  static const double _avatarHeight = 90.0;  // AvatarSize.height
  static const double _lineWidth = 52.0;      // promedio MinLineWidth(44)+MaxLineWidth(60)
  static const double _entrySpacing = 16.0;   // EntrySpacing
  static const double _renCenterX = 60.0;     // RenMessageCenter.x

  const _ConnectingLinePainter({required this.isMe, required this.nextIsMe});

  /// Calcula los puntos izquierdo y derecho donde la línea toca un mensaje.
  /// [fromRight] = true → mensaje propio (Reply, anclado a la derecha)
  /// [fromRight] = false → mensaje ajeno (Entry, anclado al avatar izquierdo)
  (Offset, Offset) _linePoints({
    required bool fromRight,
    required double y,
    required double totalWidth,
  }) {
    if (fromRight) {
      // Centro de la burbuja Reply = lado derecho - _renCenterX
      final cx = totalWidth - _renCenterX;
      return (
      Offset(cx - _lineWidth / 2, y),
      Offset(cx + _lineWidth / 2, y),
      );
    } else {
      // Centro del avatar izquierdo = _avatarWidth / 2
      final cx = _avatarWidth / 2;
      return (
      Offset(cx - _lineWidth / 2, y),
      Offset(cx + _lineWidth / 2, y),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Puntos superiores: mitad del avatar/burbuja de ESTE mensaje
    final (topLeft, topRight) = _linePoints(
      fromRight: isMe,
      y: _avatarHeight / 2,
      totalWidth: size.width,
    );

    // Puntos inferiores: mitad del avatar/burbuja del SIGUIENTE mensaje
    // (ubicado después del gap kEntrySpacing)
    final double bottomY = size.height + _entrySpacing + _avatarHeight / 2;
    final (bottomLeft, bottomRight) = _linePoints(
      fromRight: nextIsMe,
      y: bottomY,
      totalWidth: size.width,
    );

    final path = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();

    // Sombra desplazada hacia abajo (translate top = 16.dp del original)
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
      old.isMe != isMe || old.nextIsMe != nextIsMe;
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