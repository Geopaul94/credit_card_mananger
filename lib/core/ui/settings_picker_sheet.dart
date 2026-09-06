import 'package:flutter/material.dart';

/// One selectable choice inside a [showSettingsPicker] sheet.
class SettingsPickerOption<T> {
  const SettingsPickerOption({
    required this.value,
    required this.label,
    this.subtitle,
  });

  final T value;
  final String label;
  final String? subtitle;
}

/// A rounded bottom sheet listing radio-style options, shared by every
/// settings row that picks one value from a small fixed set (theme variant,
/// theme mode, text size, lock delay). Returns the picked value, or null if
/// dismissed without a change.
Future<T?> showSettingsPicker<T>({
  required BuildContext context,
  required String title,
  required List<SettingsPickerOption<T>> options,
  required T selected,
}) {
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: scheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          RadioGroup<T>(
            groupValue: selected,
            onChanged: (v) => Navigator.pop(sheetContext, v),
            child: Column(
              children: [
                for (final option in options)
                  RadioListTile<T>(
                    value: option.value,
                    title: Text(option.label),
                    subtitle: option.subtitle != null
                        ? Text(option.subtitle!)
                        : null,
                    activeColor: scheme.primary,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
