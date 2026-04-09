enum ConnectionStatus {
  disconnected,
  discovering,   // buscando peers, diferente a connecting
  connecting,    // handshake en progreso
  connected,
  error,
}