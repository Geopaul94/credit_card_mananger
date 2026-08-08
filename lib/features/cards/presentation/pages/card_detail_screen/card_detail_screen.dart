import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/card_palette.dart';
import '../../../../../core/ui/responsive_layout.dart';
import '../../../domain/entities/payment_card.dart';
import '../../bloc/card_overview/card_overview_bloc.dart';
import '../../bloc/card_overview/card_overview_event.dart';
import '../../bloc/card_overview/card_overview_state.dart';
import '../../widgets/card_tile.dart';
import '../../widgets/due_date_calendar.dart';
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

  // ── Due-date editing ───────────────────────────────────────────────────────
  bool _isDueDayEditing = false;

  // ── Notes ──────────────────────────────────────────────────────────────────
  bool _isNotesEditing = false;
  late final TextEditingController _notesCtrl;

  // ── Gradient ───────────────────────────────────────────────────────────────
  // Same source as the list tile, so a card keeps its colours when opened.
  List<Color> get _gradient => CardPalette.forCard(_card);

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _card = widget.card;
    _notesCtrl = TextEditingController(text: _card.notes ?? '');

    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 580),
    );
    _flipAnim =
        CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic);
    _flipAnim.addListener(() {
      final front = _flipAnim.value <= 0.5;
      if (front != _showFront) setState(() => _showFront = front);
    });

    // Auto-flip to show the back after entering
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _flipCtrl.forward();
    });
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    // A short tick confirms the copy landed even if the snackbar is glanced past.
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('$label copied'),
        ]),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
  }

  // ── CVV: edit / remove ─────────────────────────────────────────────────────

  /// Adds, changes, or removes the stored security code.
  Future<void> _editCvv() async {
    final edit = await showDialog<CvvEdit>(
      context: context,
      builder: (_) => CvvEditorDialog(initialValue: _card.cvv),
    );
    if (edit == null || !mounted) return;

    if (edit.remove) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove CVV?'),
          content: const Text(
              'The security code for this card will be deleted. Everything '
              'else about the card stays as it is.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep it')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      final updated = _card.copyWith(clearCvv: true);
      _dispatch(UpdateCardRequested(card: updated));
      setState(() => _card = updated);
      _toast('CVV removed');
      return;
    }

    final updated = _card.copyWith(cvv: edit.value);
    _dispatch(UpdateCardRequested(card: updated));
    setState(() => _card = updated);
    _toast('CVV saved');
  }

  /// Short confirmation message — same look as the "copied" snackbar.
  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
  }

  void _flip() {
    if (_flipCtrl.isAnimating) return;
    _flipCtrl.isDismissed ? _flipCtrl.forward() : _flipCtrl.reverse();
  }

  void _dispatch(CardOverviewEvent e) => context.read<CardOverviewBloc>().add(e);

  void _saveNotes() {
    final updated = _card.copyWith(notes: _notesCtrl.text.trim());
    _dispatch(UpdateCardRequested(card: updated));
    setState(() {
      _card = updated;
      _isNotesEditing = false;
    });
  }

  void _cancelNotesEdit() {
    _notesCtrl.text = _card.notes ?? '';
    setState(() => _isNotesEditing = false);
  }

  /// Saves a new due day (or clears it) and leaves the picker open, so the
  /// selection is visibly confirmed and a mis-tap can be corrected at once.
  void _saveDueDay(int? day) {
    final updated = day == null
        ? _card.copyWith(clearDueDay: true)
        : _card.copyWith(dueDay: day);
    _dispatch(UpdateCardRequested(card: updated));
    HapticFeedback.selectionClick();
    setState(() => _card = updated);
  }

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
        content:
            Text('Remove "${_card.displayTitle}" permanently?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
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
        final o = prev.cards.firstWhere((c) => c.id == _card.id, orElse: () => _card);
        final n = curr.cards.firstWhere((c) => c.id == _card.id, orElse: () => _card);
        return o != n;
      },
      listener: (context, state) {
        final updated =
            state.cards.firstWhere((c) => c.id == _card.id, orElse: () => _card);
        setState(() => _card = updated);
      },
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(_card.displayTitle,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit card',
              onPressed: _editCard,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: scheme.error),
              tooltip: 'Delete card',
              onPressed: _confirmDelete,
            ),
          ],
        ),
        body: ResponsiveContent(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.spacing(16), context.spacing(8),
              context.spacing(16), context.spacing(40),
            ),
            children: [
              _buildCardVisual(),
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
                    child: CardBackFace(
                      card: _card,
                      gradientColors: _gradient,
                    ),
                  ),
          );
        },
      ),
    );
  }

  // ── Details card ──────────────────────────────────────────────────────────

  Widget _buildDetailsCard(ColorScheme scheme) {
    final digits = _card.cardNumber.replaceAll(RegExp(r'\D'), '');
    final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : '****';
    final masked = '**** **** **** $last4';

    return SectionCard(children: [
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
    ]);
  }

  /// Three states: no code stored (offer to add one), stored and hidden,
  /// stored and revealed.
  Widget _buildCvvRow(ColorScheme scheme) {
    if (!_card.hasCvv) return AddCvvRow(onTap: _editCvv);

    return DetailRow(
      icon: Icons.lock_outline,
      label: 'CVV',
      value: _card.cvv!,
      onCopy: () => _copy(_card.cvv!, 'CVV'),
      trailing:
          IconBox(icon: Icons.edit_outlined, onTap: _editCvv),
    );
  }

  // ── Due-date card ─────────────────────────────────────────────────────────

  Widget _buildDueDateCard(ColorScheme scheme) {
    return SectionCard(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(children: [
              Icon(Icons.notifications_outlined, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _card.dueDay != null
                      ? 'Due on the ${_card.dueDayLabel} every month'
                      : 'No reminder set',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              PillButton(
                label: _isDueDayEditing ? 'Done' : 'Edit',
                color: scheme.primary,
                onTap: () =>
                    setState(() => _isDueDayEditing = !_isDueDayEditing),
              ),
            ]),

            // The same picker used when adding a card, opened on the day
            // already set so changing it is a single tap.
            if (_isDueDayEditing) ...[
              const SizedBox(height: 16),
              DueDayPicker(
                selectedDay: _card.dueDay,
                onSelectDay: _saveDueDay,
                onNoReminder: () => _saveDueDay(null),
              ),
            ],
          ],
        ),
      ),
    ]);
  }

  // ── Notes card ────────────────────────────────────────────────────────────

  Widget _buildNotesCard(ColorScheme scheme) {
    final hasNotes = (_card.notes ?? '').trim().isNotEmpty;

    return SectionCard(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(children: [
              Icon(Icons.sticky_note_2_outlined, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Private notes',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              if (!_isNotesEditing) ...[
                // Copy button (only if notes exist)
                if (hasNotes)
                  IconBox(
                    icon: Icons.copy,
                    onTap: () => _copy(_card.notes!, 'Notes'),
                  ),
                const SizedBox(width: 8),
                PillButton(
                  label: 'Edit',
                  color: scheme.primary,
                  onTap: () => setState(() => _isNotesEditing = true),
                ),
              ] else ...[
                TextButton(
                  onPressed: _cancelNotesEdit,
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4)),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: _saveNotes,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ]),
            const SizedBox(height: 12),

            // View mode
            if (!_isNotesEditing)
              hasNotes
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _card.notes!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 18),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                scheme.outline.withValues(alpha: 0.15),
                            style: BorderStyle.solid),
                      ),
                      child: Text(
                        'No notes yet. Tap Edit to add bank login ID,\ncustomer care numbers, or any reminder.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ),

            // Edit mode
            if (_isNotesEditing) ...[
              TextField(
                controller: _notesCtrl,
                maxLines: 6,
                minLines: 4,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14, height: 1.6),
                decoration: InputDecoration(
                  hintText:
                      'e.g.  Login ID: user@bank.com\nCustomer care: 1800-xxx-xxxx\nPassword hint: ••••••',
                  hintStyle: TextStyle(
                      color: scheme.onSurfaceVariant, fontSize: 13, height: 1.5),
                  filled: true,
                  fillColor: scheme.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ],
        ),
      ),
    ]);
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
            SectionCard(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: isPaid
                    ? PaidSuccessBanner(
                        onUndo: () => _dispatch(
                            MarkCardUnpaidRequested(cardId: _card.id)),
                      )
                    : SwipeToConfirm(
                        onConfirmed: () =>
                            _dispatch(MarkCardPaidRequested(cardId: _card.id)),
                      ),
              ),
            ]),
          ],
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

}
