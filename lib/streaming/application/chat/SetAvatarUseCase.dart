import '../../domain/repository/IUserRepository.dart';

class SetAvatarUseCase {
  final IUserRepository _repo;

  SetAvatarUseCase(this._repo);

  Future<void> execute(String path) => _repo.saveAvatarPath(path);
}