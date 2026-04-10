import 'ui/viewmodel/SetupViewModel.dart';
import 'ui/viewmodel/DiscoveryViewModel.dart';
import 'ui/viewmodel/ChatViewModel.dart';

class AppDependencies {
  final SetupViewModel setupVm;
  final DiscoveryViewModel discoveryVm;
  final ChatViewModel chatVm;

  AppDependencies({
    required this.setupVm,
    required this.discoveryVm,
    required this.chatVm,
  });
}