import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'history_screen.dart';
import '../stats/stats_screen.dart';

/// Wrapper de la tab "Actividad" — aloja Historial y Turno como sub-tabs.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // ── Tab bar ──────────────────────────────────────────────────────
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            tabs: const [
              Tab(text: 'Historial'),
              Tab(text: 'Turno'),
            ],
          ),
        ),

        // ── Tab views ────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              HistoryScreen(),
              StatsScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
