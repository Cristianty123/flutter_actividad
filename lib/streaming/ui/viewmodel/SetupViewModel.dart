import 'package:flutter/material.dart';
import '../../application/chat/SetUsernameUseCase.dart';
import '../../application/chat/SetAvatarUseCase.dart';

class SetupViewModel extends ChangeNotifier {
  final SetUsernameUseCase _setUsername;
  final SetAvatarUseCase _setAvatar;

  SetupViewModel(this._setUsername, this._setAvatar);

  bool isLoading = false;
  String? errorMessage;

  Future<bool> saveSetup({
    required String name,
    String? avatarPath,
  }) async {
    if (name.trim().isEmpty) {
      errorMessage = 'El nombre no puede estar vacío';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _setUsername.execute(name.trim());
      if (avatarPath != null) {
        await _setAvatar.execute(avatarPath);
      }
      return true;
    } catch (e) {
      errorMessage = 'Error al guardar: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}