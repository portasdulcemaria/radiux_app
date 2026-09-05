import 'package:flutter/material.dart';
import '../../widgets/isotope_pill.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/history_service.dart';
import '../../models/decay_record.dart';
import '../../models/isotope.dart';
import '../../models/decay_service.dart';
import '../../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onGoToDecaimiento;
  const HistoryScreen({super.key, this.onGoToDecaimiento});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _filterTime = 'semana';
  String? _filterIsotope;
  List<DecayRecord> _allRecords = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await HistoryService.instance.load();
    if (mounted) setState(() => _allRecords = List<DecayRecord>.from(records));
  }

  List<DecayRecord> get _todayRecords {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _allRecords.where((r) {
      final d = DateTime(r.timestamp.year, r.timestamp.month, r.timestamp.day);
      return d == today;
    }).toList();
  }

  Map<String, _IsotopeStats> get _todayByIsotope {
    final map = <String, _IsotopeStats>{};
    for (final r in _todayRecords) {
      final key = r.isotopeId;
      if (!map.containsKey(key)) {
        map[key] = _IsotopeStats(
          isotopeId: r.isotopeId,
          isotopeName: r.isotopeName,
          isotopeSymbol: r.isotopeSymbol,
          halfLifeHours: r.halfLifeHours,
          unitLabel: r.unitLabel,
        );
      }
      map[key]!.add(r);
    }
    return map;
  }

  List<DecayRecord> get _timeFiltered {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    switch (_filterTime) {
      case 'hoy':
        return _allRecords
            .where((r) => r.timestamp.isAfter(todayStart))
            .toList();
      case 'ayer':
        final yesterdayStart =
            todayStart.subtract(const Duration(days: 1));
        return _allRecords
            .where((r) =>
                r.timestamp.isAfter(yesterdayStart) &&
                r.timestamp.isBefore(todayStart))
            .toList();
      case 'semana':
        final weekStart =
            todayStart.subtract(const Duration(days: 6));
        return _allRecords.where((r) => r.timestamp.isAfter(weekStart)).toList();
      default:
        return _allRecords;
    }
  }

  List<DecayRecord> get _filtered {
    var base = _timeFiltered;
    if (_filterIsotope != null) {
      base = base.where((r) => r.isotopeId == _filterIsotope).toList();
    }
    return base;
  }

  List<String> get _availableIsotopes {
    return _timeFiltered.map((r) => r.isotopeId).toSet().cast<String>().toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final stats = _todayByIsotope;
    final filtered = _filtered;
    final isotopes = _availableIsotopes;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── TURNO DE HOY ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.lg, AppSpacing.base, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: 'TURNO DE HOY',
                    subtitle: DateFormat("EEEE, d 'de' MMMM", 'es_AR')
                        .format(DateTime.now()),
                  ),
                  SizedBox(height: AppSpacing.md),
                  if (stats.isEmpty)
                    _EmptyTurno()
                  else
                    ...stats.values.toList().asMap().entries.map((e) =>
                        Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.sm + 2),
                          child: _IsotopeCard(stats: e.value)
                              .animate()
                              .fadeIn(delay: (e.key * 80).ms, duration: 350.ms)
                              .slideY(begin: 0.15, end: 0),
                        )),
                  SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          // ── REGISTROS header + chips ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: _SectionHeader(title: 'REGISTROS')),
                      if (isotopes.length > 1)
                        _IsotopeFilterButton(
                          isotopes: isotopes,
                          selected: _filterIsotope,
                          onSelect: (id) => setState(() => _filterIsotope = id),
                        ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm + 2),
                  // Time chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _Chip(
                          label: 'Hoy',
                          selected: _filterTime == 'hoy',
                          onTap: () => setState(() {
                            _filterTime = 'hoy';
                            _filterIsotope = null;
                          }),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        _Chip(
                          label: 'Ayer',
                          selected: _filterTime == 'ayer',
                          onTap: () => setState(() {
                            _filterTime = 'ayer';
                            _filterIsotope = null;
                          }),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        _Chip(
                          label: '7 días',
                          selected: _filterTime == 'semana',
                          onTap: () => setState(() {
                            _filterTime = 'semana';
                            _filterIsotope = null;
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Record list ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: filtered.isEmpty
                  ? _EmptyRecords(key: ValueKey('empty_\$_filterTime'), filter: _filterTime, onCalcular: widget.onGoToDecaimiento)
                  : Column(
                      key: ValueKey('list_\$_filterTime'),
                      children: [
                        for (int i = 0; i < filtered.length; i++)
                          Builder(builder: (context) {
                            final record = filtered[i];
                            final showDay = i == 0 ||
                                !_sameDay(filtered[i - 1].timestamp, record.timestamp);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showDay)
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.xs, AppSpacing.base, 6),
                                    child: Text(
                                      _dayLabel(record.timestamp),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                              color: AppColors.textSecondary,
                                              letterSpacing: 0.8),
                                    ),
                                  ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.sm),
                                  child: _RecordRow(
                                    record: record,
                                    showViability: _sameDay(record.timestamp, DateTime.now()),
                                  )
                                      .animate()
                                      .fadeIn(delay: (i * 40).ms, duration: 300.ms),
                                ),
                              ],
                            );
                          }),
                      ],
                    ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'HOY';
    if (d == today.subtract(const Duration(days: 1))) return 'AYER';
    return DateFormat('EEEE d MMM', 'es_AR').format(dt).toUpperCase();
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _IsotopeStats {
  final String isotopeId;
  final String isotopeName;
  final String isotopeSymbol;
  final double halfLifeHours;
  final String unitLabel;
  final List<DecayRecord> records = [];

  _IsotopeStats({
    required this.isotopeId,
    required this.isotopeName,
    required this.isotopeSymbol,
    required this.halfLifeHours,
    required this.unitLabel,
  });

  void add(DecayRecord r) => records.add(r);

  int get count => records.length;

  double get latestResult =>
      records.isEmpty ? 0 : records.first.resultActivity;

  DateTime? get latestTime =>
      records.isEmpty ? null : records.first.timestamp;

  String? get timeRange {
    if (records.length < 2) return null;
    final earliest = records.last.timestamp;
    final latest = records.first.timestamp;
    final fmt = DateFormat('HH:mm');
    return '${fmt.format(earliest)}–${fmt.format(latest)}';
  }

  double get avgRemaining =>
      records.isEmpty
          ? 0
          : records.map((r) => r.fraction * 100).reduce((a, b) => a + b) /
              records.length;

  Color get marginColor {
    if (avgRemaining > 60) return AppColors.accent;  // teal — margen viable
    if (avgRemaining > 20) return AppColors.primary;   // indigo — atención
    return AppColors.critical;                            // naranja — crítico
  }

  String get marginLabel {
    if (avgRemaining > 60) return 'Buen margen';
    if (avgRemaining > 20) return 'Margen medio';
    return 'Crítico';
  }

  bool get isCritical => avgRemaining <= 20;

  Isotope get isotope => kIsotopes.firstWhere(
        (i) => i.id == isotopeId,
        orElse: () => kIsotopes.first,
      );
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
          ),
        ],
      ],
    );
  }
}

