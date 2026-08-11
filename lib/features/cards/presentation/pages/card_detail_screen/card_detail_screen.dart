import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/theme/card_palette.dart';
import '../../../../../core/ui/responsive_layout.dart';
import '../../../domain/entities/payment_card.dart';
import '../../bloc/card_overview/card_overview_bloc.dart';
import '../../bloc/card_overview/card_overview_event.dart';
import '../../bloc/card_overview/card_overview_state.dart';
import '../../widgets/card_tile.dart';
import '../../widgets/section_card.dart';
import '../../widgets/swipe_to_confirm.dart';
import '../edit_card_screen/edit_card_screen.dart';
import 'widgets/card_back_face.dart';
import 'widgets/cvv_editor.dart';
import 'widgets/detail_row.dart';
import 'widgets/paid_success_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
class CardDetailScreen extends StatefulWidget {
  const CardDetailScreen({required this.card, super.key});
  final PaymentCard card;

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen>
    with TickerProviderStateMixin {
  // ── Flip animation ─────────────────────────────────────────────────────────
  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;
  bool _showFront = true;

  // ── Editable card copy ─────────────────────────────────────────────────────
  late PaymentCard _card;

  // ── Reveal toggles ─────────────────────────────────────────────────────────
  bool _showNumber = false;

  // The CVV is shown plainly like every other field: the whole app already
  // sits behind a biometric lock, so a second prompt inside it only added
  // friction for the one person who owns the card.

  // ── Gradient ───────────────────────────────────────────────────────────────
  // Same source as the list tile, so a card keeps its colours when opened.
  List<Color> get _gradient => CardPalette.forCard(_card);

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _card = widget.card;

    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 580),
    );
    _flipAnim = CurvedAnimation(
      parent: _flipCtrl,
      curve: Curves.easeInOutCubic,
    );
    _flipAnim.addListener(() {
      final front = _flipAnim.value <= 0.5;
      if (front != _showFront) setState(() => _showFront = front);
    });

    // Front stays showing until the user taps the card — it used to
    // auto-flip to the back on entry, which briefly hid the number/holder
    // behind an animation nobody asked for.
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    // A short tick confirms the copy landed even if the snackbar is glanced past.
    HapticFeedback.selectionClick();
    _showSnack('$label copied');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  /// The card's fields as plain text — same set for both the "Copy" action
  /// and "Share": number, holder, expiry, and CVV if one is stored. This is
  /// everything needed to actually use the card elsewhere, so both actions
  /// carry the same weight and the same warning applies to each.
  String _detailsText() {
    final buffer = StringBuffer()
      ..writeln(_card.displayTitle)
      ..writeln('Card Number: ${_card.formattedNumber}')
      ..writeln('Card Holder: ${_card.holderName}')
      ..writeln('Expiry: ${_card.expiryDate}');
    if (_card.hasCvv) buffer.write('CVV: ${_card.cvv}');
    return buffer.toString().trim();
  }

  void _copyAllDetails() {
    Clipboard.setData(ClipboardData(text: _detailsText()));
    HapticFeedback.selectionClick();
    _showSnack('Card details copied');
  }

  /// Confirms before handing the OS share sheet a full card number and CVV —
  /// once shared there's no undo, and it's easy to tap the wrong contact.
  Future<void> _shareCard() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share full card details?'),
        content: Text(
          'This includes the full card number'
          '${_card.hasCvv ? " and CVV" : ""} for "${_card.displayTitle}". '
          'Anyone you send it to could use it — share it the way you would '
          'hand over the physical card.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Share'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    HapticFeedback.selectionClick();
    await Share.share(_detailsText(), subject: _card.displayTitle);
  }

  void _flip() {
    if (_flipCtrl.isAnimating) return;
    _flipCtrl.isDismissed ? _flipCtrl.forward() : _flipCtrl.reverse();
  }

  void _dispatch(CardOverviewEvent e) =>
      context.read<CardOverviewBloc>().add(e);

  /// Opens the edit screen and adopts the result immediately, so the card
  /// visual and details refresh without waiting for the bloc round-trip.
  Future<void> _editCard() async {
    final updated = await openEditCardScreen(context, _card);
    if (updated != null && mounted) setState(() => _card = updated);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete card?'),
        content: Text('Remove "${_card.displayTitle}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      _dispatch(DeleteCardRequested(cardId: _card.id));
      Navigator.pop(context);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocListener<CardOverviewBloc, CardOverviewState>(
      listenWhen: (prev, curr) {
        final o = prev.cards.firstWhere(
          (c) => c.id == _card.id,
          orElse: () => _card,
        );
        final n = curr.cards.firstWhere(
          (c) => c.id == _card.id,
          orElse: () => _card,
        );
        return o != n;
      },
      listener: (context, state) {
        final updated = state.cards.firstWhere(
          (c) => c.id == _card.id,
          orElse: () => _card,
        );
        setState(() => _card = updated);
      },
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(
            _card.displayTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: ResponsiveContent(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.spacing(16),
              context.spacing(8),
              context.spacing(16),
              context.spacing(40),
            ),
            children: [
              _buildCardVisual(),
              SizedBox(height: context.spacing(16)),
              _buildActionRow(scheme),
              SizedBox(height: context.spacing(24)),
              const SectionLabel(label: 'CARD DETAILS'),
              SizedBox(height: context.spacing(8)),
              _buildDetailsCard(scheme),
              SizedBox(height: context.spacing(20)),
              const SectionLabel(label: 'PAYMENT DUE DATE'),
              SizedBox(height: context.spacing(8)),
              _buildDueDateCard(scheme),
              SizedBox(height: context.spacing(20)),
              const SectionLabel(label: 'PRIVATE NOTES'),
              SizedBox(height: context.spacing(8)),
              _buildNotesCard(scheme),
              SizedBox(height: context.spacing(20)),
              if (_card.dueDay != null) _buildMarkPaidSection(scheme),
            ],
          ),
        ),
      ),
    );
  }

  // ── Card visual (flip) ────────────────────────────────────────────────────

  Widget _buildCardVisual() {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (context, _) {
          final angle = _flipAnim.value * math.pi;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: _showFront
                ? BlocSelector<CardOverviewBloc, CardOverviewState, bool>(
                    selector: (s) => s.paidCardIds.contains(_card.id),
                    builder: (context, isPaid) => CardFrontFace(
                      card: _card,
                      gradientColors: _gradient,
                      isPaid: isPaid,
                    ),
                  )
                : Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: CardBackFace(card: _card, gradientColors: _gradient),
                  ),
          );
        },
      ),
    );
  }

  // ── Action row (Copy / Edit / Share / Delete) ─────────────────────────────

  Widget _buildActionRow(ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.copy_all_outlined,
            label: 'Copy',
            onTap: _copyAllDetails,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.edit_outlined,
            label: 'Edit',
            onTap: _editCard,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: _shareCard,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: scheme.error,
            onTap: _confirmDelete,
          ),
        ),
      ],
    );
  }

  // ── Details card ──────────────────────────────────────────────────────────

  Widget _buildDetailsCard(ColorScheme scheme) {
    final digits = _card.cardNumber.replaceAll(RegExp(r'\D'), '');
    final last4 = digits.length >= 4
        ? digits.substring(digits.length - 4)
        : '****';
    final masked = '**** **** **** $last4';

    return SectionCard(
      children: [
        DetailRow(
          icon: Icons.credit_card,
          label: 'Card Number',
          value: _showNumber ? _card.formattedNumber : masked,
          onCopy: () => _copy(_card.formattedNumber, 'Card number'),
          trailing: IconBox(
            icon: _showNumber ? Icons.visibility_off : Icons.visibility,
            onTap: () => setState(() => _showNumber = !_showNumber),
          ),
        ),
        const SectionDivider(),
        DetailRow(
          icon: Icons.date_range_outlined,
          label: _card.isExpired
              ? 'Expiry · this card has expired'
              : _card.isExpiringSoon()
              ? 'Expiry · expires soon'
              : 'Expiry',
          value: _card.expiryDate,
          onCopy: () => _copy(_card.expiryDate, 'Expiry'),
          valueColor: _card.isExpired
              ? scheme.error
              : _card.isExpiringSoon()
              ? const Color(0xFFB45309) // amber-700, readable in both themes
              : null,
        ),
        const SectionDivider(),
        _buildCvvRow(scheme),
        const SectionDivider(),
        DetailRow(
          icon: Icons.person_outline,
          label: 'Card Holder',
          value: _card.holderName,
          onCopy: () => _copy(_card.holderName, 'Holder name'),
        ),
      ],
    );
  }

  /// Shows the stored code, or invites adding one. Both lead to the edit
  /// screen, which owns every field on the card.
  Widget _buildCvvRow(ColorScheme scheme) {
    if (!_card.hasCvv) return AddCvvRow(onTap: _editCard);

    return DetailRow(
      icon: Icons.lock_outline,
      label: 'CVV',
      value: _card.cvv!,
      onCopy: () => _copy(_card.cvv!, 'CVV'),
    );
  }

  // ── Due-date card (read-only; edited on the edit screen) ─────────────────

  Widget _buildDueDateCard(ColorScheme scheme) {
    return SectionCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _card.dueDay != null
                          ? 'Due on the ${_card.dueDayLabel} every month'
                          : 'No reminder set',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _card.dueDay != null
                          ? 'Evening reminders from 3 days before.'
                          : 'Add a due date to get payment reminders.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PillButton(
                label: _card.dueDay != null ? 'Change' : 'Set',
                color: scheme.primary,
                onTap: _editCard,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Notes card (read-only; edited on the edit screen) ────────────────────

  Widget _buildNotesCard(ColorScheme scheme) {
    final hasNotes = (_card.notes ?? '').trim().isNotEmpty;

    return SectionCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Private notes',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (hasNotes) ...[
                    IconBox(
                      icon: Icons.copy,
                      onTap: () => _copy(_card.notes!, 'Notes'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  PillButton(
                    label: hasNotes ? 'Change' : 'Add',
                    color: scheme.primary,
                    onTap: _editCard,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(hasNotes ? 14 : 18),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: hasNotes
                      ? null
                      : Border.all(
                          color: scheme.outline.withValues(alpha: 0.15),
                        ),
                ),
                child: Text(
                  hasNotes
                      ? _card.notes!
                      : 'Nothing saved yet. Keep a bank login ID, a customer '
                            'care number, or any reminder here.',
                  textAlign: hasNotes ? TextAlign.start : TextAlign.center,
                  style: hasNotes
                      ? Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.6)
                      : Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mark paid (swipe-to-confirm) ─────────────────────────────────────────

  Widget _buildMarkPaidSection(ColorScheme scheme) {
    return BlocBuilder<CardOverviewBloc, CardOverviewState>(
      buildWhen: (prev, curr) =>
          prev.paidCardIds.contains(_card.id) !=
          curr.paidCardIds.contains(_card.id),
      builder: (context, state) {
        final isPaid = state.paidCardIds.contains(_card.id);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel(label: 'PAYMENT STATUS'),
            SizedBox(height: context.spacing(8)),
            SectionCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: isPaid
                      ? PaidSuccessBanner(
                          onUndo: () => _dispatch(
                            MarkCardUnpaidRequested(cardId: _card.id),
                          ),
                        )
                      : SwipeToConfirm(
                          onConfirmed: () => _dispatch(
                            MarkCardPaidRequested(cardId: _card.id),
                          ),
                        ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
}

// ─── Action button ────────────────────────────────────────────────────────────

/// One button in the Copy / Edit / Share / Delete row below the card visual.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Overrides the default primary colour — used for Delete.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: tint),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: tint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
