import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../models/decay_record.dart';
import '../../models/decay_service.dart';
import '../../services/history_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/isotope_pill.dart';
import '../../models/isotope.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<DecayRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await HistoryService.instance.load();
    final now = DateTime.now();
    final today = all.where((r) =>
        r.timestamp.year == now.year &&
        r.timestamp.month == now.month &&
        r.timestamp.day == now.day).toList();
    if (mounted) setState(() { _records = today; _loading = false; });
  }

  Map<String, _IsotopeStats> get _byIsotope {
    final Map<String, List<DecayRecord>> groups = {};
    for (final r in _records) {
      groups.putIfAbsent(r.isotopeId, () => []).add(r);
    }
    final result = <String, _IsotopeStats>{};
    groups.forEach((id, list) {
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final latest = list.first;
      final maxInitial = list.map((r) => r.initialActivity).reduce((a, b) => a > b ? a : b);
      result[id] = _IsotopeStats(
        isotopeId: id,
        isotopeSymbol: latest.isotopeSymbol,
        isotopeName: latest.isotopeName,
        initialActivity: maxInitial,
        residualActivity: latest.resultActivity,
        unitLabel: latest.unitLabel,
        calcCount: list.length,
        lastTimestamp: latest.timestamp,
      );
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final stats = _byIsotope;
    final totalCalcs = _records.length;
    final uniqueIsotopes = stats.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TURNO DE HOY',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                  ).animate().fadeIn(duration: 300.ms),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    DateFormat("EEEE, d 'de' MMMM", 'es_AR').format(DateTime.now()),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ).animate().fadeIn(delay: 60.ms, duration: 300.ms),
                ],
              ),
            ),
          ),

          // ── Summary chips ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Row(
                children: [
                  _SummaryChip(
                    label: 'Cálculos',
                    value: '$totalCalcs',
                    icon: Icons.calculate_outlined,
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0, duration: 350.ms, curve: Curves.easeOut),
                  SizedBox(width: AppSpacing.md),
                  _SummaryChip(
                    label: 'Isótopos',
                    value: '$uniqueIsotopes',
                    icon: Icons.science_outlined,
                  ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1, end: 0, duration: 350.ms, curve: Curves.easeOut),
                ],
              ),
            ),
          ),

          // ── Empty state ──────────────────────────────────────────
          if (stats.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart_rounded,
                        size: 56, color: AppColors.textSecondary.withOpacity(0.3)),
                    SizedBox(height: AppSpacing.base),
                    Text(
                      'Sin actividad hoy',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Los cálculos del turno aparecerán aquí',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary.withOpacity(0.6),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // ── Isotope cards ────────────────────────────────────────
          if (stats.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
                child: Text(
                  'MARGEN DE TRABAJO',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final entry = stats.values.elementAt(i);
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: _IsotopeCard(stats: entry)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 200 + i * 80), duration: 350.ms)
                          .slideY(begin: 0.15, end: 0, delay: Duration(milliseconds: 200 + i * 80), duration: 350.ms, curve: Curves.easeOutBack),
                    );
                  },
                  childCount: stats.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _IsotopeStats {
  final String isotopeId;
  final String isotopeSymbol;
  final String isotopeName;
  final double initialActivity;
  final double residualActivity;
  final String unitLabel;
  final int calcCount;
  final DateTime lastTimestamp;

  const _IsotopeStats({
    required this.isotopeId,
    required this.isotopeSymbol,
    required this.isotopeName,
    required this.initialActivity,
    required this.residualActivity,
    required this.unitLabel,
    required this.calcCount,
    required this.lastTimestamp,
  });

  double get fraction => residualActivity / initialActivity;
  double get remainingPct => (fraction * 100).clamp(0, 100);

  bool get isCritical => remainingPct <= 20;

  Isotope get isotope => kIsotopes.firstWhere(
        (i) => i.id == isotopeId,
        orElse: () => kIsotopes.first,
      );

  Color get marginColor {
    if (remainingPct > 60) return AppColors.accent;   // teal — margen viable
    if (remainingPct > 20) return AppColors.primary;  // indigo — atención
    return AppColors.critical;                         // naranja — crítico
  }

  String get marginLabel {
    if (remainingPct > 60) return 'Margen amplio';
    if (remainingPct > 20) return 'Moderado';
    return 'Crítico';
  }
}

// ── Isotope Card ──────────────────────────────────────────────────────────────

class _IsotopeCard extends StatelessWidget {
  final _IsotopeStats stats;
  const _IsotopeCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final color = stats.marginColor;
    final pct = stats.remainingPct;

    return GlassCard(
      isActive: stats.isCritical,
      glowColor: color,
      hasBorderGlow: true,
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Isotope pill — shared widget
              IsotopePill(isotope: stats.isotope, size: IsotopePillSize.medium),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.isotopeName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '${stats.calcCount} ${stats.calcCount == 1 ? 'cálculo' : 'cálculos'} · ${DateFormat('HH:mm').format(stats.lastTimestamp)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              // Margin badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: stats.isCritical ? 8 : 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: color.withOpacity(stats.isCritical ? 0.5 : 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (stats.isCritical) ...[
                      Icon(Icons.warning_rounded, color: color, size: 11),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      stats.marginLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: stats.isCritical ? FontWeight.w700 : FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.lg),

          // Activity numbers
          Row(
            children: [
              Expanded(
                child: _ActivityStat(
                  label: 'Inicial',
                  value: DecayService.formatActivity(stats.initialActivity),
                  unit: stats.unitLabel,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.border),
              Expanded(
                child: _ActivityStat(
                  label: 'Residual',
                  value: DecayService.formatActivity(stats.residualActivity),
                  unit: stats.unitLabel,
                  color: color,
                  alignEnd: true,
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.base),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${pct.toStringAsFixed(1)}% restante',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    '${(100 - pct).toStringAsFixed(1)}% usado',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    Container(height: 6, color: AppColors.border),
                    FractionallySizedBox(
                      widthFactor: pct / 100,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Activity stat ─────────────────────────────────────────────────────────────

class _ActivityStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool alignEnd;

  const _ActivityStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: alignEnd ? 16 : 0,
        right: alignEnd ? 0 : 16,
      ),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
          ),
          SizedBox(height: AppSpacing.xs),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary chip ──────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
