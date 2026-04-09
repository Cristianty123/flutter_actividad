import 'package:flutter/material.dart';

import 'CalcularOperacion.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Calculadora'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final CalcularOperacion _calc = CalcularOperacion();

  String pantalla = '0';
  String _entradaActual = '0';
  String _expresion = '';
  bool _resultadoMostrado = false;
  bool _esperandoNuevoNumero = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _expresion,
                      style: const TextStyle(fontSize: 24, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pantalla,
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w300,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(children: [_boton("AC"), _boton("+/-"), _boton("%"), _boton("÷")]),
            Row(children: [_boton("7"), _boton("8"), _boton("9"), _boton("x")]),
            Row(children: [_boton("4"), _boton("5"), _boton("6"), _boton("-")]),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Row(children: [_boton("1"), _boton("2"), _boton("3")]),
                        Row(children: [_boton("."), _boton("0"), _boton("=")]),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: _botonEspecial("+"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boton(String texto) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 34),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _alPresionar(texto),
          child: Text(texto, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }

  Widget _botonEspecial(String texto) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: SizedBox.expand(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _alPresionar(texto),
          child: Text(
            texto,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _alPresionar(String texto) {
    setState(() {
      if (texto == 'AC') {
        _limpiar();
        return;
      }

      if (texto == '+/-') {
        _cambiarSigno();
        return;
      }

      if (texto == '=') {
        _igual();
        return;
      }

      if (_esOperador(texto)) {
        _agregarOperador(texto);
        return;
      }

      _agregarDigito(texto);
    });
  }

  void _limpiar() {
    pantalla = '0';
    _entradaActual = '0';
    _expresion = '';
    _resultadoMostrado = false;
  }

  void _cambiarSigno() {
    if (_entradaActual == '0') return;
    if (_entradaActual.startsWith('-')) {
      _entradaActual = _entradaActual.substring(1);
    } else {
      _entradaActual = '-$_entradaActual';
    }
    pantalla = _entradaActual;
  }

  void _agregarDigito(String d) {
    if (_resultadoMostrado) _limpiar();

    if (_esperandoNuevoNumero) {
      _entradaActual = '0';
      _esperandoNuevoNumero = false;
    }

    if (d == '.' && _entradaActual.contains('.')) return;

    if (_entradaActual == '0' && d != '.') {
      _entradaActual = d;
    } else {
      _entradaActual += d;
    }

    pantalla = _entradaActual;
  }

  void _agregarOperador(String op) {
    if (_resultadoMostrado) {
      _expresion = _entradaActual;
      _resultadoMostrado = false;
    }

    if (_expresion.isEmpty) {
      _expresion = _entradaActual;
    } else if (_esperandoNuevoNumero) {
      _expresion = _expresion.substring(0, _expresion.length - 1) + op;
      return;
    } else {
      _expresion += ' $_entradaActual';
    }
    _expresion += ' $op';
    _esperandoNuevoNumero = true;
  }

  void _igual() {
    final expr = _terminaEnOperador(_expresion)
        ? '$_expresion $_entradaActual'
        : (_expresion.isEmpty ? _entradaActual : '$_expresion $_entradaActual');

    try {
      final resultado = _calc.calcular(expr);
      final texto = CalcularOperacion.formatearResultado(resultado);
      pantalla = texto;
      _entradaActual = texto;
      _expresion = '';
      _resultadoMostrado = true;
    } catch (_) {
      pantalla = 'Error';
      _entradaActual = '0';
      _expresion = '';
      _resultadoMostrado = true;
    }
  }

  bool _esOperador(String s) => ['+', '-', 'x', '÷', '%'].contains(s);
  bool _terminaEnOperador(String s) =>
      s.isNotEmpty && _esOperador(s[s.length - 1]);
}