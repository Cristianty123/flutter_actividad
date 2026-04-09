import 'package:flutter/material.dart';
import '../component/P5ErrorDialog.dart';
import '../service/AuthService.dart';
import '../transitions/P5Transitions.dart';
import '../component/P5AnimatedButton.dart'; // IMPORTA TU NUEVO COMPONENTE
import 'ConnectionStatus.dart';
import 'HomeScreen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleRegister() async {
    String user = _userController.text.trim();
    String pass = _passController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      P5ErrorDialog.show(context, "Alert", "Los campos no pueden estar vacíos");
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authService.register(user, pass);
    setState(() => _isLoading = false);

    if (result['success']) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("BIENVENIDO, PHANTOM THIEF"), backgroundColor: Colors.red));
      Navigator.pushReplacement(context, P5Transitions.createRoute(HomeScreen(username: user)));
    } else {
      P5ErrorDialog.show(context, "System Error", result['message']);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
          actions: const [ConnectionStatus()]
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 80,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: ClipPath(
                  clipper: RegisterJaggedClipper(),
                  child: Container(width: MediaQuery.of(context).size.width * 0.8, height: 550, color: Colors.white),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _collageTitle("SIGN UP"),
                    const SizedBox(height: 50),
                    _p5TextField("NEW USERNAME", _userController, angle: -0.03),
                    const SizedBox(height: 25),
                    _p5TextField("NEW PASSWORD", _passController, isObscure: true, angle: 0.02),
                    const SizedBox(height: 60),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.red))
                        : P5AnimatedButton(
                      label: "CREAR CUENTA",
                      onTap: _handleRegister,
                      angle: -0.05,
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

  Widget _collageTitle(String text) {
    return Transform.rotate(
      angle: 0.05,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: const BoxDecoration(color: Color(0xFFD32F2F), boxShadow: [BoxShadow(color: Colors.black, offset: Offset(8, 8))]),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 45, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _p5TextField(String hint, TextEditingController controller, {bool isObscure = false, double angle = 0.0}) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: const BoxDecoration(color: Color(0xFFD32F2F), boxShadow: [BoxShadow(color: Colors.black45, offset: Offset(4, 4))]),
        child: TextField(
          controller: controller,
          obscureText: isObscure,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(hintText: hint, border: InputBorder.none, hintStyle: const TextStyle(color: Colors.white70)),
        ),
      ),
    );
  }
}

class RegisterJaggedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width * 0.2, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.9);
    path.lineTo(size.width * 0.4, size.height);
    path.lineTo(size.width * 0.1, size.height * 0.7);
    path.lineTo(0, size.height * 0.8);
    path.close();
    return path;
  }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}