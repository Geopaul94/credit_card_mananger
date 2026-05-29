import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../../../core/ui/responsive_layout.dart';
import '../../../../../features/cards/data/services/card_scan_service.dart';
import '../../bloc/card_overview/card_overview_bloc.dart';
import '../../bloc/card_overview/card_overview_event.dart';

// ─── Quick-select due days shown as chips ─────────────────────────────────────
const _quickDays = [1, 5, 10, 15, 20, 25, 28];

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _holderCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _customDayCtrl = TextEditingController();

  // State
  String _type = 'Credit';
  bool _showCvv = false;
  bool _isScanning = false;
  bool _wasScanned = false;
  int? _selectedDueDay; // null = no reminder
  bool _useCustomDay = false;

  late final _scanService = sl<CardScanService>();

  @override
  void dispose() {
    _holderCtrl.dispose();
    _bankCtrl.dispose();
    _numberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _customDayCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _saveCard() {
    if (!_formKey.currentState!.validate()) return;

    int? dueDay = _selectedDueDay;
    if (_useCustomDay) {
      dueDay = int.tryParse(_customDayCtrl.text.trim());
    }

    context.read<CardOverviewBloc>().add(
      AddCardRequested(
        holderName: _holderCtrl.text,
        cardNumber: _numberCtrl.text,
        expiryDate: _expiryCtrl.text,
        typeLabel: _type,
        cvv: _cvvCtrl.text,
        bankName: _bankCtrl.text.trim().isEmpty ? null : _bankCtrl.text.trim(),
        dueDay: dueDay,
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Couldn't read card. Please enter manually."),
        ));
        return;
      }
      setState(() {
        if (result.holderName != null) _holderCtrl.text = result.holderName!;
        if (result.cardNumber != null) _numberCtrl.text = result.cardNumber!;
        if (result.expiryDate != null) _expiryCtrl.text = result.expiryDate!;
        _wasScanned = true;
      });
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Add New Card',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(context.spacing(16)),
            children: [
              // ── Scan button ──────────────────────────────────────────────
              _ScanButton(isScanning: _isScanning, onTap: _isScanning ? null : _scanCard),
              if (_wasScanned) ...[
                const SizedBox(height: 10),
                _ScannedBanner(onDismiss: () => setState(() => _wasScanned = false)),
              ],
              const SizedBox(height: 20),

              // ── Section 1: Card Identity ──────────────────────────────────
              _SectionLabel(label: 'CARD INFO'),
              const SizedBox(height: 8),
              _FormCard(children: [
                _Field(
                  controller: _bankCtrl,
                  label: 'Bank Name',
                  hint: 'HDFC Bank',
                  prefixIcon: Icons.account_balance_outlined,
                ),
                _Divider(),
                _Field(
                  controller: _holderCtrl,
                  label: 'Card Holder Name',
                  hint: 'Alex Joseph',
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter holder name' : null,
                ),
                _Divider(),
                // Card type toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Card Type',
                          style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 10),
                      Row(
                        children: ['Credit', 'Debit', 'Prepaid'].map((t) {
                          final selected = _type == t;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  right: t != 'Prepaid' ? 8 : 0),
                              child: GestureDetector(
                                onTap: () => setState(() => _type = t),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? scheme.primary
                                        : scheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected
                                          ? scheme.primary
                                          : scheme.outline.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    t,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : scheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // ── Section 2: Card Numbers ───────────────────────────────────
              _SectionLabel(label: 'CARD DETAILS'),
              const SizedBox(height: 8),
              _FormCard(children: [
                _Field(
                  controller: _numberCtrl,
                  label: 'Card Number',
                  hint: '4532 1234 5678 9012',
                  prefixIcon: Icons.credit_card,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final d = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                    return d.length < 12 ? 'Enter a valid card number' : null;
                  },
                ),
                _Divider(),
                Row(children: [
                  Expanded(
                    child: _Field(
                      controller: _expiryCtrl,
                      label: 'Expiry',
                      hint: 'MM/YY',
                      prefixIcon: Icons.date_range_outlined,
                      validator: (v) =>
                          RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(v?.trim() ?? '')
                              ? null
                              : 'MM/YY',
                      noBorder: true,
                    ),
                  ),
                  Container(width: 1, height: 56, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)),
                  Expanded(
                    child: _CvvField(
                      controller: _cvvCtrl,
                      showCvv: _showCvv,
                      onToggle: () => setState(() => _showCvv = !_showCvv),
                    ),
                  ),
                ]),
              ]),

              const SizedBox(height: 20),

              // ── Section 3: Due Date ───────────────────────────────────────
              _SectionLabel(label: 'PAYMENT DUE DATE'),
              const SizedBox(height: 8),
              _FormCard(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.notifications_outlined,
                            size: 16, color: scheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Bill due every month on the…',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: scheme.onSurface),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        'You\'ll get reminders 3 days before, 2 days before, the day before, and on the due date.',
                        style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                            height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      // Quick-select day chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._quickDays.map((day) {
                            final sel = !_useCustomDay && _selectedDueDay == day;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedDueDay = day;
                                _useCustomDay = false;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: sel ? scheme.primary : scheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: sel ? scheme.primary : scheme.outline.withValues(alpha: 0.2),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: sel ? Colors.white : scheme.onSurface,
                                  ),
                                ),
                              ),
                            );
                          }),
                          // Custom chip
                          GestureDetector(
                            onTap: () => setState(() {
                              _useCustomDay = true;
                              _selectedDueDay = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: _useCustomDay ? scheme.primary : scheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _useCustomDay ? scheme.primary : scheme.outline.withValues(alpha: 0.2),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Other',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: _useCustomDay ? Colors.white : scheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          // No reminder chip
                          GestureDetector(
                            onTap: () => setState(() {
                              _selectedDueDay = null;
                              _useCustomDay = false;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: (!_useCustomDay && _selectedDueDay == null)
                                    ? scheme.errorContainer
                                    : scheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (!_useCustomDay && _selectedDueDay == null)
                                      ? scheme.error
                                      : scheme.outline.withValues(alpha: 0.2),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'No reminder',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: (!_useCustomDay && _selectedDueDay == null)
                                      ? scheme.onErrorContainer
                                      : scheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Custom day input
                      if (_useCustomDay) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _customDayCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Enter day (1–31)',
                            prefixIcon: const Icon(Icons.calendar_today_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          validator: _useCustomDay
                              ? (v) {
                                  final d = int.tryParse(v?.trim() ?? '');
                                  if (d == null || d < 1 || d > 31) {
                                    return 'Enter a day between 1 and 31';
                                  }
                                  return null;
                                }
                              : null,
                        ),
                      ],
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ]),

              const SizedBox(height: 28),

              // ── Save button ───────────────────────────────────────────────
              FilledButton.icon(
                onPressed: _saveCard,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Card'),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.noBorder = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool noBorder;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, size: 20),
        border: noBorder ? InputBorder.none : InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _CvvField extends StatelessWidget {
  const _CvvField({
    required this.controller,
    required this.showCvv,
    required this.onToggle,
  });

  final TextEditingController controller;
  final bool showCvv;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: !showCvv,
      maxLength: 4,
      validator: (v) {
        final d = v?.replaceAll(RegExp(r'\D'), '') ?? '';
        return d.length < 3 ? 'Enter CVV' : null;
      },
      decoration: InputDecoration(
        labelText: 'CVV',
        hintText: '•••',
        counterText: '',
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            showCvv ? Icons.visibility_off : Icons.visibility,
            size: 20,
          ),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.isScanning, required this.onTap});
  final bool isScanning;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primary.withValues(alpha: 0.12),
              scheme.secondary.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: scheme.primary.withValues(alpha: 0.35), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isScanning)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: scheme.primary),
              )
            else
              Icon(Icons.camera_alt_outlined, color: scheme.primary, size: 20),
            const SizedBox(width: 10),
            Text(
              isScanning ? 'Scanning card…' : 'Scan Card with Camera',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.primary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannedBanner extends StatelessWidget {
  const _ScannedBanner({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(Icons.check_circle_outline,
            size: 16, color: scheme.onTertiaryContainer),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Card scanned — please verify before saving.',
            style: TextStyle(
                fontSize: 12, color: scheme.onTertiaryContainer),
          ),
        ),
        GestureDetector(
          onTap: onDismiss,
          child: Icon(Icons.close,
              size: 15, color: scheme.onTertiaryContainer),
        ),
      ]),
    );
  }
}
