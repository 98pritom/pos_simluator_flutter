# pos_simulator_flutter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Inventory Transaction Migration

- The app now derives stock from `inventory_transactions` instead of mutating `products.stock`.
- On DB upgrade to version `2`, each existing product with legacy stock gets one backfill `restock` transaction.
- New sales, restocks, and refunds append transactions (`sale`, `restock`, `refund`) and never update stock directly.
- `products.stock` is treated as a computed UI field sourced from transaction aggregation.
