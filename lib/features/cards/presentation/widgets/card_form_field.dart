import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A borderless text field for the card forms, designed to sit inside a
/// [SectionCard] where the panel supplies the border and the dividers separate
/// the rows. Shared by the add-card and edit-card screens so both look and
/// behave identically.
class CardFormField extends StatelessWidget {
  const CardFormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  /// Name fields open the keyboard already shifted to a capital letter, so
  /// "axis bank" doesn't have to be corrected afterwards.
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
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

/// The Credit / Debit / Prepaid selector, shared by both card forms.
class CardTypeSelector extends StatelessWidget {
  const CardTypeSelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  static const types = ['Credit', 'Debit', 'Prepaid'];

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Card Type',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant, letterSpacing: 0),
          ),
          const SizedBox(height: 10),
          Row(
            children: types.map((t) {
              final isSelected = selected == t;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: t != types.last ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => onChanged(t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? scheme.primary
                            : scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? scheme.primary
                              : scheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        t,
                        style: TextStyle(
                          color: isSelected ? Colors.white : scheme.onSurface,
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
  }
}
