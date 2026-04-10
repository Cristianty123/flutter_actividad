import 'domain/repository/IUserRepository.dart';
import 'ui/viewmodel/SetupViewModel.dart';
import 'ui/viewmodel/DiscoveryViewModel.dart';
import 'ui/viewmodel/ChatViewModel.dart';

class AppDependencies {
  final SetupViewModel setupVm;
  final DiscoveryViewModel discoveryVm;
  final ChatViewModel chatVm;
  final IUserRepository userRepo; // necesario para leer el IP real en ChatScreen

  AppDependencies({
    required this.setupVm,
    required this.discoveryVm,
    required this.chatVm,
    required this.userRepo,
  });
}