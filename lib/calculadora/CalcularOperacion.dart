class CalcularOperacion {
  double calcular(String expresion) {
    final tokens = _tokenizar(expresion.replaceAll(',', '.'));
    if (tokens.isEmpty) return 0;

    final operandos = <double>[];
    final operadores = <String>[];

    for (final token in tokens) {
      final numero = double.tryParse(token);
      if (numero != null) {
        operandos.add(numero);
      } else {
        while (operadores.isNotEmpty &&
            _prioridad(operadores.last) >= _prioridad(token)) {
          _resolverOperacion(operandos, operadores);
        }
        operadores.add(token);
      }
    }

    while (operadores.isNotEmpty) {
      _resolverOperacion(operandos, operadores);
    }

    if (operandos.isEmpty) return 0;
    return operandos.last;
  }

  static String formatearResultado(double valor) {
    var texto = valor.toStringAsFixed(3);
    texto = texto.replaceFirst(RegExp(r'\.?0+$'), '');
    if (texto == '-0') texto = '0';
    return texto;
  }

  List<String> _tokenizar(String expr) {
    final tokens = <String>[];
    for (int i = 0; i < expr.length; i++) {
      final c = expr[i];

      if (c == ' ') continue;

      final esMenosUnario = c == '-' &&
          (tokens.isEmpty || _esOperador(tokens.last));

      if (_esDigito(c) || c == '.' || esMenosUnario) {
        final sb = StringBuffer()..write(c);
        i++;
        while (i < expr.length) {
          final n = expr[i];
          if (_esDigito(n) || n == '.') {
            sb.write(n);
            i++;
          } else {
            break;
          }
        }
        i--;
        tokens.add(sb.toString());
        continue;
      }

      if ('+-x*/÷%'.contains(c)) {
        tokens.add(c);
      } else {
        throw FormatException('Símbolo inválido: $c');
      }
    }
    return tokens;
  }

  void _resolverOperacion(List<double> operandos, List<String> operadores) {
    if (operandos.length < 2 || operadores.isEmpty) {
      throw FormatException('Expresión inválida');
    }

    final b = operandos.removeLast();
    final a = operandos.removeLast();
    final op = operadores.removeLast();

    switch (op) {
      case '+':
        operandos.add(a + b);
        break;
      case '-':
        operandos.add(a - b);
        break;
      case 'x':
      case '*':
        operandos.add(a * b);
        break;
      case '÷':
      case '/':
        if (b == 0) throw const FormatException('No se puede dividir entre 0');
        operandos.add(a / b);
        break;
      case '%':
        if (b == 0) throw const FormatException('No se puede hacer mod con 0');
        operandos.add(a.remainder(b));
        break;
      default:
        throw FormatException('Operador inválido: $op');
    }
  }

  int _prioridad(String op) {
    switch (op) {
      case '+':
      case '-':
        return 1;
      case 'x':
      case '*':
      case '÷':
      case '/':
      case '%':
        return 2;
      default:
        throw FormatException('Operador inválido: $op');
    }
  }

  bool _esOperador(String t) => ['+', '-', 'x', '*', '÷', '/', '%'].contains(t);
  bool _esDigito(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
}