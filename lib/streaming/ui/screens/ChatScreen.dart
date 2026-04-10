import 'package:flutter/material.dart';
import '../../AppDependencies.dart';
import '../../domain/repository/IUserRepository.dart';
import '../theme/P5Theme.dart';
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

    // Obtener el IP real (ya disponible tras el handshake Wi-Fi) e iniciar
    // el ViewModel con él. init() cancela cualquier suscripción previa,
    // por lo que es seguro aunque ChatScreen se reconstruya.
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
        title: const Text(
          'SALIR DEL CHAT',
          style: TextStyle(
            color: kPersonaWhite,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
        content: const Text(
          'Se cerrará la conexión con todos los dispositivos.',
          style: TextStyle(color: kPersonaWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR',
                style: TextStyle(color: kPersonaWhite)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SALIR',
                style: TextStyle(
                    color: kPersonaRed, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Limpiar estado del chat antes de salir
      widget.deps.chatVm.reset();
      await widget.deps.discoveryVm.disconnect();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => DiscoveryScreen(deps: widget.deps)),
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
      decoration: BoxDecoration(
        color: kPersonaBlack,
        border: const Border(
          bottom: BorderSide(color: kPersonaRed, width: 2),
        ),
      ),
      child: Row(
        children: [
          P5NavButton(pointsLeft: true, onTap: _confirmExit),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'PHANTOM CHAT',
              style: TextStyle(
                color: kPersonaWhite,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 2,
              ),
            ),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
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
                      Icon(
                        inCall ? Icons.call_end : Icons.call,
                        color: kPersonaWhite,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        inCall ? 'COLGAR' : 'LLAMAR',
                        style: const TextStyle(
                          color: kPersonaWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
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
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: kEntrySpacing),
      itemBuilder: (_, i) {
        final msg = messages[i];
        if (msg.isSystem) return _SystemBanner(text: msg.text);
        if (msg.isMe) return P5MessageReply(text: msg.text);
        return P5MessageEntry(
          text: msg.text,
          senderName: msg.senderName,
          avatarPath: msg.avatarPath,
          accentColor: msg.accentColor,
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: kPersonaBlack,
        border: const Border(
          top: BorderSide(color: kPersonaRed, width: 2),
        ),
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
                    color: kPersonaBlack,
                    fontWeight: FontWeight.w900,
                  ),
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