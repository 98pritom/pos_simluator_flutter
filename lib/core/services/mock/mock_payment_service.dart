import 'dart:math';
import '../payment_service.dart';
import '../../config/app_config.dart';
import '../../utils/id_generator.dart';

/// Simulator payment terminal — configurable success/failure rate.
class MockPaymentService implements PaymentService {
  /// When true, randomly fails ~20% of the time.
  bool simulateFailures;

  MockPaymentService({this.simulateFailures = false});

  @override
  Future<PaymentResult> processPayment({
    required PaymentType type,
    required double amount,
  }) async {
    await Future.delayed(AppConfig.mockPaymentDelay);

    if (simulateFailures && Random().nextDouble() < 0.2) {
      return const PaymentResult.failure('Payment declined — simulated failure');
    }

    return PaymentResult.success('TXN-${IdGenerator.generate().substring(0, 8)}');
  }

  @override
  Future<PaymentResult> refund({
    required String transactionId,
    required double amount,
  }) async {
    await Future.delayed(AppConfig.mockPaymentDelay);

    if (simulateFailures && Random().nextDouble() < 0.1) {
      return const PaymentResult.failure('Refund failed — simulated failure');
    }

    return PaymentResult.success('REF-${IdGenerator.generate().substring(0, 8)}');
  }
}
