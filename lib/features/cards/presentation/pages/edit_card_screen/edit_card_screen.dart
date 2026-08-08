import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/ui/responsive_layout.dart';
import '../../../../../core/utils/card_input.dart';
import '../../../domain/entities/payment_card.dart';
import '../../bloc/card_overview/card_overview_bloc.dart';
import '../../bloc/card_overview/card_overview_event.dart';
import '../../widgets/card_form_field.dart';
import '../../widgets/section_card.dart';

/// Opens the edit screen for [card], carrying the bloc across the route.
Future<PaymentCard?> openEditCardScreen(
  BuildContext context,
  PaymentCard card,
) {
  return Navigator.of(context).push<PaymentCard>(
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<CardOverviewBloc>(),
        child: EditCardScreen(card: card),
      ),
    ),
  );
}

/// Corrects a card's identity details — the fields that were previously only
/// fixable by deleting the card and adding it again, which threw away its
/// notes, due date, paid history and position.
///
/// Due date, notes and CVV are deliberately absent: each already has its own
/// editor on the detail screen, and two ways to change one value is how the
/// two drift apart.
class EditCardScreen extends StatefulWidget {
  const EditCardScreen({required this.card, super.key});
  final PaymentCard card;

  @override
  State<EditCardScreen> createState() => _EditCardScreenState();
}

class _EditCardScreenState extends State<EditCardScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _holderCtrl;
  late final TextEditingController _bankCtrl;
  late final TextEditingController _cardNameCtrl;
  late final TextEditingController _numberCtrl;
  late final TextEditingController _expiryCtrl;
  late String _cardType;

  @override
  void initState() {
    super.initState();
    final c = widget.card;
    _holderCtrl = TextEditingController(text: c.holderName);
    _bankCtrl = TextEditingController(text: c.bankName ?? '');
    _cardNameCtrl = TextEditingController(text: c.cardName ?? '');
    // Shown grouped, the way it is typed and read on the card itself.
    _numberCtrl = TextEditingController(text: c.formattedNumber);
    _expiryCtrl = TextEditingController(text: c.expiryDate);
    _cardType = c.typeLabel;
  }

  @override
  void dispose() {
    _holderCtrl.dispose();
    _bankCtrl.dispose();
    _cardNameCtrl.dispose();
    _numberCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final c = widget.card;
    return _holderCtrl.text.trim() != c.holderName ||
        _bankCtrl.text.trim() != (c.bankName ?? '') ||
        _cardNameCtrl.text.trim() != (c.cardName ?? '') ||
        _numberCtrl.text.replaceAll(RegExp(r'\D'), '') != c.cardNumber ||
        _expiryCtrl.text.trim() != c.expiryDate ||
        _cardType != c.typeLabel;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Blocking errors are handled by the validators; these two are
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
      if (proceed != true || !mounted) return;
    }

    // copyWith keeps everything this screen doesn't touch — id, due day,
    // notes, CVV and list position all survive the edit.
    final updated = widget.card.copyWith(
      holderName: _holderCtrl.text.trim(),
      cardNumber: digits,
      expiryDate: _expiryCtrl.text.trim(),
      typeLabel: _cardType,
      bankName: _bankCtrl.text.trim().isEmpty ? null : _bankCtrl.text.trim(),
      clearBankName: _bankCtrl.text.trim().isEmpty,
      cardName:
          _cardNameCtrl.text.trim().isEmpty ? null : _cardNameCtrl.text.trim(),
      clearCardName: _cardNameCtrl.text.trim().isEmpty,
    );

    HapticFeedback.lightImpact();
    context.read<CardOverviewBloc>().add(UpdateCardRequested(card: updated));
    Navigator.of(context).pop(updated);
  }

  /// Guards against losing edits to a stray back gesture.
  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits to this card will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // Captured before the await so no BuildContext crosses the gap.
        final navigator = Navigator.of(context);
        if (await _confirmDiscard()) navigator.pop();
      },
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text('Edit Card',
              style: TextStyle(fontWeight: FontWeight.w700)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ResponsiveContent(
              child: ListView(
                padding: EdgeInsets.all(context.spacing(16)),
                children: [
                  const SectionLabel(label: 'CARD INFO'),
                  const SizedBox(height: 8),
                  SectionCard(children: [
                    CardFormField(
                      controller: _bankCtrl,
                      label: 'Bank Name',
                      hint: 'Axis Bank',
                      prefixIcon: Icons.account_balance_outlined,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SectionDivider(),
                    CardFormField(
                      controller: _cardNameCtrl,
                      label: 'Card Name',
                      hint: 'Flipkart',
                      prefixIcon: Icons.badge_outlined,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SectionDivider(),
                    CardFormField(
                      controller: _holderCtrl,
                      label: 'Card Holder Name',
                      hint: 'Alex Joseph',
                      prefixIcon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter holder name'
                          : null,
                    ),
                    const SectionDivider(),
                    CardTypeSelector(
                      selected: _cardType,
                      onChanged: (t) => setState(() => _cardType = t),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  const SectionLabel(label: 'CARD DETAILS'),
                  const SizedBox(height: 8),
                  SectionCard(children: [
                    CardFormField(
                      controller: _numberCtrl,
                      label: 'Card Number',
                      hint: '4532 1234 5678 9012',
                      prefixIcon: Icons.credit_card,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CardNumberInputFormatter()],
                      validator: validateCardNumber,
                    ),
                    const SectionDivider(),
                    CardFormField(
                      controller: _expiryCtrl,
                      label: 'Expiry',
                      hint: 'MM/YY',
                      prefixIcon: Icons.date_range_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ExpiryDateInputFormatter()],
                      validator: validateExpiry,
                    ),
                  ]),

                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Due date, notes and CVV are edited on the card '
                          'screen itself.',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Changes'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
