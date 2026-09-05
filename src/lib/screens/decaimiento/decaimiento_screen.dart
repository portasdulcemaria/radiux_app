import 'package:flutter/material.dart';
import '../../models/decay_record.dart';
import '../../widgets/custom_numpad.dart';
import '../../services/history_service.dart';
import '../../services/sound_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../models/isotope.dart';
import '../../models/unit.dart';
import '../../models/decay_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_motion.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/isotope_pill.dart';

class DecaimientoScreen extends StatefulWidget {
  const DecaimientoScreen({super.key});

  @override
  State<DecaimientoScreen> createState() => _DecaimientoScreenState();
}

class _DecaimientoScreenState extends State<DecaimientoScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // State
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  RadioUnit _unit = kUnits[4]; // mCi default
  Isotope _isotope = kIsotopes.first; // Tc99m
  final List<String> _recentIsotopeIds = []; // últimos usados (max 4, orden LIFO)
  DateTime _referenceDate = DateTime.now();
  double _addedHours = 0;
  int? _selectedQuickIdx;

  double? _result;
  double? _lastDecayResult;
  double? _lastDecayA0;
  RadioUnit? _lastDecayUnit;
  Isotope? _lastDecayIsotope;
  String? _errorText;
  bool _isCalculating = false;
  Timer? _debounce;

  // Stepper state
  int _activeStep = 0; // 0=activity, 1=isotope, 2=time
  bool _isotopeConfirmed = false;

  DateTime get _targetDate =>
      _referenceDate.add(Duration(minutes: (_addedHours * 60).round()));

  double? get _initialActivity {
    final text = _controller.text.replaceAll(',', '.');
    return double.tryParse(text);
  }

  bool get _step0Done =>
      _controller.text.isNotEmpty &&
      _initialActivity != null &&
      _initialActivity! > 0;

  bool get _step1Done => _isotopeConfirmed;

  bool get _step2Done => _addedHours > 0;

  bool get _canCalculate => _step0Done && _step1Done && _step2Done;

  List<_QuickTimeOption> get _quickOptions => [
        _QuickTimeOption(label: '+1h', hours: 1),
        _QuickTimeOption(label: '+6h', hours: 6),
        _QuickTimeOption(label: '+12h', hours: 12),
        _QuickTimeOption(label: '+24h', hours: 24),
        _QuickTimeOption(
          label: '+T½',
          hours: _isotope.halfLifeHours,
          isHalfLife: true,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onInputChanged);
    _focusNode.addListener(() { if (mounted) setState(() {}); });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {
      _errorText = null;
      _result = null;
    });
    // Auto-advance to isotope step when activity is valid
    if (_step0Done && _activeStep == 0) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _step0Done && _activeStep == 0) {
          setState(() => _activeStep = 1);
          _focusNode.unfocus();
        }
      });
    }
  }

  void _confirmIsotope(Isotope iso) {
    HapticFeedback.selectionClick();
    SoundService.instance.select();
    setState(() {
      _isotope = iso;
      _isotopeConfirmed = true;
      _result = null;
      if (_activeStep == 1) _activeStep = 2;
    });
  }

  void _selectQuickTime(int idx) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedQuickIdx == idx) {
        _selectedQuickIdx = null;
        _addedHours = 0;
        _result = null;
      } else {
        _selectedQuickIdx = idx;
        _addedHours = _quickOptions[idx].hours;
        _result = null;
      }
    });
    if (_canCalculate) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), _calculate);
    }
  }

  Future<void> _pickDateTime() async {
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DateTimePickerSheet(initial: _referenceDate),
    );
    if (result == null) return;
    setState(() {
      _referenceDate = result;
      _result = null;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _calculate() async {
    final a0 = _initialActivity;
    if (a0 == null || a0 <= 0) {
      setState(() => _errorText = 'Ingresá un valor de actividad positivo');
      HapticFeedback.mediumImpact();
      return;
    }
    if (_addedHours <= 0) {
      setState(() => _errorText = 'Seleccioná un tiempo transcurrido');
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() => _isCalculating = true);
    await Future.delayed(const Duration(milliseconds: 150));

    final result = DecayService.decay(
      initialActivity: a0,
      halfLifeHours: _isotope.halfLifeHours,
      elapsedHours: _addedHours,
    );

    setState(() {
      _result = result;
      _isCalculating = false;
      _errorText = null;
    });
    // Persistir último resultado para referencia
    _lastDecayResult = result;
    _lastDecayA0 = a0;
    _lastDecayUnit = _unit;
    _lastDecayIsotope = _isotope;
    // Track recent isotopes (LIFO, max 4, no duplicates)
    _recentIsotopeIds
      ..remove(_isotope.id)
      ..insert(0, _isotope.id);
    if (_recentIsotopeIds.length > 4) _recentIsotopeIds.removeLast();
    // Guardar en histórico
    HistoryService.instance.save(DecayRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      isotopeId: _isotope.id,
      isotopeSymbol: _isotope.symbol,
      isotopeName: _isotope.name,
      initialActivity: a0,
      resultActivity: result,
      unitId: _unit.id,
      unitLabel: _unit.label,
      elapsedHours: _addedHours.toDouble(),
      halfLifeHours: _isotope.halfLifeHours,
    ));
    // Haptic: arranque
    HapticFeedback.mediumImpact();
    // Show dramatic result reveal sheet
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        builder: (_) => _ResultRevealSheet(
          result: result,
          initialActivity: a0,
          unit: _unit,
          isotope: _isotope,
          elapsedHours: _addedHours,
          onReset: _reset,
        ),
      ).whenComplete(_reset);
    }
    // Landing haptic when ring completes (900ms)
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) { HapticFeedback.heavyImpact(); SoundService.instance.success(); }
    });
    // Critical zone: double-pulse at 1150ms — patrón táctil diferenciado = acción requerida
    final fraction = (a0 > 0) ? (result / a0).clamp(0.0, 1.0) : 0.0;
    if (fraction <= 0.20) {
      Future.delayed(const Duration(milliseconds: 1150), () {
        if (mounted) HapticFeedback.heavyImpact();
      });
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _controller.clear();
      _addedHours = 0;
      _selectedQuickIdx = null;
      _result = null;
      _errorText = null;
      _referenceDate = DateTime.now();
      _isotopeConfirmed = false;
      _activeStep = 0;
      _isotope = kIsotopes.first;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _goToStep(int step) {
    if (step == 0 || (step == 1 && _step0Done) || (step == 2 && _step1Done)) {
      setState(() => _activeStep = step);
      if (step == 0) _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _focusNode.unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.base, AppSpacing.lg, AppSpacing.base,
              (_focusNode.hasFocus && _result == null)
                  ? MediaQuery.of(context).size.height * 0.48
                  : AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Result ───────────────────────────────────────────────
                if (_result != null && _initialActivity != null) ...[
                  _DecayResultCard(
                    initialActivity: _initialActivity!,
                    result: _result!,
                    unit: _unit,
                    isotope: _isotope,
                    elapsedHours: _addedHours,
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.2, end: 0)
                      .scale(begin: const Offset(0.96, 0.96)),
                  const SizedBox(height: 10),
                  Center(
                    child: GestureDetector(
                      onTap: _reset,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                        child: Text(
                          'Nuevo cálculo',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.primary.withOpacity(0.6),
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary.withOpacity(0.4)),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Sección 1: Actividad inicial (siempre visible) ────────
                _StepLabel(number: 1, label: 'Actividad inicial', done: _step0Done),
                const SizedBox(height: 10),
                _ActivityInputRow(
                  controller: _controller,
                  focusNode: _focusNode,
                  unit: _unit,
                  hasError: _errorText != null && !_step0Done,
                  onUnitTap: _showUnitPicker,
                ).animate().fadeIn(duration: 300.ms),
                if (_errorText != null && !_step0Done) ...[
                  const SizedBox(height: 6),
                  _ErrorHint(text: _errorText!).animate().fadeIn(),
                ],

                // ── Sección 2: Isótopo (aparece cuando actividad es válida) ─
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  child: _step0Done
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.lg),
                            _StepLabel(number: 2, label: 'Isótopo', done: _step1Done),
                            const SizedBox(height: AppSpacing.sm),
                            _PressableScale(
                              onTap: _showIsotopePicker,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _isotope.color.withOpacity(0.12),
                                      _isotope.color.withOpacity(0.04),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  border: Border.all(
                                    color: _isotope.color.withOpacity(_step1Done ? 0.55 : 0.28),
                                    width: _step1Done ? 1.5 : 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _isotope.color.withOpacity(0.12),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    IsotopePill(isotope: _isotope, size: IsotopePillSize.large)
                                        .animate(key: ValueKey(_isotopeConfirmed))
                                        .then(delay: 50.ms)
                                        .scaleXY(begin: 1.0, end: 1.10, duration: 120.ms, curve: Curves.easeOut)
                                        .then()
                                        .scaleXY(begin: 1.10, end: 1.0, duration: 200.ms, curve: Curves.elasticOut),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(_isotope.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium),
                                          Text(_isotope.halfLifeDisplay,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                          Text(_isotope.category,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                      color: _isotope.color
                                                          .withOpacity(0.8))),
                                        ],
                                      ),
                                    ),
                                    if (_step1Done)
                                      const Icon(Icons.check_circle_rounded,
                                          color: AppColors.accent, size: 20)
                                    else
                                      const Icon(Icons.chevron_right_rounded,
                                          color: AppColors.textSecondary),
                                  ],
                                ),
                              ),
                            ),
                            if (!_step1Done) ...[
                              const SizedBox(height: 10),
                              _PressableScale(
                                onTap: () => _confirmIsotope(_isotope),
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primary, AppColors.primaryDark],
                                    ),
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      )
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('Confirmar isótopo',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ],
                        )
                      : const SizedBox.shrink(),
                ),

                // ── Sección 3: Tiempo (aparece cuando isótopo confirmado) ──
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  child: _step1Done
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Fecha inicial',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                              color:
                                                  AppColors.textSecondary)),
                                ),
                                GestureDetector(
                                  onTap: _pickDateTime,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: AppColors.primary.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.edit_calendar_rounded,
                                            size: 14,
                                            color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Text('Modificar',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                    color: AppColors.primary,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _DateTimeCard(dateTime: _referenceDate),
                            const SizedBox(height: AppSpacing.lg),
                            _StepLabel(number: 3, label: 'Tiempo transcurrido', done: _step2Done),
                            const SizedBox(height: 10),
                            _QuickTimeRow(
                              options: _quickOptions,
                              selectedIdx: _selectedQuickIdx,
                              onSelect: _selectQuickTime,
                            ),
                            if (_errorText != null && _errorText!.contains('tiempo') && !_step2Done) ...[
                              const SizedBox(height: 8),
                              _ErrorHint(text: _errorText!).animate().fadeIn(),
                            ],
                            if (_selectedQuickIdx != null) ...[
                              const SizedBox(height: 10),
                              _TargetDateCard(
                                targetDate: _targetDate,
                                addedHours: _addedHours,
                                isotope: _isotope,
                              )
                                  .animate()
                                  .fadeIn(duration: 300.ms)
                                  .slideY(begin: 0.1, end: 0),
                            ],
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),

        // ── Último resultado (referencia) ─────────────────────────────────
        if (_result == null && _lastDecayResult != null)
          Positioned(
            left: AppSpacing.base,
            right: AppSpacing.base,
            bottom: 92,
            child: _DecayLastResultChip(
              value: DecayService.formatActivity(_lastDecayResult!),
              unit: _lastDecayUnit!,
              isotope: _lastDecayIsotope!,
              initialActivity: _lastDecayA0!,
            ).animate().fadeIn(duration: 250.ms),
          ),

        // ── Sticky CTA ───────────────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _CalculateFooter(
            canCalculate: _canCalculate,
            isCalculating: _isCalculating,
            hasResult: _result != null,
            onTap: _calculate,
          ),
        ),

        // ── Custom numpad ─────────────────────────────────────────────────
        if (_focusNode.hasFocus && _result == null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomNumpad(
              controller: _controller,
              onDone: () {
                _focusNode.unfocus();
                setState(() {});
              },
              onChanged: () => setState(() {}),
            ),
          ),
      ],
    );
  }

  void _showUnitPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final maxH = MediaQuery.of(ctx).size.height * 0.6;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: AppSpacing.base),
                    Text('Unidad de actividad',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: kUnits.asMap().entries.map((e) {
                    final u = e.value;
                    final isSelected = u.id == _unit.id;
                    return _DecPickerUnitRow(
                      key: ValueKey(u.id),
                      unit: u,
                      isSelected: isSelected,
                      index: e.key,
                      onSelect: () {
                        setState(() {
                          _unit = u;
                          _result = null;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showIsotopePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => _IsotopePickerSheet(
          selected: _isotope,
          recentIds: List.unmodifiable(_recentIsotopeIds),
          scrollController: scrollCtrl,
          onSelect: (iso) {
            Navigator.pop(context);
            _confirmIsotope(iso);
          },
        ),
      ),
    );
  }
}

// ── StepCard ──────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final int index;
  final String title;
  final bool isDone;
  final bool isActive;
  final bool isLocked;
  final String? summary;
  final VoidCallback onHeaderTap;
  final Widget child;

  const _StepCard({
    required this.index,
    required this.title,
    required this.isDone,
    required this.isActive,
    required this.isLocked,
    required this.onHeaderTap,
    required this.child,
    this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isActive
        ? AppColors.primary
        : isDone
            ? AppColors.accent.withOpacity(0.4)
            : AppColors.border;

    final Color numberBg = isActive
        ? AppColors.primary
        : isDone
            ? AppColors.accent
            : AppColors.card;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: isActive ? 1.5 : 1),
        boxShadow: isActive
            ? [BoxShadow(color: AppColors.primaryGlow, blurRadius: 12)]
            : null,
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: isLocked ? null : onHeaderTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  // Step number / check
                  AnimatedContainer(
                    duration: AppMotion.exit,
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: numberBg,
                      shape: BoxShape.circle,
                      border: isLocked
                          ? Border.all(color: AppColors.border)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: isDone
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isLocked
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (summary != null && !isActive)
                          Text(
                            summary!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isDone && !isActive)
                    const Icon(Icons.edit_rounded,
                        color: AppColors.textSecondary, size: 16),
                  if (isLocked)
                    const Icon(Icons.lock_rounded,
                        color: AppColors.textSecondary, size: 16),
                ],
              ),
            ),
          ),

          // Body (animated)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isActive
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: child,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _ActivityInputRow extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final RadioUnit unit;
  final bool hasError;
  final VoidCallback onUnitTap;

  const _ActivityInputRow({
    required this.controller,
    required this.focusNode,
    required this.unit,
    required this.hasError,
    required this.onUnitTap,
  });

  @override
  State<_ActivityInputRow> createState() => _ActivityInputRowState();
}

