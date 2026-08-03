import 'package:flutter/material.dart';

/// Confirmation shown in place of the swipe slider once a bill is marked paid,
/// with a way back out if it was a mistake.
class PaidSuccessBanner extends StatelessWidget {
  const PaidSuccessBanner({required this.onUndo, super.key});
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
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reminders rescheduled for next month.',
            style: TextStyle(color: Colors.green.shade700, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: onUndo,
            icon: const Icon(Icons.undo, size: 16),
            label: const Text('Mark as not paid'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }
}
