abstract class IUserRepository {
  Future<void> saveUsername(String name);
  Future<String?> getUsername();
  Future<void> saveAvatarPath(String path);
  Future<String?> getAvatarPath();
  Future<void> saveIpAddress(String ip);
  Future<String> getIpAddress();
}