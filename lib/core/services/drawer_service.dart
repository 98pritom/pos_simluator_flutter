/// Abstract cash drawer interface.
/// Real implementation would send signal via serial/USB port.
abstract class DrawerService {
  Future<bool> openDrawer();
  bool get isOpen;
  Stream<bool> get drawerStateStream;
}
