import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../AppDependencies.dart';
import '../theme/P5Theme.dart';
import 'DiscoveryScreen.dart';

class SetupScreen extends StatefulWidget {
  final AppDependencies deps;
  const SetupScreen({super.key, required this.deps});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _controller = TextEditingController();
  String? _avatarPath;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _avatarPath = picked.path);
    }
  }

  Future<void> _continue() async {
    final ok = await widget.deps.setupVm.saveSetup(
      name: _controller.text,
      avatarPath: _avatarPath,
    );
    if (ok && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DiscoveryScreen(deps: widget.deps),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPersonaBlack,
      body: Stack(
        children: [
          // Fondo con splash de color rojo esquina superior
          Positioned(
            top: 0, left: 0, right: 0,
            child: ClipPath(
              clipper: _P5TopClipper(),
              child: Container(height: 280, color: kPersonaRed),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Título estilo P5 inclinado
                  Transform.rotate(
                    angle: -0.05,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: kPersonaBlack,
                      child: const Text(
                        'PHANTOM\nTHIEF ID',
                        style: TextStyle(
                          color: kPersonaWhite,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Avatar picker
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: kPersonaRed,
                              border: Border.all(
                                  color: kPersonaWhite, width: 3),
                            ),
                            child: _avatarPath != null
                                ? Image.file(File(_avatarPath!),
                                fit: BoxFit.cover)
                                : const Icon(Icons.person,
                                color: kPersonaWhite, size: 50),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              color: kPersonaWhite,
                              child: const Icon(Icons.camera_alt,
                                  color: kPersonaBlack, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'ELIGE TU FOTO',
                      style: TextStyle(
                        color: kPersonaWhite,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Label del campo
                  const Text(
                    'CODE NAME',
                    style: TextStyle(
                      color: kPersonaRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Input estilo P5: fondo blanco, texto negro, inclinado
                  Transform.rotate(
                    angle: 0.01,
                    child: Container(
                      decoration: BoxDecoration(
                        color: kPersonaWhite,
                        border: Border.all(color: kPersonaBlack, width: 3),
                        boxShadow: const [
                          BoxShadow(
                              color: kPersonaRed, offset: Offset(4, 4))
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(
                          color: kPersonaBlack,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'ej. Joker',
                          hintStyle: TextStyle(color: Colors.grey),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  // Error
                  ListenableBuilder(
                    listenable: widget.deps.setupVm,
                    builder: (_, __) {
                      if (widget.deps.setupVm.errorMessage == null) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          widget.deps.setupVm.errorMessage!,
                          style: const TextStyle(color: kPersonaRed),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // Botón CONTINUAR estilo P5
                  ListenableBuilder(
                    listenable: widget.deps.setupVm,
                    builder: (_, __) {
                      return GestureDetector(
                        onTap: widget.deps.setupVm.isLoading ? null : _continue,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Transform.rotate(
                            angle: -0.03,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              decoration: BoxDecoration(
                                color: kPersonaRed,
                                border: Border.all(
                                    color: kPersonaWhite, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                      color: kPersonaWhite,
                                      offset: Offset(4, 4))
                                ],
                              ),
                              child: widget.deps.setupVm.isLoading
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: kPersonaWhite,
                                    strokeWidth: 2),
                              )
                                  : const Text(
                                'LET\'S GO',
                                style: TextStyle(
                                  color: kPersonaWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _P5TopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(size.width, 0);
    p.lineTo(size.width, size.height * 0.7);
    p.lineTo(size.width * 0.6, size.height * 0.9);
    p.lineTo(0, size.height * 0.75);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(_) => false;
}