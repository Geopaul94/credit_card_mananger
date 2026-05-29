import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/ui/responsive_layout.dart';
import '../../bloc/card_overview/card_overview_bloc.dart';
import '../../bloc/card_overview/card_overview_event.dart';
import '../../bloc/card_overview/card_overview_state.dart';
import '../add_card_screen/add_card_screen.dart';
import '../../widgets/card_tile.dart';
import '../../widgets/empty_card_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _openAddCardScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CardOverviewBloc>(),
          child: const AddCardScreen(),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    context.read<CardOverviewBloc>().add(const LoadCardsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cards'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: context.spacing(16)),
            child: IconButton.filledTonal(
              onPressed: _openAddCardScreen,
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.withValues(alpha: 0.12),
              ),
              icon: const Icon(Icons.add, color: Colors.blue),
            ),
          ),
        ],
      ),
      body: BlocBuilder<CardOverviewBloc, CardOverviewState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null) {
            return Center(child: Text(state.errorMessage!));
          }

          if (state.cards.isEmpty) {
            return const EmptyCardView();
          }

          return ResponsiveContent(
            child: ListView(
              padding: EdgeInsets.all(context.spacing(16)),
              children: [
                const _HomeGreeting(),
                SizedBox(height: context.spacing(14)),
                const _ProtectionHint(),
                SizedBox(height: context.spacing(16)),
                ...state.cards.map((card) => CardTile(card: card)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProtectionHint extends StatelessWidget {
  const _ProtectionHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.spacing(14)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.spacing(12)),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock, color: Colors.blue, size: context.spacing(22)),
          SizedBox(width: context.spacing(10)),
          Expanded(
            child: Text(
              'Your card data is encrypted locally on this device.',
              style: TextStyle(fontSize: context.font(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeGreeting extends StatelessWidget {
  const _HomeGreeting();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.spacing(16)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.spacing(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back',
            style: TextStyle(color: Colors.white70, fontSize: context.font(13)),
          ),
          SizedBox(height: context.spacing(8)),
          Text(
            'Your secure card vault',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: context.font(20),
            ),
          ),
        ],
      ),
    );
  }
}
