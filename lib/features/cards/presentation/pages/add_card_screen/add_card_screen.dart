import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/auth/auth_cubit.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/ui/responsive_layout.dart';
import '../../../../../core/utils/card_input.dart';
import '../../bloc/add_card/add_card_cubit.dart';
import '../../bloc/card_overview/card_overview_bloc.dart';
import '../../bloc/card_overview/card_overview_event.dart';
import '../../widgets/due_date_calendar.dart';

// ─── Route entry-point — provides a fresh AddCardCubit per open ───────────────

class AddCardScreen extends StatelessWidget {
  const AddCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AddCardCubit>(),
      child: const _AddCardView(),
    );
  }
}

// ─── Actual view — consumes AddCardCubit ─────────────────────────────────────

class _AddCardView extends StatefulWidget {
  const _AddCardView();

  @override
  State<_AddCardView> createState() => _AddCardViewState();
}

class _AddCardViewState extends State<_AddCardView> {
  final _formKey = GlobalKey<FormState>();

  // Framework objects — not app state; kept as local fields.
  final _holderCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();

  @override
  void dispose() {
    _holderCtrl.dispose();
    _bankCtrl.dispose();
    _cardNameCtrl.dispose();
    _numberCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  // ── Two-step camera scan: front, then optional back ───────────────────────

  Future<void> _runScanFlow() async {
    final cubit = context.read<AddCardCubit>();
    final auth = context.read<AuthCubit>();

    // Opening the camera backgrounds the app; mark this as a trusted
    // interruption so AuthCubit doesn't force a re-auth when we return.
    Future<bool> guarded(Future<bool> Function() op) async {
      auth.beginTrustedInterruption();
      try {
        return await op();
      } finally {
        auth.endTrustedInterruption();
      }
    }

    final gotFront = await guarded(cubit.scanFront);
    if (!mounted || !gotFront) return;

    final captureBack = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Front captured ✓'),
        content: const Text(
          'Now flip the card over and capture the back so we can read the '
          'issuing bank and card number. You can skip this step.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Skip'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.flip_camera_android_outlined, size: 18),
            label: const Text('Capture back'),
          ),
        ],
      ),
    );

    if (captureBack == true && mounted) {
      await guarded(cubit.scanBack);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveCard(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    // Blocking errors are handled by the validators above; these two are
    // legitimate-but-suspicious cases where the user decides.
    final warnings = <String>[];
    final digits = _numberCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (!luhnCheck(digits)) {
      warnings.add('The card number fails its checksum — one digit is '
          'probably mistyped.');
    }
    if (isExpiredDate(_expiryCtrl.text)) {
      warnings.add('This card expired on ${_expiryCtrl.text.trim()}.');
    }
    if (warnings.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Check card details'),
          content: Text(warnings.join('\n\n')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Fix it'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save anyway'),
            ),
          ],
        ),
      );
      if (proceed != true || !context.mounted) return;
    }

    final cubit = context.read<AddCardCubit>();

    context.read<CardOverviewBloc>().add(
          AddCardRequested(
            holderName: _holderCtrl.text,
            cardNumber: _numberCtrl.text,
            expiryDate: _expiryCtrl.text,
            typeLabel: cubit.state.cardType,
            bankName: _bankCtrl.text.trim().isEmpty
                ? null
                : _bankCtrl.text.trim(),
            cardName: _cardNameCtrl.text.trim().isEmpty
                ? null
                : _cardNameCtrl.text.trim(),
            dueDay: cubit.state.selectedDueDay,
          ),
        );
    Navigator.of(context).pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // BlocListener applies scan results to TextEditingControllers.
    // BlocBuilder drives the rest of the UI from cubit state.
    return BlocListener<AddCardCubit, AddCardState>(
      listenWhen: (prev, curr) => curr.scanResult != prev.scanResult,
      listener: (context, state) {
        final r = state.scanResult;
        if (r == null) return;
        // Only fill empty fields so a re-scan never clobbers typed-in values.
        if (r.bankName != null && _bankCtrl.text.trim().isEmpty) {
          _bankCtrl.text = r.bankName!;
        }
        if (r.cardName != null && _cardNameCtrl.text.trim().isEmpty) {
          _cardNameCtrl.text = r.cardName!;
        }
        if (r.holderName != null && _holderCtrl.text.trim().isEmpty) {
          _holderCtrl.text = r.holderName!;
        }
        if (r.cardNumber != null && _numberCtrl.text.trim().isEmpty) {
          _numberCtrl.text = r.cardNumber!;
        }
        if (r.expiryDate != null && _expiryCtrl.text.trim().isEmpty) {
          _expiryCtrl.text = r.expiryDate!;
        }
      },
      child: Scaffold(
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
                // ── Scan button ────────────────────────────────────────────
                BlocBuilder<AddCardCubit, AddCardState>(
                  buildWhen: (p, c) => p.isScanning != c.isScanning,
                  builder: (context, state) => _ScanButton(
                    isScanning: state.isScanning,
                    onTap: state.isScanning ? null : _runScanFlow,
                  ),
                ),

                // ── Scanned banner ─────────────────────────────────────────
                BlocBuilder<AddCardCubit, AddCardState>(
                  buildWhen: (p, c) => p.wasScanned != c.wasScanned,
                  builder: (context, state) {
                    if (!state.wasScanned) return const SizedBox.shrink();
                    return Column(
                      children: [
                        const SizedBox(height: 10),
                        _ScannedBanner(
                          onDismiss: () =>
                              context.read<AddCardCubit>().dismissScannedBanner(),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ── Section 1: Card Identity ───────────────────────────────
                _SectionLabel(label: 'CARD INFO'),
                const SizedBox(height: 8),
                _FormCard(children: [
                  _Field(
                    controller: _bankCtrl,
                    label: 'Bank Name',
                    hint: 'Axis Bank',
                    prefixIcon: Icons.account_balance_outlined,
                  ),
                  _Divider(),
                  _Field(
                    controller: _cardNameCtrl,
                    label: 'Card Name',
                    hint: 'Flipkart',
                    prefixIcon: Icons.badge_outlined,
                  ),
                  _Divider(),
                  _Field(
                    controller: _holderCtrl,
                    label: 'Card Holder Name',
                    hint: 'Alex Joseph',
                    prefixIcon: Icons.person_outline,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Enter holder name'
                            : null,
                  ),
                  _Divider(),
                  // Card type toggle — rebuilds only when cardType changes.
                  BlocBuilder<AddCardCubit, AddCardState>(
                    buildWhen: (p, c) => p.cardType != c.cardType,
                    builder: (context, state) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Card Type',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children:
                                  ['Credit', 'Debit', 'Prepaid'].map((t) {
                                final selected = state.cardType == t;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        right: t != 'Prepaid' ? 8 : 0),
                                    child: GestureDetector(
                                      onTap: () => context
                                          .read<AddCardCubit>()
                                          .selectType(t),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? scheme.primary
                                              : scheme.surfaceContainerHigh,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: selected
                                                ? scheme.primary
                                                : scheme.outline
                                                    .withValues(alpha: 0.2),
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
                      );
                    },
                  ),
                ]),

                const SizedBox(height: 20),

                // ── Section 2: Card Numbers ────────────────────────────────
                _SectionLabel(label: 'CARD DETAILS'),
                const SizedBox(height: 8),
                _FormCard(children: [
                  _Field(
                    controller: _numberCtrl,
                    label: 'Card Number',
                    hint: '4532 1234 5678 9012',
                    prefixIcon: Icons.credit_card,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CardNumberInputFormatter()],
                    validator: validateCardNumber,
                  ),
                  _Divider(),
                  _Field(
                    controller: _expiryCtrl,
                    label: 'Expiry',
                    hint: 'MM/YY',
                    prefixIcon: Icons.date_range_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ExpiryDateInputFormatter()],
                    validator: validateExpiry,
                  ),
                ]),

                const SizedBox(height: 20),

                // ── Section 3: Due Date ────────────────────────────────────
                _SectionLabel(label: 'PAYMENT DUE DATE'),
                const SizedBox(height: 8),

                // Rebuilds when the selected due day changes.
                BlocBuilder<AddCardCubit, AddCardState>(
                  buildWhen: (p, c) => p.selectedDueDay != c.selectedDueDay,
                  builder: (context, state) {
                    final cubit = context.read<AddCardCubit>();
                    return _FormCard(children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.notifications_outlined,
                                  size: 16, color: scheme.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  state.selectedDueDay != null
                                      ? 'Reminders on day ${state.selectedDueDay} of every month'
                                      : 'Pick the day your bill is due',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: scheme.onSurface),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 4),
                            Text(
                              "You'll get reminders 3 days before, 2 days before, the day before, and on the due date.",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                  height: 1.4),
                            ),
                            const SizedBox(height: 16),
                            DueDateCalendar(
                              selectedDay: state.selectedDueDay,
                              onSelectDay: cubit.selectDueDay,
                              onNoReminder: cubit.clearDueDay,
                            ),
                          ],
                        ),
                      ),
                    ]);
                  },
                ),

                const SizedBox(height: 28),

                // ── Save button ────────────────────────────────────────────
                FilledButton.icon(
                  onPressed: () => _saveCard(context),
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
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, size: 20),
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
              Icon(Icons.camera_alt_outlined,
                  color: scheme.primary, size: 20),
            const SizedBox(width: 10),
            Text(
              isScanning ? 'Reading card…' : 'Scan Card (front & back)',
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

// ─── Expiry input formatter ───────────────────────────────────────────────────

/// Formats expiry input as MM/YY: digits only, auto-inserts "/" once a third
/// digit is typed, capped at 4 digits. e.g. 0 → 02 → 02/9 → 02/29.
