import '../../domain/model/ChatUser.dart';
import '../../domain/repository/IUserRepository.dart';

class GetCurrentUserUseCase {
  final IUserRepository _repo;

  GetCurrentUserUseCase(this._repo);

  Future<ChatUser> execute() async {
    final name = await _repo.getUsername() ?? 'Anónimo';
    final ip = await _repo.getIpAddress();
    final avatar = await _repo.getAvatarPath();

    return ChatUser(name: name, ipAddress: ip, avatarPath: avatar);
  }
}