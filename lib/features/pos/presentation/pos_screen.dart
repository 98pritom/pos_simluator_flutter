import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/presentation/product_providers.dart';
import '../../products/presentation/product_widgets.dart';
import '../../products/domain/product.dart';
import '../../cart/presentation/cart_panel.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../orders/presentation/orders_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../payments/presentation/checkout_dialog.dart';
import '../../../core/services/mock/mock_scanner_service.dart';
import '../../../core/services/mock/mock_drawer_service.dart';
import '../../../core/utils/id_generator.dart';

// Scanner provider — shared mock instance
final scannerServiceProvider = Provider<MockScannerService>((ref) => MockScannerService());

// Drawer state provider for UI indicator
final drawerOpenProvider = StreamProvider<bool>((ref) {
  final drawer = MockDrawerService();
  return drawer.drawerStateStream;
});

/// Main POS screen — split layout: products left, cart right.
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _barcodeController = TextEditingController();
  final _barcodeFocusNode = FocusNode();
  StreamSubscription<String>? _scannerSub;

  @override
  void initState() {
    super.initState();

    // Load settings & set tax
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsNotifier = ref.read(settingsProvider.notifier);
      settingsNotifier.load().then((_) {
        ref.read(cartProvider.notifier).initWithTax(settingsNotifier.taxPercent);
      });
    });

    // Listen to scanner barcode stream
    final scanner = ref.read(scannerServiceProvider);
    _scannerSub = scanner.barcodeStream.listen(_onBarcodeScanned);
  }

  @override
  void dispose() {
    _scannerSub?.cancel();
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeScanned(String barcode) async {
    final repo = ref.read(productRepositoryProvider);
    final product = await repo.getByBarcode(barcode);

    if (product != null) {
      ref.read(cartProvider.notifier).addProduct(product);
      _barcodeController.clear();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product not found: $barcode'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onBarcodeSubmit(String value) {
    if (value.trim().isEmpty) return;
    final scanner = ref.read(scannerServiceProvider);
    scanner.manualScan(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final productsAsync = ref.watch(categoryFilteredProductsProvider);
    final categories = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(productSearchQueryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Column(
        children: [
          // Top bar
          _buildTopBar(user),

          // Main content
          Expanded(
            child: Row(
              children: [
                // LEFT: Products panel (~65% width)
                Expanded(
                  flex: 65,
                  child: Column(
                    children: [
                      // Search + barcode input
                      _buildSearchBar(searchQuery),

                      // Category chips
                      _buildCategoryChips(categories, selectedCategory),

                      // Product grid
                      Expanded(
                        child: productsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(
                            child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
                          ),
                          data: (products) => _buildProductGrid(products),
                        ),
                      ),
                    ],
                  ),
                ),

                // RIGHT: Cart panel (~35% width)
                Expanded(
                  flex: 35,
                  child: CartPanel(
                    onCheckout: () => _showCheckout(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF16213E),
      child: Row(
        children: [
          const Icon(Icons.point_of_sale, color: Colors.greenAccent, size: 28),
          const SizedBox(width: 10),
          const Text(
            'POS Simulator',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),

          // Barcode input field (scanner simulator)
          SizedBox(
            width: 220,
            height: 38,
            child: TextField(
              controller: _barcodeController,
              focusNode: _barcodeFocusNode,
              onSubmitted: _onBarcodeSubmit,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Scan barcode...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                prefixIcon: const Icon(Icons.qr_code_scanner, color: Colors.greenAccent, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User info
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: user.isAdmin ? Colors.orange.shade900 : Colors.blue.shade900,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                user.isAdmin ? 'ADMIN' : 'CASHIER',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(user.name, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
          const SizedBox(width: 8),

          // Navigation buttons
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white70),
            tooltip: 'Orders',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
          ),
          if (user?.isAdmin == true)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70),
              tooltip: 'Settings',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                // Refresh tax after settings change
                final notifier = ref.read(settingsProvider.notifier);
                ref.read(cartProvider.notifier).initWithTax(notifier.taxPercent);
              },
            ),

          // Admin: add product
          if (user?.isAdmin == true)
            IconButton(
              icon: const Icon(Icons.add_box, color: Colors.white70),
              tooltip: 'Add Product',
              onPressed: () => _showAddProduct(context),
            ),

          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              ref.read(currentUserProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(String searchQuery) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        onChanged: (v) => ref.read(productSearchQueryProvider.notifier).state = v,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search products by name or barcode...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF16213E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(AsyncValue<List<String>> categories, String? selected) {
    return SizedBox(
      height: 50,
      child: categories.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (cats) => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _categoryChip('All', selected == null, () {
              ref.read(selectedCategoryProvider.notifier).state = null;
            }),
            ...cats.map((cat) => _categoryChip(cat, selected == cat, () {
              ref.read(selectedCategoryProvider.notifier).state = cat;
            })),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.greenAccent.shade700,
        backgroundColor: const Color(0xFF16213E),
        labelStyle: TextStyle(
          color: selected ? Colors.black : Colors.white70,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    if (products.isEmpty) {
      return const Center(
        child: Text('No products found', style: TextStyle(color: Colors.white38, fontSize: 16)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductGridCard(
          product: product,
          onTap: () => ref.read(cartProvider.notifier).addProduct(product),
        );
      },
    );
  }

  void _showCheckout(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CheckoutDialog(),
    );
  }

  Future<void> _showAddProduct(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const ProductEditDialog(),
    );

    if (result != null) {
      final repo = ref.read(productRepositoryProvider);
      final now = DateTime.now();
      final product = Product(
        id: IdGenerator.generate(),
        name: result['name'] as String,
        price: result['price'] as double,
        barcode: result['barcode'] as String?,
        category: result['category'] as String,
        stock: result['stock'] as int,
        createdAt: now,
        updatedAt: now,
      );
      await repo.insert(product);
      ref.invalidate(productListProvider);
      ref.invalidate(filteredProductsProvider);
      ref.invalidate(categoryFilteredProductsProvider);
      ref.invalidate(categoriesProvider);
    }
  }
}