class _ActivityInputRowState extends State<_ActivityInputRow> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hasError
        ? AppColors.error.withOpacity(0.7)
        : _isFocused
            ? AppColors.primary.withOpacity(0.6)
            : AppColors.border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: _isFocused
              ? AppColors.primary.withOpacity(0.6)
              : widget.hasError
                  ? AppColors.error.withOpacity(0.6)
                  : AppColors.border,
          width: _isFocused || widget.hasError ? 1.5 : 1,
        ),
        color: AppColors.card,
        boxShadow: widget.hasError
            ? [BoxShadow(color: AppColors.errorGlow, blurRadius: 12)]
            : _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 0,
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
      ),
      child: Row(
        children: [
          // Mirror spacer so the text field centers optically within the full card
          const SizedBox(width: 78),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              readOnly: true,
              showCursor: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 44,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
              decoration: const InputDecoration(
                hintText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                filled: false,
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.onUnitTap,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cardHover,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Text(widget.unit.label,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more_rounded,
                      color: AppColors.textSecondary, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorHint extends StatelessWidget {
  final String text;
  const _ErrorHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.warning_amber_rounded,
            size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.primary))),
      ],
    );
  }
}

class _DateTimeCard extends StatelessWidget {
  final DateTime dateTime;

  const _DateTimeCard({required this.dateTime});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat("EEE, d MMM y, HH:mm", 'es_AR');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.primary.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(color: AppColors.primary.withOpacity(0.20)),
      ),
      child: Text(
        fmt.format(dateTime),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w600,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final int number;
  final String label;
  final bool done;

  const _StepLabel({required this.number, required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: done ? const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : null,
            color: done ? null : Colors.transparent,
            border: done ? null : Border.all(
              color: AppColors.primary.withOpacity(0.40),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
              : Text(
                  '$number',
                  style: TextStyle(
                    color: AppColors.primary.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: done
                ? AppColors.primary.withOpacity(0.6)
                : AppColors.primary.withOpacity(0.85),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _QuickTimeRow extends StatefulWidget {
  final List<_QuickTimeOption> options;
  final int? selectedIdx;
  final ValueChanged<int> onSelect;

  const _QuickTimeRow({
    required this.options,
    required this.selectedIdx,
    required this.onSelect,
  });

  @override
  State<_QuickTimeRow> createState() => _QuickTimeRowState();
}

class _QuickTimeRowState extends State<_QuickTimeRow> {
  int? _pressedIdx;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: widget.options.asMap().entries.map((e) {
        final idx = e.key;
        final opt = e.value;
        final isSelected = widget.selectedIdx == idx;
        final isPressed = _pressedIdx == idx;

        return Expanded(
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressedIdx = idx),
            onTapUp: (_) {
              setState(() => _pressedIdx = null);
              widget.onSelect(idx);
            },
            onTapCancel: () => setState(() => _pressedIdx = null),
            child: AnimatedScale(
              scale: isPressed ? 0.91 : 1.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                margin: EdgeInsets.only(
                    right: idx < widget.options.length - 1 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.20),
                      AppColors.primary.withOpacity(0.08),
                    ],
                  ) : null,
                  color: isSelected ? null : AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.base),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.60)
                        : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                        color: AppColors.primary.withOpacity(0.20),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ] : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  opt.label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w500,
                    letterSpacing: isSelected ? -0.2 : 0,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TargetDateCard extends StatelessWidget {
  final DateTime targetDate;
  final double addedHours;
  final Isotope isotope;

  const _TargetDateCard({
    required this.targetDate,
    required this.addedHours,
    required this.isotope,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat("EEE, d MMM y, HH:mm", 'es_AR');
    final fraction =
        math.pow(2, -addedHours / isotope.halfLifeHours).toDouble();
    final pct = (fraction * 100).toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.10),
            AppColors.primary.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fmt.format(targetDate),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                'Calculada automáticamente · ',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary.withOpacity(0.7)),
              ),
              Text(
                '$pct% restante',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecayResultCard extends StatefulWidget {
  final double initialActivity;
  final double result;
  final RadioUnit unit;
  final Isotope isotope;
  final double elapsedHours;

  const _DecayResultCard({
    required this.initialActivity,
    required this.result,
    required this.unit,
    required this.isotope,
    required this.elapsedHours,
  });

  @override
  State<_DecayResultCard> createState() => _DecayResultCardState();
}

class _DecayResultCardState extends State<_DecayResultCard>
    with TickerProviderStateMixin {
  bool _copied = false;
  bool _saved = false;
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  void _copy(BuildContext ctx) async {
    HapticFeedback.mediumImpact();
    SoundService.instance.copy();
    final text =
        '${DecayService.formatActivity(widget.result)} ${widget.unit.label}';
    await Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final fraction = widget.result / widget.initialActivity;
    final pct = (fraction * 100).toStringAsFixed(2);
    final halfLives =
        (widget.elapsedHours / widget.isotope.halfLifeHours).toStringAsFixed(2);

    return GlassCard(
      hasBorderGlow: true,
      glowColor: AppColors.primary,
      isActive: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────
          Row(
            children: [
              IsotopePill(isotope: widget.isotope, size: IsotopePillSize.large),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actividad residual',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.primary.withOpacity(0.8),
                            letterSpacing: 0.4,
                          ),
                    ),
                    Text(widget.isotope.name,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              // Copy button with checkmark feedback
              Semantics(
                label: 'Copiar resultado',
                button: true,
                child: GestureDetector(
                  onTap: () => _copy(context),
                  child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _copied
                        ? AppColors.success.withOpacity(0.12)
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: _copied
                          ? AppColors.success.withOpacity(0.4)
                          : AppColors.border,
                    ),
                  ),
                    child: AnimatedSwitcher(
                      duration: AppMotion.exit,
                      child: _copied
                          ? const Icon(Icons.check_rounded,
                              key: ValueKey('check'),
                              size: 16,
                              color: AppColors.success)
                          : const Icon(Icons.copy_rounded,
                              key: ValueKey('copy'),
                              size: 16,
                              color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Animated result number ────────────────────────────────
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: widget.result),
            duration: const Duration(milliseconds: 1100),
            curve: AppMotion.curveEnter,
            builder: (_, value, __) => Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: _SmartNumber(formatted: DecayService.formatActivity(value))),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.unit.label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // ── Stat chips (staggered entrance) ───────────────────────
          Row(
            children: [
              _StatChip(label: 'Restante', value: '$pct%', color: AppColors.accent)
                  .animate().fadeIn(delay: 100.ms, duration: 350.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack)
                  .scale(begin: const Offset(0.82, 0.82), end: const Offset(1, 1), delay: 100.ms, duration: 350.ms, curve: Curves.easeOutBack),
              const SizedBox(width: AppSpacing.sm),
              _StatChip(label: 'Vidas medias', value: halfLives, color: AppColors.accent)
                  .animate().fadeIn(delay: 200.ms, duration: 350.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack)
                  .scale(begin: const Offset(0.82, 0.82), end: const Offset(1, 1), delay: 200.ms, duration: 350.ms, curve: Curves.easeOutBack),
              const SizedBox(width: AppSpacing.sm),
              _StatChip(
                      label: 'Reducción',
                      value: '${(100 - double.parse(pct)).toStringAsFixed(2)}%',
                      color: AppColors.primary)
                  .animate().fadeIn(delay: 300.ms, duration: 350.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack)
                  .scale(begin: const Offset(0.82, 0.82), end: const Offset(1, 1), delay: 300.ms, duration: 350.ms, curve: Curves.easeOutBack),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _DecayBar(fraction: fraction),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _DecayBar extends StatefulWidget {
  final double fraction;
  const _DecayBar({required this.fraction});

  @override
  State<_DecayBar> createState() => _DecayBarState();
}

class _DecayBarState extends State<_DecayBar>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween(begin: 0.0, end: widget.fraction)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVIDAD RESTANTE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _anim.value,
                backgroundColor: AppColors.cardHover,
                valueColor: AlwaysStoppedAnimation(
                  Color.lerp(AppColors.critical, AppColors.accent, _anim.value)!,
                ),
                minHeight: 8,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CalculateFooter extends StatelessWidget {
  final bool canCalculate;
  final bool isCalculating;
  final bool hasResult;
  final VoidCallback onTap;

  const _CalculateFooter({
    required this.canCalculate,
    required this.isCalculating,
    required this.hasResult,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (hasResult) return const SizedBox.shrink();

    const label = 'Calcular actividad residual';
    const icon = Icon(Icons.calculate_outlined, color: Colors.white, size: 18);

    return AnimatedSlide(
      offset: canCalculate ? Offset.zero : const Offset(0, 0.15),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: canCalculate
              ? GestureDetector(
                  key: const ValueKey('active'),
                  onTap: isCalculating ? null : onTap,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.40),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isCalculating)
                          const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          icon,
                        const SizedBox(width: 10),
                        Text(label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            )),
                      ],
                    ),
                  ),
                ).animate().shimmer(
                    delay: 600.ms,
                    duration: 1200.ms,
                    color: Colors.white.withOpacity(0.15),
                  )
              : Container(
                  key: const ValueKey('inactive'),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calculate_outlined,
                          color: AppColors.textSecondary.withOpacity(0.5), size: 18),
                      const SizedBox(width: 10),
                      Text(label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary.withOpacity(0.5),
                          )),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _IsotopePickerSheet extends StatelessWidget {
  final Isotope selected;
  final List<String> recentIds;
  final ScrollController scrollController;
  final ValueChanged<Isotope> onSelect;

  const _IsotopePickerSheet({
    required this.selected,
    required this.recentIds,
    required this.scrollController,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Isotope>>{};
    for (final iso in kIsotopes) {
      grouped.putIfAbsent(iso.category, () => []).add(iso);
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Center(
            child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: AppSpacing.base),
        Text('Seleccionar isótopo',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.base),
        // ── Sección Recientes ─────────────────────────────────────
        if (recentIds.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              'RECIENTES',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.accent,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...recentIds.map((id) {
            final iso = kIsotopes.firstWhere((i) => i.id == id, orElse: () => kIsotopes.first);
            return _IsotopePickerRow(
              key: ValueKey('recent_\${iso.id}'),
              iso: iso,
              isSelected: iso.id == selected.id,
              onSelect: () => onSelect(iso),
            );
          }),
          const Divider(color: AppColors.border, height: 24),
        ],
        ...grouped.entries.map((entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 4),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
                ...entry.value.asMap().entries.map((e) {
                  final iso = e.value;
                  final isSelected = iso.id == selected.id;
                  return _IsotopePickerRow(
                    key: ValueKey(iso.id),
                    iso: iso,
                    isSelected: isSelected,
                    onSelect: () => onSelect(iso),
                  );
                }),
                const SizedBox(height: AppSpacing.sm),
              ],
            )),
      ],
    );
  }
}

class _QuickTimeOption {
  final String label;
  final double hours;
  final bool isHalfLife;

  _QuickTimeOption(
      {required this.label, required this.hours, this.isHalfLife = false});
}

// ── Custom Date/Time Picker ───────────────────────────────────────────────────

class _DateTimePickerSheet extends StatefulWidget {
  final DateTime initial;
  const _DateTimePickerSheet({required this.initial});

  @override
  State<_DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<_DateTimePickerSheet>
    with TickerProviderStateMixin {
  late TabController _tab;
  late DateTime _selectedDate;
  late int _hour;
  late int _minute;
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minCtrl;

  static const _months = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
  ];
  static const _dayHeaders = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const _shortMonths = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
  ];
  static const _shortDays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _selectedDate = widget.initial;
    _hour = widget.initial.hour;
    _minute = widget.initial.minute;
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minCtrl = FixedExtentScrollController(initialItem: _minute);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    _hourCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  DateTime get _result {
    final h = _hourCtrl.hasClients ? _hourCtrl.selectedItem : _hour;
    final m = _minCtrl.hasClients ? _minCtrl.selectedItem : _minute;
    return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, h, m);
  }

  String get _confirmLabel {
    final d = _selectedDate;
    final dow = _shortDays[(d.weekday - 1) % 7];
    final mon = _shortMonths[d.month - 1];
    if (_tab.index == 0) {
      return 'Confirmar — $dow ${d.day} $mon';
    } else {
      final h = _hourCtrl.hasClients ? _hourCtrl.selectedItem : _hour;
      final m = _minCtrl.hasClients ? _minCtrl.selectedItem : _minute;
      return 'Confirmar — ${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
  }

  void _prevMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    });
  }

  void _selectDay(int day) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, day);
    });
  }

  void _goNow() {
    final now = DateTime.now();
    setState(() {
      _hour = now.hour;
      _minute = now.minute;
    });
    _hourCtrl.animateToItem(_hour,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    _minCtrl.animateToItem(_minute,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),

            // Tabs
            Container(
              margin: AppSpacing.screenPadding,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Fecha'),
                  Tab(text: 'Hora'),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.base),

            // Tab content
            SizedBox(
              height: 320,
              child: TabBarView(
                controller: _tab,
                children: [
                  _buildCalendar(),
                  _buildTimePicker(),
                ],
              ),
            ),

            // Confirm button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, _result),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.base),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _confirmLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      alignment: Alignment.center,
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final today = DateTime.now();
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    // Monday-based week offset
    int startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          // Month navigation
          Row(
            children: [
              GestureDetector(
                onTap: _prevMonth,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.chevron_left_rounded,
                      color: AppColors.textPrimary, size: 20),
                ),
              ),
              Expanded(
                child: Text(
                  '${_months[_selectedDate.month - 1]} ${_selectedDate.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _nextMonth,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textPrimary, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Day headers
          Row(
            children: _dayHeaders.map((d) => Expanded(
              child: Text(d,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 6),

          // Grid
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: startOffset + daysInMonth,
              itemBuilder: (_, i) {
                if (i < startOffset) return const SizedBox();
                final day = i - startOffset + 1;
                final isSelected = day == _selectedDate.day;
                final isToday = day == today.day &&
                    _selectedDate.month == today.month &&
                    _selectedDate.year == today.year;

                return GestureDetector(
                  onTap: () => _selectDay(day),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: AppColors.primary, width: 1.5)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? AppColors.primary
                                : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: isSelected || isToday
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker() {
    return Column(
      children: [
        // "Ahora" button
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _goNow,
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryGlow,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: const Text(
                'Ahora',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Drum roll
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hours
              SizedBox(
                width: 80,
                child: ListWheelScrollView.useDelegate(
                  controller: _hourCtrl,
                  itemExtent: 52,
                  perspective: 0.003,
                  diameterRatio: 1.8,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (v) { HapticFeedback.selectionClick(); SoundService.instance.tick(); setState(() => _hour = v); },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 24,
                    builder: (_, i) => _WheelItem(
                      label: i.toString().padLeft(2, '0'),
                      isSelected: i == _hour,
                    ),
                  ),
                ),
              ),

              // Separator
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  ':',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Minutes
              SizedBox(
                width: 80,
                child: ListWheelScrollView.useDelegate(
                  controller: _minCtrl,
                  itemExtent: 52,
                  perspective: 0.003,
                  diameterRatio: 1.8,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (v) { HapticFeedback.selectionClick(); SoundService.instance.tick(); setState(() => _minute = v); },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 60,
                    builder: (_, i) => _WheelItem(
                      label: i.toString().padLeft(2, '0'),
                      isSelected: i == _minute,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

      ],
    );
  }
}

class _WheelItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _WheelItem({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: isSelected
          ? BoxDecoration(
              color: AppColors.primaryGlow,
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
          fontSize: isSelected ? 28 : 22,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

// ── Result Reveal Sheet ───────────────────────────────────────────────────────

class _ResultRevealSheet extends StatefulWidget {
  final double result;
  final double initialActivity;
  final RadioUnit unit;
  final Isotope isotope;
  final double elapsedHours;
  final VoidCallback? onReset;

  const _ResultRevealSheet({
    required this.result,
    required this.initialActivity,
    required this.unit,
    required this.isotope,
    required this.elapsedHours,
    this.onReset,
  });

  @override
  State<_ResultRevealSheet> createState() => _ResultRevealSheetState();
}

class _ResultRevealSheetState extends State<_ResultRevealSheet>
    with TickerProviderStateMixin {
  late final AnimationController _ringCtrl;
  late final Animation<double> _ringAnim;
  AnimationController? _pulseCtrl;
  Animation<double>? _pulseAnim;
  bool _copied = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.dramatic,
    );
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: AppMotion.curveDramatic);
    _ringCtrl.forward();
    Future.delayed(const Duration(milliseconds: 950), () {
      if (mounted) setState(() => _saved = true);
    });

    final fraction = widget.result / widget.initialActivity;
    if (fraction < 0.20) {
      // Critical: haptic warning pattern + pulsing ring glow
      Future.delayed(AppMotion.dramatic, () {
        if (!mounted) return;
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) { HapticFeedback.heavyImpact(); SoundService.instance.success(); }
        });
        _pulseCtrl = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 800),
        )..repeat(reverse: true);
        _pulseAnim = CurvedAnimation(parent: _pulseCtrl!, curve: Curves.easeInOut);
        if (mounted) setState(() {});
      });
    } else if (fraction > 0.60) {
      // Healthy: single light confirmation tap
      Future.delayed(AppMotion.dramatic, () {
        if (mounted) HapticFeedback.lightImpact();
      });
    }
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _pulseCtrl?.dispose();
    super.dispose();
  }

  void _copy() async {
    HapticFeedback.lightImpact();
    SoundService.instance.copy();
    final text = '${DecayService.formatActivity(widget.result)} ${widget.unit.label}';
    await Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final fraction = widget.result / widget.initialActivity;
    final pct = (fraction * 100).toStringAsFixed(1);
    final halfLives = (widget.elapsedHours / widget.isotope.halfLifeHours).toStringAsFixed(2);
    final reduction = (100 - fraction * 100).toStringAsFixed(1);

    // Semantic color — paleta clínica: teal (viable) → indigo (atención) → naranja (crítico)
    final Color semanticColor;
    if (fraction > 0.60) {
      semanticColor = AppColors.accent;          // teal — actividad viable
    } else if (fraction > 0.20) {
      semanticColor = AppColors.primary;         // indigo — atención
    } else {
      semanticColor = AppColors.critical;        // naranja — verificar viabilidad
    }

    return Theme(
      data: AppTheme.dark,
      child: DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      snap: true,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
            child: ListView(
              controller: scrollCtrl,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              children: [
                // ── Handle ───────────────────────────────────────────
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Isotope pill + label ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IsotopePill(isotope: widget.isotope, size: IsotopePillSize.large),
                    Text(
                      'Actividad residual',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Guardado stamp ───────────────────────────────────
                AnimatedOpacity(
                  opacity: _saved ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: AnimatedSlide(
                    offset: _saved ? Offset.zero : const Offset(0, 0.3),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 13, color: AppColors.accent),
                        const SizedBox(width: 5),
                        Text(
                          'Registrado en turno',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Activity Ring + Number ────────────────────────────
                Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_ringAnim, if (_pulseAnim != null) _pulseAnim!]),
                    builder: (_, __) {
                      // Critical state: pulse glow opacity between 0.4 and 1.0
                      final glowOpacity = _pulseAnim != null
                          ? 0.4 + (_pulseAnim!.value * 0.6)
                          : 1.0;
                      return _ActivityRing(
                      fraction: fraction * _ringAnim.value,
                      semanticColor: semanticColor,
                      glowOpacity: glowOpacity,
                      size: 220,
                      strokeWidth: 16,
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: widget.result),
                              duration: AppMotion.dramatic,
                              curve: AppMotion.curveDramatic,
                              builder: (_, val, __) => FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  DecayService.formatActivity(val),
                                  style: const TextStyle(
                                    fontSize: 46,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -2.0,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              widget.unit.label,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: semanticColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // ── Pct remaining label ───────────────────────────────
                Center(
                  child: AnimatedBuilder(
                    animation: _ringAnim,
                    builder: (_, __) => Text(
                      '$pct% del total inicial',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: semanticColor.withOpacity(0.85),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Bento stat grid ───────────────────────────────────
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.25,
                  children: [
                    _BentoStat(
                      label: 'Restante',
                      value: '$pct%',
                      icon: Icons.water_drop_outlined,
                      color: semanticColor,
                    ),
                    _BentoStat(
                      label: 'Vidas medias',
                      value: halfLives,
                      icon: Icons.timelapse_rounded,
                      color: AppColors.accent,
                    ),
                    _BentoStat(
                      label: 'Reducción',
                      value: '$reduction%',
                      icon: Icons.trending_down_rounded,
                      color: AppColors.primary,   // indigo — dato informativo
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Copy button ───────────────────────────────────────
                _PressableScale(
                  onTap: _copy,
                  child: AnimatedContainer(
                    duration: AppMotion.standard,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _copied
                          ? AppColors.success.withOpacity(0.12)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: _copied
                            ? AppColors.success.withOpacity(0.4)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: AppMotion.exit,
                          child: _copied
                              ? const Icon(Icons.check_rounded,
                                  key: ValueKey('chk'),
                                  size: 18,
                                  color: AppColors.success)
                              : const Icon(Icons.copy_rounded,
                                  key: ValueKey('cpy'),
                                  size: 18,
                                  color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _copied ? 'Copiado' : 'Copiar resultado',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _copied ? AppColors.success : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── New calculation ───────────────────────────────────
                _PressableScale(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                    widget.onReset?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 18, color: Colors.white),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Nuevo cálculo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}

// ── Activity Ring ─────────────────────────────────────────────────────────────

class _ActivityRing extends StatelessWidget {
  final double fraction;
  final Color semanticColor;
  final double size;
  final double strokeWidth;
  final Widget child;
  final double glowOpacity;

  const _ActivityRing({
    required this.fraction,
    required this.semanticColor,
    required this.size,
    required this.strokeWidth,
    required this.child,
    this.glowOpacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              fraction: fraction,
              semanticColor: semanticColor,
              strokeWidth: strokeWidth,
              glowOpacity: glowOpacity,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color semanticColor;
  final double strokeWidth;
  final double glowOpacity;

  _RingPainter({
    required this.fraction,
    required this.semanticColor,
    required this.strokeWidth,
    this.glowOpacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2; // top
    final sweepAngle = math.pi * 2 * fraction.clamp(0, 1);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track — more visible
    final trackPaint = Paint()
      ..color = AppColors.cardHover.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    if (fraction <= 0) return;

    // Glow layer
    final glowPaint = Paint()
      ..color = semanticColor.withOpacity(0.28 * glowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    // Gradient arc: dimmer at start → full color at tip
    final gradientColors = [
      semanticColor.withOpacity(0.4),
      semanticColor,
    ];
    // Rotate gradient stops to match arc start (top = -π/2)
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: gradientColors,
      tileMode: TileMode.clamp,
    );
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, gradientPaint);

    // Bright dot at arc tip
    if (sweepAngle > 0.05) {
      final tipAngle = startAngle + sweepAngle;
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);
      final dotPaint = Paint()
        ..color = semanticColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(tipX, tipY), strokeWidth / 2, dotPaint);
      canvas.drawCircle(Offset(tipX, tipY), strokeWidth / 2 - 2,
          Paint()..color = Colors.white.withOpacity(0.9));
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.semanticColor != semanticColor;
}

// ── Bento Stat Chip ───────────────────────────────────────────────────────────

class _BentoStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _BentoStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.14),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 16, color: color.withOpacity(0.85)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.8,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pressable Scale wrapper ───────────────────────────────────────────────────

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.quick,
      reverseDuration: AppMotion.standard,
    );
    _scale = Tween(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: AppMotion.curveQuick),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ── Smart Number — significant digits large, noise dimmed ─────────────────────

class _SmartNumber extends StatelessWidget {
  final String formatted;
  const _SmartNumber({required this.formatted});

  @override
  Widget build(BuildContext context) {
    // Split at decimal point
    final dotIdx = formatted.indexOf('.');
    if (dotIdx == -1) {
      // Integer — just show it big
      return Text(
        formatted,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 44,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
          height: 1,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      );
    }

    final intPart = formatted.substring(0, dotIdx);
    final decPart = formatted.substring(dotIdx); // includes '.'

    // Show first 2 decimals at full size, rest dimmed and smaller
    const sigDecimals = 3; // '.XYZ'
    final String sigPart;
    final String noisePart;
    if (decPart.length <= sigDecimals + 1) {
      sigPart = decPart;
      noisePart = '';
    } else {
      sigPart = decPart.substring(0, sigDecimals + 1);
      noisePart = decPart.substring(sigDecimals + 1);
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'SF Pro Display',
          fontFeatures: [FontFeature.tabularFigures()],
          height: 1,
        ),
        children: [
          TextSpan(
            text: intPart + sigPart,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 44,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.5,
            ),
          ),
          if (noisePart.isNotEmpty)
            TextSpan(
              text: noisePart,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontSize: 28,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.5,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Fila de picker de unidad con micro-animación de press ─────────────────────
class _DecPickerUnitRow extends StatefulWidget {
  final RadioUnit unit;
  final bool isSelected;
  final int index;
  final VoidCallback onSelect;

  const _DecPickerUnitRow({
    super.key,
    required this.unit,
    required this.isSelected,
    required this.index,
    required this.onSelect,
  });

  @override
  State<_DecPickerUnitRow> createState() => _DecPickerUnitRowState();
}

class _DecPickerUnitRowState extends State<_DecPickerUnitRow>
    with SingleTickerProviderStateMixin {
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
    await _ctrl.forward(from: 0);
    widget.onSelect();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.unit;
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
                  color: AppColors.primary.withOpacity(_bgOpacity.value * 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            ListTile(
              dense: true,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              tileColor: isSelected
                  ? AppColors.primary.withOpacity(0.06)
                  : Colors.transparent,
              leading: Transform.scale(
                scale: 0.88 + (_scale.value - 0.93).clamp(0.0, 0.07) / 0.07 * 0.12,
                child: Container(
                  width: 48,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.12)
                        : AppColors.cardHover,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.45)
                          : AppColors.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    u.label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              title: Text(u.fullName,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14)),
              trailing: isSelected
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 18)
                  : null,
              onTap: _handleTap,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 30 * widget.index),
          duration: 200.ms,
        );
  }
}

// ── Fila de isotopo con micro-animación de press ──────────────────────────────
class _IsotopePickerRow extends StatefulWidget {
  final Isotope iso;
  final bool isSelected;
  final VoidCallback onSelect;

  const _IsotopePickerRow({
    super.key,
    required this.iso,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<_IsotopePickerRow> createState() => _IsotopePickerRowState();
}

class _IsotopePickerRowState extends State<_IsotopePickerRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _bgOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 170));
    _scale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.92)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 0.92, end: 1.0)
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
    await _ctrl.forward(from: 0);
    widget.onSelect();
  }

  @override
  Widget build(BuildContext context) {
    final iso = widget.iso;
    final isSelected = widget.isSelected;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Stack(
          children: [
            // Flash con el color del isotopo
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: iso.color.withOpacity(_bgOpacity.value * 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            ListTile(
              dense: true,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              tileColor: isSelected
                  ? iso.color.withOpacity(0.08)
                  : Colors.transparent,
              leading: Transform.scale(
                scale: 0.88 + (_scale.value - 0.92).clamp(0.0, 0.08) / 0.08 * 0.12,
                child: IsotopePill(isotope: iso),
              ),
              title: Text(iso.name,
                  style: TextStyle(
                      color: isSelected
                          ? iso.color
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500)),
              subtitle: Text(iso.halfLifeDisplay,
                  style: Theme.of(context).textTheme.bodySmall),
              trailing: isSelected
                  ? Icon(Icons.check_circle_rounded,
                      color: iso.color, size: 18)
                  : null,
              onTap: _handleTap,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Último resultado de decaimiento ───────────────────────────────────────────
class _DecayLastResultChip extends StatelessWidget {
  final String value;
  final RadioUnit unit;
  final Isotope isotope;
  final double initialActivity;
  const _DecayLastResultChip({
    required this.value, required this.unit,
    required this.isotope, required this.initialActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('Último: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              '$value ${unit.label}',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            isotope.symbol,
            style: TextStyle(fontSize: 11, color: isotope.color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
