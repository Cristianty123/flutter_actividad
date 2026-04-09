class PeerDevice {
  final String deviceName;
  final String macAddress;     // Esto sí está disponible antes de conectar
  final String? ipAddress;     // Nullable: solo existe después del handshake
  final bool isGroupOwner;
  final bool isConnected;

  PeerDevice({
    required this.deviceName,
    required this.macAddress,
    this.ipAddress,
    this.isGroupOwner = false,
    this.isConnected = false,
  });

  // actualizar el objeto con la ip después del handshake
  PeerDevice copyWith({
    String? ipAddress,
    bool? isGroupOwner,
    bool? isConnected,
  }) => PeerDevice(
    deviceName: deviceName,
    macAddress: macAddress,
    ipAddress: ipAddress ?? this.ipAddress,
    isGroupOwner: isGroupOwner ?? this.isGroupOwner,
    isConnected: isConnected ?? this.isConnected,
  );
}