class _IsotopeCard extends StatelessWidget {
  final _IsotopeStats stats;
  const _IsotopeCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final iso = stats.isotope;
    return Container(
      padding: EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [iso.color.withOpacity(0.10), iso.color.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: iso.color.withOpacity(0.22)),
        boxShadow: [BoxShadow(color: iso.color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Isotope pill
              IsotopePill(isotope: iso, size: IsotopePillSize.medium),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.isotopeName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${stats.count} cálculo${stats.count != 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (stats.timeRange != null) ...[
                          Text(
                            ' · ${stats.timeRange}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary.withOpacity(0.6),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Badge: solo visible en attention o critical
              if (stats.avgRemaining < 60)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: stats.marginColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                        color: stats.marginColor.withOpacity(stats.isCritical ? 0.6 : 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (stats.isCritical) ...[
                        Icon(Icons.warning_rounded, color: stats.marginColor, size: 11),
                        SizedBox(width: AppSpacing.xs),
                      ],
                      Text(
                        stats.marginLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: stats.marginColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          // Progress bar: avg remaining
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Actividad promedio restante',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  Text(
                    '${stats.avgRemaining.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: stats.marginColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: stats.avgRemaining / 100,
                  backgroundColor: AppColors.cardHover,
                  valueColor:
                      AlwaysStoppedAnimation(stats.marginColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm + 2),
          // Last result
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 13, color: AppColors.textSecondary),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Último: ${DecayService.formatActivity(stats.latestResult)} ${stats.unitLabel}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (stats.latestTime != null) ...[
                SizedBox(width: AppSpacing.xs),
                Text(
                  DateFormat('HH:mm').format(stats.latestTime!),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary.withOpacity(0.6),
                      ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatefulWidget {
  final DecayRecord record;
  final bool showViability;
  const _RecordRow({required this.record, this.showViability = true});

  @override
  State<_RecordRow> createState() => _RecordRowState();
}

class _RecordRowState extends State<_RecordRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final iso = kIsotopes.firstWhere((i) => i.id == record.isotopeId,
        orElse: () => kIsotopes.first);
    final timeFmt = DateFormat('HH:mm');
    final fraction = record.fraction.clamp(0.0, 1.0);
    final pctVal = fraction * 100;
    final pct = pctVal.toStringAsFixed(1);

    Color barColor;
    String? actionLabel;
    bool isCriticalAction = false;
    if (pctVal < 20) {
      barColor = AppColors.critical;
      actionLabel = 'Verificar viabilidad';
      isCriticalAction = true;
    } else if (pctVal < 60) {
      barColor = AppColors.primary;
      actionLabel = 'Actividad baja';
    } else {
      barColor = AppColors.accent;
      actionLabel = null;
    }

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: _expanded ? AppSpacing.base : AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [iso.color.withOpacity(0.08), iso.color.withOpacity(0.02)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: _expanded ? barColor.withOpacity(0.30) : iso.color.withOpacity(0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fila siempre visible: escaneado rápido ──────────────────
            Row(
              children: [
                IsotopePill(isotope: iso, size: IsotopePillSize.small),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        DecayService.formatActivity(record.resultActivity),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: barColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        record.unitLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: barColor.withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  timeFmt.format(record.timestamp),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                SizedBox(width: AppSpacing.xs),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            // ── Detalle expandido ───────────────────────────────────────
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.sm + 2),
                  // Badge de viabilidad
                  if (widget.showViability && actionLabel != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: barColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: barColor.withOpacity(0.30)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCriticalAction) ...[
                              Icon(Icons.warning_rounded, size: 9, color: barColor),
                              const SizedBox(width: 3),
                            ],
                            Text(
                              actionLabel!,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: barColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Barra de actividad
                  if (widget.showViability)
                    Row(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: fraction,
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [barColor.withOpacity(0.6), barColor],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: barColor.withOpacity(0.4),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm + 2),
                        Text(
                          '$pct%',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: barColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  // Actividad inicial
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(Icons.start_rounded, size: 12, color: AppColors.textSecondary.withOpacity(0.5)),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        'Inicial: ${DecayService.formatActivity(record.initialActivity)} ${record.unitLabel}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.12) : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: selected ? c.withOpacity(0.5) : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? c
                : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}


// ── Isotope filter button + sheet ─────────────────────────────────────────────

class _IsotopeFilterButton extends StatelessWidget {
  final List<String> isotopes;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _IsotopeFilterButton({
    required this.isotopes,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilter = selected != null;
    final iso = hasFilter
        ? kIsotopes.firstWhere((i) => i.id == selected,
            orElse: () => kIsotopes.first)
        : null;

    return GestureDetector(
      onTap: () => _showSheet(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: 6),
        decoration: BoxDecoration(
          color: hasFilter
              ? (iso?.color ?? AppColors.primary).withOpacity(0.12)
              : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: hasFilter
                ? (iso?.color ?? AppColors.primary).withOpacity(0.5)
                : AppColors.border,
            width: hasFilter ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.science_outlined,
              size: 13,
              color: hasFilter
                  ? (iso?.color ?? AppColors.primary)
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              hasFilter
                  ? iso!.symbol.split('\n').join('')
                  : 'Isótopo',
              style: TextStyle(
                color: hasFilter
                    ? (iso?.color ?? AppColors.primary)
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: hasFilter ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.expand_more_rounded,
              size: 13,
              color: hasFilter
                  ? (iso?.color ?? AppColors.primary)
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _IsotopePickerSheet(
        isotopes: isotopes,
        selected: selected,
        onSelect: (id) {
          Navigator.pop(context);
          onSelect(id);
        },
      ),
    );
  }
}

class _IsotopePickerSheet extends StatelessWidget {
  final List<String> isotopes;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _IsotopePickerSheet({
    required this.isotopes,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.base),
          Text(
            'Filtrar por isótopo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mostrá solo los registros de un radiofármaco',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          SizedBox(height: AppSpacing.base),
          // "Todos" option
          _IsoRow(
            label: 'Todos los isótopos',
            subtitle: 'Sin filtro activo',
            color: AppColors.textSecondary,
            isSelected: selected == null,
            onTap: () => onSelect(null),
          ),
          const Divider(color: AppColors.border, height: 1),
          ...isotopes.asMap().entries.map((e) {
            final id = e.value;
            final iso = kIsotopes.firstWhere((i) => i.id == id,
                orElse: () => kIsotopes.first);
            return _IsoRow(
              label: iso.symbol.split('\n').join(''),
              subtitle: iso.name,
              color: iso.color,
              isSelected: selected == id,
              onTap: () => onSelect(id),
            ).animate().fadeIn(
                  delay: Duration(milliseconds: 40 * e.key),
                  duration: 200.ms,
                );
          }),
        ],
      ),
    );
  }
}

class _IsoRow extends StatefulWidget {
  final String label;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _IsoRow({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_IsoRow> createState() => _IsoRowState();
}

class _IsoRowState extends State<_IsoRow> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _bgOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 160));
    _scale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.93)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 0.93, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 60),
    ]).animate(_ctrl);
    _bgOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 70),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    HapticFeedback.selectionClick();
    await _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    final subtitle = widget.subtitle;
    final color = widget.color;
    final isSelected = widget.isSelected;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(_bgOpacity.value * 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Transform.scale(
                scale: 0.88 + (_scale.value - 0.93).clamp(0.0, 0.07) / 0.07 * 0.12,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(isSelected ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: color.withOpacity(isSelected ? 0.5 : 0.2),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label.length <= 6 ? label : label.substring(0, 6),
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              title: Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle_rounded, color: color, size: 18)
                  : null,
              onTap: _handleTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTurno extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.07),
            AppColors.primary.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.20)),
            ),
            child: const Icon(
              Icons.science_outlined,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          SizedBox(height: AppSpacing.base),
          Text(
            'Aún no comenzó tu turno',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Calculá un decaimiento para empezar a registrar la actividad del turno.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyRecords extends StatelessWidget {
  final String filter;
  final VoidCallback? onCalcular;
  const _EmptyRecords({super.key, required this.filter, this.onCalcular});

  @override
  Widget build(BuildContext context) {
    final isHoy = filter == 'hoy';

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.xl, AppSpacing.base, 40),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              Icons.science_outlined,
              size: 24,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
          ),
          SizedBox(height: AppSpacing.base),
          Text(
            isHoy ? 'Aún no comenzó tu turno' : filter == 'ayer' ? 'Sin actividad registrada ayer' : 'Sin actividad en los últimos 7 días',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            isHoy
                ? 'Calculá un decaimiento para empezar a registrar la actividad del turno.'
                : 'Los registros se generan al calcular un decaimiento.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          if (isHoy && onCalcular != null) ...[
            SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: onCalcular,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.science_outlined, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Ir a Decaimiento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


