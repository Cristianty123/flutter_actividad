import 'package:flutter/material.dart';
import '../../AppDependencies.dart';
import '../theme/P5Theme.dart';
import '../widgets/P5Avatar.dart';
import '../../domain/model/PeerDevice.dart';
import '../../domain/model/ConnectionStatus.dart';
import '../widgets/P5BackgroundParticles.dart';
import '../widgets/P5PulsingButton.dart';
import 'ChatScreen.dart';

class DiscoveryScreen extends StatefulWidget {
  final AppDependencies deps;
  const DiscoveryScreen({super.key, required this.deps});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  late VoidCallback _connectionListener;

  @override
  void initState() {
    super.initState();
    widget.deps.discoveryVm.init();

    _connectionListener = () {
      if (widget.deps.discoveryVm.isConnected && mounted) {
        // Remover listener ANTES de navegar para evitar llamadas duplicadas
        widget.deps.discoveryVm.removeListener(_connectionListener);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(deps: widget.deps)),
        );
      }
    };

    widget.deps.discoveryVm.addListener(_connectionListener);
  }

  @override
  void dispose() {
    widget.deps.discoveryVm.removeListener(_connectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPersonaBlack,
      body: Stack(
        children: [
          // Partículas de fondo
          const Positioned.fill(child: P5BackgroundParticles()),

          SafeArea(
            child: ListenableBuilder(
              listenable: widget.deps.discoveryVm,
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildStatusBar(),
                    Expanded(child: _buildPeerList()),
                    _buildSearchButton(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Transform.rotate(
        angle: -0.03,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: kPersonaRed,
            border: Border.all(color: kPersonaWhite, width: 2),
          ),
          child: const Text(
            'PHANTOM\nCHAT',
            style: TextStyle(
              color: kPersonaWhite,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    final status = widget.deps.discoveryVm.status;
    final label = switch (status) {
      ConnectionStatus.disconnected => 'DESCONECTADO',
      ConnectionStatus.discovering  => 'BUSCANDO...',
      ConnectionStatus.connecting   => 'CONECTANDO...',
      ConnectionStatus.connected    => 'CONECTADO',
      ConnectionStatus.error        => 'ERROR',
    };
    final color = switch (status) {
      ConnectionStatus.connected   => const Color(0xFF00C853),
      ConnectionStatus.error       => kPersonaRed,
      ConnectionStatus.discovering => Colors.orange,
      _                            => Colors.grey,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          if (widget.deps.discoveryVm.errorMessage != null) ...[
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                widget.deps.discoveryVm.errorMessage!,
                style: const TextStyle(color: kPersonaRed, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeerList() {
    final peers = widget.deps.discoveryVm.peers;

    if (peers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_find, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            Text(
              widget.deps.discoveryVm.isSearching
                  ? 'BUSCANDO PHANTOM THIEVES...'
                  : 'PRESIONA BUSCAR',
              style: const TextStyle(
                color: Colors.white38,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: peers.length,
      itemBuilder: (_, i) => _PeerTile(
        peer: peers[i],
        onTap: () => widget.deps.discoveryVm.connectTo(peers[i]),
      ),
    );
  }

  Widget _buildSearchButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Center(
        child: ListenableBuilder(
          listenable: widget.deps.discoveryVm,
          builder: (_, __) => P5PulsingButton(
            label: widget.deps.discoveryVm.isSearching
                ? 'BUSCANDO...'
                : 'BUSCAR DISPOSITIVOS',
            onTap: widget.deps.discoveryVm.isSearching
                ? null
                : widget.deps.discoveryVm.discoverPeers,
            angle: -0.02,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
          ),
        ),
      ),
    );
  }
}

class _PeerTile extends StatelessWidget {
  final PeerDevice peer;
  final VoidCallback onTap;

  const _PeerTile({required this.peer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white10,
          border: Border.all(color: kPersonaWhite.withOpacity(0.3)),
          boxShadow: const [
            BoxShadow(color: kPersonaRed, offset: Offset(3, 3))
          ],
        ),
        child: Row(
          children: [
            // Avatar P5 con inicial del nombre del dispositivo
            P5Avatar(
              name: peer.deviceName,
              accentColor: kPersonaRed,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peer.deviceName.toUpperCase(),
                    style: const TextStyle(
                      color: kPersonaWhite,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    peer.macAddress,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            // Flecha estilo P5
            Container(
              padding: const EdgeInsets.all(6),
              color: kPersonaRed,
              child: const Icon(Icons.chevron_right,
                  color: kPersonaWhite, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}