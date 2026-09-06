import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/theme_cubit.dart';
import '../../../../../../core/ui/responsive_layout.dart';

class ThemePickerTile extends StatelessWidget {
  const ThemePickerTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = context.watch<ThemeCubit>().state;
    final variantLabel = state.variant == AppThemeVariant.warm
        ? 'Warm'
        : 'Classic';
    final modeLabel = switch (state.mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'Follow system',
    };

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
        onTap: () => _openPicker(context),
        leading: Container(
          width: context.spacing(36),
          height: context.spacing(36),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(context.spacing(10)),
          ),
          child: Icon(Icons.palette_outlined, size: context.spacing(20)),
        ),
        title: Text(
          'Appearance',
          style: TextStyle(
            fontSize: context.font(15),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '$variantLabel · $modeLabel',
          style: TextStyle(fontSize: context.font(12)),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  void _openPicker(BuildContext context) {
    final cubit = context.read<ThemeCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: BlocBuilder<ThemeCubit, ThemeState>(
          bloc: cubit,
          builder: (sheetContext, state) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetLabel('THEME'),
              RadioGroup<AppThemeVariant>(
                groupValue: state.variant,
                onChanged: (v) => cubit.setVariant(v!),
                child: const Column(
                  children: [
                    RadioListTile<AppThemeVariant>(
                      value: AppThemeVariant.warm,
                      title: Text('Warm'),
                      subtitle: Text('Cream & terracotta'),
                    ),
                    RadioListTile<AppThemeVariant>(
                      value: AppThemeVariant.classic,
                      title: Text('Classic'),
                      subtitle: Text('Indigo'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _SheetLabel('BRIGHTNESS'),
              RadioGroup<ThemeMode>(
                groupValue: state.mode,
                onChanged: (v) => cubit.setMode(v!),
                child: const Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      title: Text('Light'),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      title: Text('Dark'),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      title: Text('Follow system'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
