import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/ui/responsive_layout.dart';
import '../../../domain/entities/payment_card.dart';
import '../../bloc/card_overview/card_overview_bloc.dart';
import '../../bloc/card_overview/card_overview_event.dart';
import '../../bloc/card_overview/card_overview_state.dart';
import '../../widgets/card_tile.dart';

const double _kCardHeight = 220;

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

  // ── Due-date editing ───────────────────────────────────────────────────────
  bool _isDueDayEditing = false;
  bool _useCustomDay = false;
  final _customDayCtrl = TextEditingController();
  final _customDayKey = GlobalKey<FormState>();

  // ── Notes ──────────────────────────────────────────────────────────────────
  bool _isNotesEditing = false;
  late final TextEditingController _notesCtrl;

  // ── Gradient ───────────────────────────────────────────────────────────────
  List<Color> get _gradient {
    switch (_card.typeLabel) {
      case 'Debit':
        return [const Color(0xFF7C3AED), const Color(0xFF5B21B6)];
      case 'Prepaid':
        return [const Color(0xFF059669), const Color(0xFF0D9488)];
      default:
        return [const Color(0xFF1D4ED8), const Color(0xFF4F46E5)];
    }
  }

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
    _customDayCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
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

  void _saveDueDay(int? day) {
    final updated =
        day == null ? _card.copyWith(clearDueDay: true) : _card.copyWith(dueDay: day);
    _dispatch(UpdateCardRequested(card: updated));
    setState(() {
      _card = updated;
      _isDueDayEditing = false;
      _useCustomDay = false;
      _customDayCtrl.clear();
    });
  }

  Future<void> _openCalendarPicker() async {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final safeDay = (_card.dueDay ?? now.day).clamp(1, lastDayOfMonth);
    final initial = DateTime(now.year, now.month, safeDay);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, 1),
      lastDate: DateTime(now.year, now.month, lastDayOfMonth),
      helpText: 'SELECT YOUR BILLING DUE DAY',
      confirmText: 'SET DUE DAY',
      cancelText: 'CANCEL',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            headerBackgroundColor: Theme.of(context).colorScheme.primary,
            headerForegroundColor: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) _saveDueDay(picked.day);
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
              _sectionLabel(context, 'CARD DETAILS'),
              SizedBox(height: context.spacing(8)),
              _buildDetailsCard(scheme),
              SizedBox(height: context.spacing(20)),
              _sectionLabel(context, 'PAYMENT DUE DATE'),
              SizedBox(height: context.spacing(8)),
              _buildDueDateCard(scheme),
              SizedBox(height: context.spacing(20)),
              _sectionLabel(context, 'PRIVATE NOTES'),
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
                    child: _CardBackFace(
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

    return _SectionCard(children: [
      _DetailRow(
        icon: Icons.credit_card,
        label: 'Card Number',
        value: _showNumber ? _card.formattedNumber : masked,
        onCopy: () => _copy(_card.formattedNumber, 'Card number'),
        trailing: _IconBox(
          icon: _showNumber ? Icons.visibility_off : Icons.visibility,
          onTap: () => setState(() => _showNumber = !_showNumber),
          scheme: scheme,
        ),
      ),
      _RowDivider(),
      _DetailRow(
        icon: Icons.date_range_outlined,
        label: 'Expiry',
        value: _card.expiryDate,
        onCopy: () => _copy(_card.expiryDate, 'Expiry'),
      ),
      _RowDivider(),
      _DetailRow(
        icon: Icons.person_outline,
        label: 'Card Holder',
        value: _card.holderName,
        onCopy: () => _copy(_card.holderName, 'Holder name'),
      ),
    ]);
  }

  // ── Due-date card ─────────────────────────────────────────────────────────

  Widget _buildDueDateCard(ColorScheme scheme) {
    return _SectionCard(children: [
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
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14, color: scheme.onSurface),
                ),
              ),
              _PillButton(
                label: _isDueDayEditing ? 'Cancel' : 'Edit',
                color: scheme.primary,
                onTap: () => setState(() {
                  _isDueDayEditing = !_isDueDayEditing;
                  if (!_isDueDayEditing) {
                    _useCustomDay = false;
                    _customDayCtrl.clear();
                  }
                }),
              ),
            ]),

            // Editing panel
            if (_isDueDayEditing) ...[
              const SizedBox(height: 14),

              // 📅 Calendar picker button
              GestureDetector(
                onTap: _openCalendarPicker,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text('Pick from Calendar',
                          style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Text('— or choose a quick day —',
                  style:
                      TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),

              // Quick chips
              Form(
                key: _customDayKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...[1, 5, 10, 15, 20, 25, 28].map((day) {
                          final sel = !_useCustomDay && _card.dueDay == day;
                          return GestureDetector(
                            onTap: () => _saveDueDay(day),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: sel
                                    ? scheme.primary
                                    : scheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: sel
                                        ? scheme.primary
                                        : scheme.outline.withValues(alpha: 0.2)),
                              ),
                              alignment: Alignment.center,
                              child: Text('$day',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: sel ? Colors.white : scheme.onSurface)),
                            ),
                          );
                        }),
                        // Other
                        GestureDetector(
                          onTap: () =>
                              setState(() => _useCustomDay = !_useCustomDay),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: _useCustomDay
                                  ? scheme.primary
                                  : scheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _useCustomDay
                                      ? scheme.primary
                                      : scheme.outline.withValues(alpha: 0.2)),
                            ),
                            alignment: Alignment.center,
                            child: Text('Other',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _useCustomDay
                                        ? Colors.white
                                        : scheme.onSurface)),
                          ),
                        ),
                        // No reminder
                        GestureDetector(
                          onTap: () => _saveDueDay(null),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: _card.dueDay == null
                                  ? scheme.errorContainer
                                  : scheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _card.dueDay == null
                                      ? scheme.error
                                      : scheme.outline.withValues(alpha: 0.2)),
                            ),
                            alignment: Alignment.center,
                            child: Text('No reminder',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _card.dueDay == null
                                        ? scheme.onErrorContainer
                                        : scheme.onSurface)),
                          ),
                        ),
                      ],
                    ),
                    if (_useCustomDay) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: _customDayCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Enter day (1–31)',
                              prefixIcon:
                                  const Icon(Icons.calendar_today_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            validator: (v) {
                              final d = int.tryParse(v?.trim() ?? '');
                              return (d == null || d < 1 || d > 31)
                                  ? 'Enter 1–31'
                                  : null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            if (_customDayKey.currentState!.validate()) {
                              _saveDueDay(int.parse(_customDayCtrl.text.trim()));
                            }
                          },
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                          ),
                          child: const Text('Save'),
                        ),
                      ]),
                    ],
                  ],
                ),
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

    return _SectionCard(children: [
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
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: scheme.onSurface)),
              ),
              if (!_isNotesEditing) ...[
                // Copy button (only if notes exist)
                if (hasNotes)
                  _IconBox(
                    icon: Icons.copy,
                    onTap: () => _copy(_card.notes!, 'Notes'),
                    scheme: scheme,
                  ),
                const SizedBox(width: 8),
                _PillButton(
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
                        style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: scheme.onSurface),
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
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: scheme.onSurfaceVariant),
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
            _sectionLabel(context, 'PAYMENT STATUS'),
            SizedBox(height: context.spacing(8)),
            _SectionCard(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: isPaid
                    ? _PaidSuccessBanner(
                        onUndo: () => _dispatch(
                            MarkCardUnpaidRequested(cardId: _card.id)),
                      )
                    : _SwipeToConfirm(
                        onConfirmed: () {
                          _dispatch(
                              MarkCardPaidRequested(cardId: _card.id));
                        },
                      ),
              ),
            ]),
          ],
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.primary));
  }
}

