import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/settings/settings_cubit.dart';
import '../../../../../../core/ui/responsive_layout.dart';
import '../../../../../../core/ui/settings_picker_sheet.dart';

class TextSizeTile extends StatelessWidget {
  const TextSizeTile({super.key});

  static const _labels = {
    TextSizeOption.system: 'Follow system',
    TextSizeOption.small: 'Small',
    TextSizeOption.standard: 'Default',
    TextSizeOption.large: 'Large',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final option = context.watch<SettingsCubit>().state.textSize;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing(14),
        vertical: context.spacing(6),
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(context.spacing(14)),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () => _openPicker(context, option),
        leading: Container(
          width: context.spacing(36),
          height: context.spacing(36),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(context.spacing(10)),
          ),
          child: Icon(Icons.format_size, size: context.spacing(20)),
        ),
        title: Text(
          'Text size',
          style: TextStyle(
            fontSize: context.font(15),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _labels[option]!,
          style: TextStyle(fontSize: context.font(12)),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context, TextSizeOption current) async {
    final cubit = context.read<SettingsCubit>();
    final picked = await showSettingsPicker<TextSizeOption>(
      context: context,
      title: 'Text size',
      selected: current,
      options: [
        for (final entry in _labels.entries)
          SettingsPickerOption(value: entry.key, label: entry.value),
      ],
    );
    if (picked != null) cubit.setTextSize(picked);
  }
}
