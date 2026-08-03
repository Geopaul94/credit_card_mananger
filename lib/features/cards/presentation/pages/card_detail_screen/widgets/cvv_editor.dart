import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/utils/card_input.dart';
import '../../../widgets/section_card.dart';

/// Shown when no security code is stored — including on every card saved
/// before the CVV field existed.
class AddCvvRow extends StatelessWidget {
  const AddCvvRow({required this.onTap, super.key});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.lock_outline, size: 17, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CVV',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Not saved',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            PillButton(label: 'Add', color: scheme.primary, onTap: onTap),
          ],
        ),
      ),
    );
  }
}

/// What the CVV editor hands back: either a code to save, or a removal.
class CvvEdit {
  const CvvEdit.save(this.value) : remove = false;
  const CvvEdit.remove()
      : value = null,
        remove = true;

  final String? value;
  final bool remove;
}

/// Dialog for adding, changing, or clearing a card's security code.
class CvvEditorDialog extends StatefulWidget {
  const CvvEditorDialog({this.initialValue, super.key});

  /// Existing code, pre-filled for editing. Null when adding a new one.
  final String? initialValue;

  @override
  State<CvvEditorDialog> createState() => _CvvEditorDialogState();
}

class _CvvEditorDialogState extends State<CvvEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ctrl;

  bool get _isEditing => widget.initialValue != null;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final digits = _ctrl.text.replaceAll(RegExp(r'\D'), '');
    // An emptied field on an existing card means "remove it", which the
    // caller confirms before anything is discarded.
    Navigator.pop(
      context,
      digits.isEmpty ? const CvvEdit.remove() : CvvEdit.save(digits),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(_isEditing ? 'Edit CVV' : 'Add CVV'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: validateCvv,
              decoration: const InputDecoration(
                labelText: 'Security code',
                hintText: '3 digits · 4 on Amex',
                counterText: '',
              ),
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _isEditing
                        ? 'Clear the field and save to remove the stored code.'
                        : 'Stored encrypted on this device and never uploaded.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
