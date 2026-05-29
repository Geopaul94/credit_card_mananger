import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../../../core/ui/responsive_layout.dart';
import '../../../../../features/cards/data/services/card_scan_service.dart';
import '../../bloc/card_overview/card_overview_bloc.dart';
import '../../bloc/card_overview/card_overview_event.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _holderController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _bankController = TextEditingController();
  String _type = 'Credit';
  bool _isScanning = false;
  bool _wasScanned = false;
  bool _showCvv = false;

  late final CardScanService _scanService = sl<CardScanService>();

  @override
  void dispose() {
    _holderController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  void _saveCard() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CardOverviewBloc>().add(
      AddCardRequested(
        holderName: _holderController.text,
        cardNumber: _numberController.text,
        expiryDate: _expiryController.text,
        typeLabel: _type,
        cvv: _cvvController.text,
        bankName: _bankController.text.trim().isEmpty
            ? null
            : _bankController.text.trim(),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _scanCard() async {
    setState(() => _isScanning = true);
    try {
      final result = await _scanService.scanFromCamera();
      if (result == null || !mounted) return;

      if (!result.hasAnyField) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Couldn't read card data. Please enter manually."),
            ),
          );
        }
        return;
      }

      setState(() {
        if (result.holderName != null) _holderController.text = result.holderName!;
        if (result.cardNumber != null) _numberController.text = result.cardNumber!;
        if (result.expiryDate != null) _expiryController.text = result.expiryDate!;
        _wasScanned = true;
      });
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Card')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.contentMaxWidth),
            child: Padding(
              padding: EdgeInsets.all(context.spacing(16)),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _ScanCardButton(
                      isScanning: _isScanning,
                      onTap: _isScanning ? null : _scanCard,
                    ),
                    SizedBox(height: context.spacing(16)),
                    if (_wasScanned) ...[
                      _ReviewBanner(
                        onDismiss: () => setState(() => _wasScanned = false),
                      ),
                      SizedBox(height: context.spacing(12)),
                    ],
                    _InputField(
                      controller: _holderController,
                      label: 'Card Holder Name',
                      hint: 'Alex Joseph',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Enter holder name' : null,
                    ),
                    SizedBox(height: context.spacing(12)),
                    _InputField(
                      controller: _bankController,
                      label: 'Bank Name (optional)',
                      hint: 'HDFC Bank',
                    ),
                    SizedBox(height: context.spacing(12)),
                    _InputField(
                      controller: _numberController,
                      label: 'Card Number',
                      hint: '4532 1234 5678 9012',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                        if (digits.length < 12) return 'Enter a valid card number';
                        return null;
                      },
                    ),
                    SizedBox(height: context.spacing(12)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _InputField(
                            controller: _expiryController,
                            label: 'Expiry Date',
                            hint: 'MM/YY',
                            validator: (v) {
                              final ok = RegExp(
                                r'^(0[1-9]|1[0-2])\/\d{2}$',
                              ).hasMatch(v?.trim() ?? '');
                              return ok ? null : 'Use MM/YY format';
                            },
                          ),
                        ),
                        SizedBox(width: context.spacing(12)),
                        Expanded(
                          child: TextFormField(
                            controller: _cvvController,
                            keyboardType: TextInputType.number,
                            obscureText: !_showCvv,
                            maxLength: 4,
                            validator: (v) {
                              final d = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                              if (d.length < 3) return 'Enter CVV';
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'CVV',
                              hintText: '•••',
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  context.spacing(12),
                                ),
                              ),
                              suffixIcon: GestureDetector(
                                onTap: () =>
                                    setState(() => _showCvv = !_showCvv),
                                child: Icon(
                                  _showCvv
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.spacing(12)),
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(labelText: 'Card Type'),
                      items: const [
                        DropdownMenuItem(value: 'Credit', child: Text('Credit')),
                        DropdownMenuItem(value: 'Debit', child: Text('Debit')),
                        DropdownMenuItem(value: 'Prepaid', child: Text('Prepaid')),
                      ],
                      onChanged: (v) => setState(() => _type = v ?? 'Credit'),
                    ),
                    SizedBox(height: context.spacing(22)),
                    FilledButton.icon(
                      onPressed: _saveCard,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Card'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanCardButton extends StatelessWidget {
  const _ScanCardButton({required this.isScanning, required this.onTap});

  final bool isScanning;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      icon: isScanning
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.camera_alt_outlined),
      label: Text(isScanning ? 'Scanning…' : 'Scan Card with Camera'),
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Verify extracted data before saving.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close,
              size: 16,
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.spacing(12)),
        ),
      ),
    );
  }
}
