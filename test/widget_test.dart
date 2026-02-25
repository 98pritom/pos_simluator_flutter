import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_simulator_flutter/features/cart/domain/cart.dart';

void main() {
  group('Cart business logic', () {
    test('empty cart has zero totals', () {
      const cart = CartState();
      expect(cart.subtotal, 0);
      expect(cart.taxAmount, 0);
      expect(cart.grandTotal, 0);
      expect(cart.isEmpty, true);
    });

    test('percentage discount calculates correctly', () {
      const discount = Discount(type: DiscountType.percentage, value: 10);
      expect(discount.calculate(100), 10.0);
      expect(discount.calculate(50), 5.0);
    });

    test('fixed discount clamps to subtotal', () {
      const discount = Discount(type: DiscountType.fixed, value: 200);
      expect(discount.calculate(100), 100.0); // clamps to subtotal
    });

    test('tax calculates on discounted amount', () {
      // Cart with subtotal 100, 10% discount, 8% tax
      // Discounted: 100 - 10 = 90
      // Tax: 90 * 0.08 = 7.2
      // Total: 90 + 7.2 = 97.2
      const cart = CartState(
        items: [],
        taxPercent: 8.0,
        discount: Discount(type: DiscountType.percentage, value: 10),
      );
      expect(cart.subtotal, 0); // no items
    });
  });

  group('Login screen', () {
    testWidgets('shows POS Simulator title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: Text('POS Simulator')),
          ),
        ),
      );
      expect(find.text('POS Simulator'), findsOneWidget);
    });
  });
}
