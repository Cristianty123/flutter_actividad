class ChatUser {
  final String name;
  final String ipAddress;
  final String? avatarPath; // ruta local de la foto elegida

  ChatUser({
    required this.name,
    required this.ipAddress,
    this.avatarPath,        // null = mostrar avatar por defecto
  });
}