import 'package:flutter/material.dart';
import '../component/P5ErrorDialog.dart';
import '../service/AuthService.dart';
import '../service/BiometricService.dart';
import '../service/database/DatabaseHelper.dart';
import '../transitions/P5Transitions.dart';
import '../component/P5AnimatedButton.dart';
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
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isLoading = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await BiometricService.isAvailable();
    setState(() => _biometricAvailable = available);
  }

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

    if (!result['success']) {
      P5ErrorDialog.show(context, "System Error", result['message']);
      return;
    }

    // ── Registro exitoso: ofrecer vincular biometría ──
    if (_biometricAvailable && mounted) {
      await _showBiometricEnrollmentDialog(user);
    } else {
      _goToHome(user);
    }
  }

  /// Muestra el diálogo de vinculación biométrica al estilo P5
  Future<void> _showBiometricEnrollmentDialog(String username) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Biometric",
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        );
      },
      pageBuilder: (dialogContext, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(dialogContext).size.width * 0.85,
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabecera
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFFD32F2F),
                  child: const Text(
                    "VINCULAR CARA",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                // Icono de cara
                const Padding(
                  padding: EdgeInsets.only(top: 30, bottom: 10),
                  child: Icon(Icons.face_retouching_natural, size: 80, color: Colors.white),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    "¿DESEAS VINCULAR TU CARA PARA FUTUROS INICIOS DE SESIÓN?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                // Botones
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Saltar
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _goToHome(username);
                        },
                        child: const Text(
                          "SALTAR",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      // Vincular cara
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: const BeveledRectangleBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.face_unlock_outlined),
                        label: const Text(
                          "VINCULAR",
                          style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                        ),
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await _enrollBiometric(username);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _enrollBiometric(String username) async {
    final result = await BiometricService.authenticate(
      reason: "Escanea tu cara para vincularla a tu cuenta en Lab Login",
    );

    if (result['success']) {
      // Guardamos la flag en la DB local
      await _dbHelper.enableBiometric(username);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ CARA VINCULADA EXITOSAMENTE"),
            backgroundColor: Color(0xFFD32F2F),
          ),
        );
      }
    } else {
      if (mounted) {
        P5ErrorDialog.show(context, "Biometría", result['message']);
      }
    }

    _goToHome(username);
  }

  void _goToHome(String username) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("BIENVENIDO, PHANTOM THIEF"), backgroundColor: Colors.red),
    );
    Navigator.pushReplacement(
      context,
      P5Transitions.createRoute(HomeScreen(username: username)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [ConnectionStatus()],
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
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 550,
                    color: Colors.white,
                  ),
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

                    // Badge informativo de biometría
                    if (_biometricAvailable)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Transform.rotate(
                          angle: 0.03,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(color: const Color(0xFFD32F2F), width: 2),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.face_retouching_natural, color: Color(0xFFD32F2F), size: 16),
                                SizedBox(width: 8),
                                Text(
                                  "SE PEDIRÁ VINCULAR TU CARA",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),
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
        decoration: const BoxDecoration(
          color: Color(0xFFD32F2F),
          boxShadow: [BoxShadow(color: Colors.black, offset: Offset(8, 8))],
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 45, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _p5TextField(String hint, TextEditingController controller,
      {bool isObscure = false, double angle = 0.0}) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: const BoxDecoration(
          color: Color(0xFFD32F2F),
          boxShadow: [BoxShadow(color: Colors.black45, offset: Offset(4, 4))],
        ),
        child: TextField(
          controller: controller,
          obscureText: isObscure,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.white70),
          ),
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

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}