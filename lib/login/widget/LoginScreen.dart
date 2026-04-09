import 'package:flutter/material.dart';
import '../component/P5ErrorDialog.dart';
import '../service/AuthService.dart';
import '../transitions/P5Transitions.dart';
import '../component/P5AnimatedButton.dart';
import '../component/P5SecondaryButton.dart'; // IMPORTA EL NUEVO
import 'ConnectionStatus.dart';
import 'HomeScreen.dart';
import 'RegisterScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    final result = await _authService.login(
      _userController.text.trim(),
      _passController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (result['success']) {
      Navigator.pushReplacement(
        context,
        P5Transitions.createRoute(HomeScreen(username: _userController.text)),
      );
    } else {
      P5ErrorDialog.show(context, "System Error", result['message']);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, actions: const [ConnectionStatus()]),
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 80,
          child: Stack(
            children: [
              ClipPath(
                clipper: JaggedClipper(),
                child: Container(width: double.infinity, height: 500, color: const Color(0xFFD32F2F)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _p5Title("LOG IN"),
                    const SizedBox(height: 60),
                    _p5Input("USER NAME", _userController, angle: 0.02),
                    const SizedBox(height: 20),
                    _p5Input("PASSWORD", _passController, isObscure: true, angle: -0.01),
                    const SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // AQUÍ ESTÁ TU BOTÓN BLANCO BONITO
                        P5SecondaryButton(
                          label: "CREAR CUENTA",
                          onTap: () => Navigator.of(context).push(P5Transitions.createRoute(const RegisterScreen())),
                          angle: 0.08,
                        ),

                        _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : P5AnimatedButton(
                          label: "INICIAR SESIÓN",
                          onTap: _handleLogin,
                          angle: -0.05,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _p5Title(String text) {
    return Transform.rotate(
      angle: -0.1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.white, width: 3)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 45, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _p5Input(String hint, TextEditingController controller, {bool isObscure = false, double angle = 0.0}) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        color: Colors.white,
        child: TextField(
          controller: controller,
          obscureText: isObscure,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.all(15), border: InputBorder.none, hintStyle: TextStyle(color: Colors.grey[600])),
        ),
      ),
    );
  }
}

class JaggedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.4, size.height * 0.85);
    path.lineTo(size.width * 0.7, size.height * 0.65);
    path.lineTo(size.width, size.height * 0.8);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}