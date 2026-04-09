// clase base para manejar excepciones relacionadas con la red en la aplicación de streaming
class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);
}

// Wi-Fi Direct se cayó o el dispositivo se alejó
class ConnectionLostException extends NetworkException {
  ConnectionLostException(super.message);
}

// El GO rechazó la conexión o hubo fallo en el handshake
class ConnectionRefusedException extends NetworkException {
  ConnectionRefusedException(super.message);
}

// El socket TCP/UDP falló al enviar
class MessageSendException extends NetworkException {
  MessageSendException(super.message);
}

// El stream de audio se interrumpió
class AudioStreamException extends NetworkException {
  AudioStreamException(super.message);
}