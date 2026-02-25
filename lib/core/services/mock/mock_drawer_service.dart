import 'dart:async';
import 'dart:developer' as dev;
import '../drawer_service.dart';
import '../../config/app_config.dart';

/// Simulator cash drawer with open/close state tracking.
class MockDrawerService implements DrawerService {
  bool _isOpen = false;
  final _stateController = StreamController<bool>.broadcast();

  @override
  bool get isOpen => _isOpen;

  @override
  Stream<bool> get drawerStateStream => _stateController.stream;

  @override
  Future<bool> openDrawer() async {
    await Future.delayed(AppConfig.mockDrawerDelay);
    _isOpen = true;
    _stateController.add(true);
    dev.log('Cash drawer OPENED', name: 'MockDrawer');

    // Auto-close after 5 seconds (simulates physical drawer closing)
    Future.delayed(const Duration(seconds: 5), () {
      if (_isOpen) {
        _isOpen = false;
        _stateController.add(false);
        dev.log('Cash drawer CLOSED (auto)', name: 'MockDrawer');
      }
    });

    return true;
  }

  void dispose() {
    _stateController.close();
  }
}
