enum PaymentType { cash, card, qr }

/// Result of a payment attempt.
class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    this.transactionId,
    this.errorMessage,
  });

  const PaymentResult.success(String txnId)
      : success = true,
        transactionId = txnId,
        errorMessage = null;

  const PaymentResult.failure(String error)
      : success = false,
        transactionId = null,
        errorMessage = error;
}

/// Abstract payment terminal interface.
/// Real implementation would integrate with payment gateway SDK.
abstract class PaymentService {
  Future<PaymentResult> processPayment({
    required PaymentType type,
    required double amount,
  });

  Future<PaymentResult> refund({
    required String transactionId,
    required double amount,
  });
}
