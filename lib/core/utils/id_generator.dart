import 'package:uuid/uuid.dart';

/// Centralized ID generation — swap implementation if needed later.
class IdGenerator {
  static const _uuid = Uuid();

  static String generate() => _uuid.v4();

  static String orderId() => 'ORD-${DateTime.now().millisecondsSinceEpoch}';
}
