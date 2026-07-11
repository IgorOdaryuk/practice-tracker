import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/report_view_model.dart';
import '../viewmodels/rewards_view_model.dart';
import 'practice/practice_screen.dart';
import 'report/report_screen.dart';
import 'report/rewards_screen.dart';

/// Main shell with three tabs. [IndexedStack] keeps each tab's state (a running
/// timer survives peeking at the report).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const List<Widget> _tabs = [
    PracticeScreen(),
    ReportScreen(),
    RewardsScreen(),
  ];

  void _onSelect(int index) {
    setState(() => _index = index);
    // Refresh the data a tab shows when it becomes visible.
    if (index == 1) context.read<ReportViewModel>().load();
    if (index == 2) context.read<RewardsViewModel>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onSelect,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Practice',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Rewards',
          ),
        ],
      ),
    );
  }
}