// ─── Swipe-to-confirm widget ──────────────────────────────────────────────────

class _SwipeToConfirm extends StatefulWidget {
  const _SwipeToConfirm({required this.onConfirmed});
  final VoidCallback onConfirmed;

  @override
  State<_SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<_SwipeToConfirm>
    with SingleTickerProviderStateMixin {
  static const double _thumbW = 54.0;
  static const double _trackH = 62.0;
  static const double _margin = 5.0;

  double _progress = 0.0; // 0.0 → 1.0
  bool _done = false;

  late final AnimationController _snapCtrl;
  late Animation<double> _snapAnim;

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d, double maxDrag) {
    if (_done) return;
    _snapCtrl.stop();
    setState(() {
      _progress =
          ((_progress * maxDrag) + d.delta.dx).clamp(0.0, maxDrag) / maxDrag;
    });
  }

  void _onDragEnd(DragEndDetails d, double maxDrag) {
    if (_done) return;
    if (_progress >= 0.78) {
      setState(() {
        _progress = 1.0;
        _done = true;
      });
      widget.onConfirmed();
    } else {
      // Snap back with spring
      _snapAnim = Tween<double>(begin: _progress, end: 0.0).animate(
        CurvedAnimation(parent: _snapCtrl, curve: Curves.easeOutCubic),
      )..addListener(() => setState(() => _progress = _snapAnim.value));
      _snapCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxDrag = constraints.maxWidth - _thumbW - _margin * 2;

      return GestureDetector(
        onHorizontalDragUpdate: (d) => _onDragUpdate(d, maxDrag),
        onHorizontalDragEnd: (d) => _onDragEnd(d, maxDrag),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _trackH,
          decoration: BoxDecoration(
            color: _done
                ? Colors.green.withValues(alpha: 0.15)
                : Color.lerp(
                    Colors.green.withValues(alpha: 0.06),
                    Colors.green.withValues(alpha: 0.18),
                    _progress,
                  ),
            borderRadius: BorderRadius.circular(_trackH / 2),
            border: Border.all(
              color: Color.lerp(
                Colors.green.withValues(alpha: 0.25),
                Colors.green.withValues(alpha: 0.55),
                _progress,
              )!,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Track hint text
              if (!_done)
                Opacity(
                  opacity: (1.0 - _progress * 1.8).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 50), // offset for thumb
                      Icon(Icons.check_circle_outline,
                          size: 16, color: Colors.green.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'Swipe right to mark as Paid',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

              // Draggable thumb
              if (!_done)
                Positioned(
                  left: _margin + _progress * maxDrag,
                  child: Container(
                    width: _thumbW,
                    height: _thumbW,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.lerp(Colors.green.shade400,
                              Colors.green.shade600, _progress)!,
                          Color.lerp(Colors.green.shade500,
                              Colors.green.shade800, _progress)!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(
                              alpha: 0.3 + _progress * 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _progress > 0.6
                          ? Icons.check
                          : Icons.chevron_right,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

// ─── Paid success banner ──────────────────────────────────────────────────────

class _PaidSuccessBanner extends StatelessWidget {
  const _PaidSuccessBanner({required this.onUndo});
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
          ),
          const SizedBox(height: 10),
          const Text(
            'Paid this cycle ✓',
            style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w700,
                fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Reminders rescheduled for next month.',
            style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: onUndo,
            icon: const Icon(Icons.undo, size: 16),
            label: const Text('Mark as not paid'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green.shade800,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card back face ───────────────────────────────────────────────────────────

class _CardBackFace extends StatelessWidget {
  const _CardBackFace({
    required this.card,
    required this.gradientColors,
  });

  final PaymentCard card;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: _kCardHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withValues(alpha: 0.4),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 36, color: const Color(0xFF111827)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                      3,
                      (_) => Container(height: 1, color: Colors.grey.shade300)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(children: [
                _BackInfoRow(label: 'TYPE', value: card.typeLabel),
                const SizedBox(height: 6),
                _BackInfoRow(label: 'HOLDER', value: card.holderName),
                const SizedBox(height: 6),
                _BackInfoRow(label: 'EXPIRY', value: card.expiryDate),
              ]),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Icon(Icons.touch_app_outlined,
                    size: 12, color: Colors.white.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text('tap to flip',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.5))),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackInfoRow extends StatelessWidget {
  const _BackInfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(
        width: 48,
        child: Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      ),
      Expanded(
        child: Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8)),
      ),
    ]);
  }
}

// ─── Detail row ───────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onCopy;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ]),
        ),
        if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
        _IconBox(icon: Icons.copy, onTap: onCopy, scheme: scheme),
      ]),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _IconBox extends StatelessWidget {
  const _IconBox(
      {required this.icon, required this.onTap, required this.scheme});
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 15, color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton(
      {required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
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
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class _RowDivider extends StatelessWidget {
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
