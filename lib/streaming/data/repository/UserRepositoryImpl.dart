import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repository/IUserRepository.dart';

class UserRepositoryImpl implements IUserRepository {
  static const _keyName = 'username';
  static const _keyAvatar = 'avatar_path';
  static const _keyIp = 'ip_address';

  @override
  Future<void> saveUsername(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
  }

  @override
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  @override
  Future<void> saveAvatarPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAvatar, path);
  }

  @override
  Future<String?> getAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAvatar);
  }

  @override
  Future<void> saveIpAddress(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyIp, ip);
  }

  @override
  Future<String> getIpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyIp) ?? '';
  }
}