import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/backup/backup_cubit.dart';
import '../../../../../../core/ui/responsive_layout.dart';
import '../../../bloc/card_overview/card_overview_bloc.dart';

/// Uses the theme's own primary colour rather than a fixed gradient, so it
/// reads correctly in both the Warm (terracotta) and Classic (indigo)
/// variants, in either brightness.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = context.select<BackupCubit, String?>(
      (cubit) => cubit.state.account?.displayName,
    );
    final cardCount = context.select<CardOverviewBloc, int>(
      (bloc) => bloc.state.cards.length,
    );

    return Container(
      padding: EdgeInsets.all(context.spacing(16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.18)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.spacing(16)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: context.spacing(24),
            backgroundColor: scheme.onPrimary.withValues(alpha: 0.2),
            child: name != null && name.isNotEmpty
                ? Text(
                    _initialsOf(name),
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: context.font(16),
                    ),
                  )
                : Icon(Icons.person, color: scheme.onPrimary),
          ),
          SizedBox(width: context.spacing(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'Card Vault',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: context.font(20),
                  ),
                ),
                SizedBox(height: context.spacing(2)),
                Text(
                  '$cardCount ${cardCount == 1 ? 'card' : 'cards'} · app-locked',
                  style: TextStyle(
                    color: scheme.onPrimary.withValues(alpha: 0.85),
                    fontSize: context.font(12.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase());
    return letters.isEmpty ? '?' : letters.join();
  }
}
