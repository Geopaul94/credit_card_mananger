import 'package:flutter/material.dart';

import '../../../../../core/ui/responsive_layout.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ResponsiveContent(
        child: ListView(
          padding: EdgeInsets.all(context.spacing(16)),
          children: [
            const _ReminderHeader(),
            SizedBox(height: context.spacing(14)),
            const _ReminderTile(
              title: 'Card expiry check',
              subtitle: 'Notify me 45 days before expiry.',
            ),
            const _ReminderTile(
              title: 'Monthly review',
              subtitle: 'Review cards every first Sunday.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: context.spacing(12)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.spacing(16)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.spacing(14),
          vertical: context.spacing(6),
        ),
        leading: Container(
          width: context.spacing(38),
          height: context.spacing(38),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(context.spacing(10)),
          ),
          child: Icon(Icons.notifications_active, size: context.spacing(22)),
        ),
        title: Text(title, style: TextStyle(fontSize: context.font(16))),
        subtitle: Text(subtitle, style: TextStyle(fontSize: context.font(13))),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ReminderHeader extends StatelessWidget {
  const _ReminderHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.spacing(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacing(16)),
      ),
      child: Row(
        children: [
          Container(
            width: context.spacing(40),
            height: context.spacing(40),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(context.spacing(10)),
            ),
            child: const Icon(Icons.alarm, color: Colors.orange),
          ),
          SizedBox(width: context.spacing(12)),
          Expanded(
            child: Text(
              'Stay ahead with expiry and review reminders.',
              style: TextStyle(fontSize: context.font(14)),
            ),
          ),
        ],
      ),
    );
  }
}
