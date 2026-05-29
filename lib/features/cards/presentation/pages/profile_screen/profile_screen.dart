import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/theme_cubit.dart';
import '../../../../../core/ui/responsive_layout.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ResponsiveContent(
        child: ListView(
          padding: EdgeInsets.all(context.spacing(16)),
          children: [
            const _ProfileHeader(),
            SizedBox(height: context.spacing(14)),
            const _ThemeModeTile(),
            SizedBox(height: context.spacing(10)),
            _ProfileTile(
              icon: Icons.security,
              title: 'App lock',
              subtitle: 'Biometric or PIN protection',
            ),
            Divider(height: context.spacing(12)),
            _ProfileTile(
              icon: Icons.remove_red_eye,
              title: 'Mask card numbers',
              subtitle: 'Always enabled for safety',
            ),
            Divider(height: context.spacing(12)),
            _ProfileTile(
              icon: Icons.privacy_tip,
              title: 'Privacy',
              subtitle: 'No CVV storage, encrypted local data',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
        leading: Container(
          width: context.spacing(36),
          height: context.spacing(36),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(context.spacing(10)),
          ),
          child: Icon(icon, size: context.spacing(20)),
        ),
        title: Text(title, style: TextStyle(fontSize: context.font(16))),
        subtitle: Text(subtitle, style: TextStyle(fontSize: context.font(13))),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing(14),
        vertical: context.spacing(10),
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(context.spacing(14)),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('Dark theme', style: TextStyle(fontSize: context.font(16))),
        subtitle: Text(
          isDark ? 'Enabled for low-light use' : 'Switch to dark appearance',
          style: TextStyle(fontSize: context.font(13)),
        ),
        secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
        value: isDark,
        onChanged: (value) => context.read<ThemeCubit>().setDarkMode(value),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.spacing(16)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.spacing(16)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: context.spacing(24),
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          SizedBox(width: context.spacing(12)),
          Expanded(
            child: Text(
              'Security preferences',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: context.font(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
