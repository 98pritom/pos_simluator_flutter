import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _taxCtrl;
  late TextEditingController _currencyCtrl;
  late TextEditingController _footerCtrl;
  late bool _simulateFailures;

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(settingsProvider.notifier);
    _taxCtrl = TextEditingController(text: notifier.taxPercent.toString());
    _currencyCtrl = TextEditingController(text: notifier.currency);
    _footerCtrl = TextEditingController(text: notifier.receiptFooter);
    _simulateFailures = notifier.simulateFailures;
  }

  @override
  void dispose() {
    _taxCtrl.dispose();
    _currencyCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final notifier = ref.read(settingsProvider.notifier);
    await notifier.updateAll({
      'tax_percent': _taxCtrl.text.trim(),
      'currency': _currencyCtrl.text.trim(),
      'receipt_footer': _footerCtrl.text.trim(),
      'simulate_payment_failures': _simulateFailures.toString(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Tax & Currency'),
            _textField('Tax Percentage (%)', _taxCtrl, keyboard: TextInputType.number),
            const SizedBox(height: 16),
            _textField('Currency Symbol', _currencyCtrl),
            const SizedBox(height: 32),
            _sectionHeader('Receipt'),
            _textField('Receipt Footer Text', _footerCtrl, maxLines: 3),
            const SizedBox(height: 32),
            _sectionHeader('Simulator'),
            SwitchListTile(
              value: _simulateFailures,
              onChanged: (v) => setState(() => _simulateFailures = v),
              title: const Text('Simulate Payment Failures',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Random ~20% failure rate on payments',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              activeThumbColor: Colors.orange,
              tileColor: const Color(0xFF16213E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('SAVE SETTINGS'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _textField(String label, TextEditingController ctrl, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF16213E),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.greenAccent),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
