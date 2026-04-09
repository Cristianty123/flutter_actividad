import '../../domain/repository/IUserRepository.dart';

class SetUsernameUseCase {
  final IUserRepository _repo;

  SetUsernameUseCase(this._repo);

  Future<void> execute(String name) => _repo.saveUsername(name);
}