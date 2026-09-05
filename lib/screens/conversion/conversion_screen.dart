import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/sound_service.dart';
import '../../widgets/custom_numpad.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/unit.dart';
import '../../models/decay_service.dart';
import '../../theme/app_theme.dart';

// ─── Local palette ────────────────────────────────────────────────────────────
// _k* constants replaced with AppColors for dark theme consistency

class ConversionScreen extends StatefulWidget {
  const ConversionScreen({super.key});

  @override
  State<ConversionScreen> createState() => _ConversionScreenState();
}

class _ConversionScreenState extends State<ConversionScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _inputController = TextEditingController();
  final _focusNode       = FocusNode();
  Timer? _debounce;

  RadioUnit _fromUnit = kUnits.first;
  RadioUnit _toUnit   = kUnits[4];

  double? _result;
  double? _resultMBq;  // mismo cálculo en MBq para panel multi-unidad
  double? _lastResult;
  RadioUnit? _lastFromUnit;
  RadioUnit? _lastToUnit;
  String? _errorText;

  bool get _hasInput => _inputController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
    _focusNode.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {
      _errorText = null;
      if (_inputController.text.isEmpty) _result = null;
    });
    _debounce?.cancel();
    if (_inputController.text.isNotEmpty) {
      _debounce = Timer(const Duration(milliseconds: 350), _convertLive);
    }
  }

  void _convertLive() {
    final text  = _inputController.text.replaceAll(',', '.');
    final value = double.tryParse(text);
    if (value == null) return;
    if (value <= 0) {
      setState(() => _errorText = 'Ingresa un valor mayor a cero');
      return;
    }
    final result = DecayService.convert(value, _fromUnit, _toUnit);
    final mbqVal = value * _fromUnit.toMBq;
    setState(() {
      _result = result;
      _resultMBq = mbqVal;
      _lastResult = result;
      _lastFromUnit = _fromUnit;
      _lastToUnit = _toUnit;
    });
  }

  void _clear() {
    HapticFeedback.selectionClick();
    _debounce?.cancel();
    _inputController.clear();
    setState(() { _result = null; _resultMBq = null; _errorText = null; });
    _focusNode.requestFocus();
  }

  void _swapUnits() {
    setState(() {
      final tmp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit   = tmp;
      _result   = null;
    });
    if (_hasInput) _convertLive();
  }

  void _onUnitChanged(RadioUnit unit, bool isFrom) {
    setState(() {
      if (isFrom) _fromUnit = unit;
      else        _toUnit   = unit;
      _result = null;
    });
    if (_hasInput) _convertLive();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () { _focusNode.unfocus(); setState(() {}); },
          child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
          _focusNode.hasFocus
              ? MediaQuery.of(context).size.height * 0.48
              : AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Convertir',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 12),

            _ActivityInput(
              controller: _inputController,
              focusNode:  _focusNode,
              hasError:   _errorText != null,
              hasInput:   _hasInput,
              onClear:    _clear,
              fromUnit:   _fromUnit,
            ).animate().fadeIn(delay: 60.ms),

            if (_errorText != null)
              _ErrorRow(text: _errorText!)
                  .animate().fadeIn(duration: 200.ms).shakeX(amount: 4, hz: 4),

            const SizedBox(height: 20),

            _UnitRow(
              fromUnit:  _fromUnit,
              toUnit:    _toUnit,
              onFromTap: () => _showUnitPicker(isFrom: true),
              onToTap:   () => _showUnitPicker(isFrom: false),
              onSwap:    _swapUnits,
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 16),
            _RatioHint(fromUnit: _fromUnit, toUnit: _toUnit),

            // Chip de último resultado — visible cuando no hay cálculo activo
            if (_result == null && _lastResult != null) ...[
              const SizedBox(height: 20),
              _LastResultChip(
                value: DecayService.formatActivity(_lastResult!),
                fromLabel: _lastFromUnit!.label,
                toLabel: _lastToUnit!.label,
              ),
            ],

            if (_result != null) ...[
              const SizedBox(height: 32),
              _InlineResult(
                result: DecayService.formatActivity(_result!),
                toLabel: _toUnit.label,
                fromText: _inputController.text,
                fromLabel: _fromUnit.label,
              ).animate().fadeIn(duration: 300.ms).slideY(
                begin: 0.15, end: 0,
                duration: 350.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 12),
              _AllUnitsPanel(
                valueMBq: _resultMBq ?? _result!,
                highlightFromId: _fromUnit.id,
                highlightToId: _toUnit.id,
              ).animate().fadeIn(delay: 120.ms, duration: 300.ms)
               .slideY(begin: 0.1, end: 0, delay: 120.ms, duration: 300.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _clear();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
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
                      SizedBox(width: 8),
                      Text(
                        'Nueva conversión',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
            ],
          ],
        ),
      ),
    ),
    if (_focusNode.hasFocus)
      Positioned(
        left: 0, right: 0, bottom: 0,
        child: CustomNumpad(
          controller: _inputController,
          onDone: () { _focusNode.unfocus(); setState(() {}); },
          onChanged: () => setState(() {}),
          doneLabel: 'Convertir',
        ),
      ),
  ],
  );
  }

  void _showUnitPicker({required bool isFrom}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _UnitPickerSheet(
          selected:         isFrom ? _fromUnit : _toUnit,
          excluded:         isFrom ? _toUnit   : _fromUnit,
          scrollController: scrollController,
          onSelect: (unit) {
            HapticFeedback.selectionClick();
            _onUnitChanged(unit, isFrom);
            Navigator.pop(context);
          },
        ),
        ),
      ),
    );
  }
}

// ── Inline Result ────────────────────────────────────────────────────────────

class _InlineResult extends StatefulWidget {
  final String result;
  final String toLabel;
  final String fromText;
  final String fromLabel;

  const _InlineResult({
    required this.result,
    required this.toLabel,
    required this.fromText,
    required this.fromLabel,
  });

  @override
  State<_InlineResult> createState() => _InlineResultState();
}

class _InlineResultState extends State<_InlineResult> {
  bool _copied = false;

  void _copy() async {
    HapticFeedback.mediumImpact();
    SoundService.instance.copy();
    await Clipboard.setData(
        ClipboardData(text: '${widget.result} ${widget.toLabel}'));
    setState(() => _copied = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withOpacity(0.10),
            AppColors.accent.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.accent.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(color: AppColors.accent.withOpacity(0.08), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // From echo
          Text(
            '${widget.fromText} ${widget.fromLabel}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
          ),

          const SizedBox(height: AppSpacing.xs),
          const Icon(Icons.arrow_downward_rounded,
              size: 14, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.sm),

          // Result value
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
                      child: child,
                    ),
                  ),
                  child: Text(
                    widget.result,
                    key: ValueKey(widget.result),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.5,
                      height: 1,
                    ),
                  ),
                ),
              ),
              Text(
                widget.toLabel,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Copy button
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            decoration: BoxDecoration(
              color: _copied
                  ? AppColors.success.withOpacity(0.12)
                  : AppColors.primary.withOpacity(0.10),
              border: Border.all(
                color: _copied ? AppColors.success : AppColors.primary,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: TextButton(
              onPressed: _copied ? null : _copy,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 16,
                    color: _copied ? AppColors.success : AppColors.primary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _copied ? 'Copiado' : 'Copiar resultado',
                    style: TextStyle(
                      color: _copied ? AppColors.success : AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity Input with pulsing border ───────────────────────────────────────

class _ActivityInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool hasInput;
  final VoidCallback onClear;
  final RadioUnit fromUnit;

  const _ActivityInput({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.hasInput,
    required this.onClear,
    required this.fromUnit,
  });

  @override
  State<_ActivityInput> createState() => _ActivityInputState();
}

class _ActivityInputState extends State<_ActivityInput>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    widget.focusNode.addListener(_onFocusChange);
    if (widget.focusNode.hasFocus) _pulseCtrl.repeat(reverse: true);
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus) {
      _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) {
        final borderOpacity = isFocused
            ? 0.40 + 0.35 * _pulseAnim.value  // pulsa entre 0.40 y 0.75
            : 0.0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.hasError
                  ? AppColors.error.withOpacity(0.7)
                  : isFocused
                      ? AppColors.primary.withOpacity(borderOpacity)
                      : AppColors.border,
              width: widget.hasError || isFocused ? 1.5 : 1,
            ),
            color: AppColors.card,
            boxShadow: [
              BoxShadow(
                color: isFocused
                    ? AppColors.primary.withOpacity(0.06 + 0.06 * _pulseAnim.value)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isFocused ? 18 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Center(
              child: Text(
                widget.fromUnit.fullName,
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode:  widget.focusNode,
                  readOnly: true,
                  showCursor: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.5,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: '',
                    border:        InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(16, 14, 16, 14),
                    filled: false,
                  ),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }
}

// ── Unit row con flip 3D en swap ─────────────────────────────────────────────

class _UnitRow extends StatefulWidget {
  final RadioUnit fromUnit;
  final RadioUnit toUnit;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onSwap;

  const _UnitRow({
    required this.fromUnit,
    required this.toUnit,
    required this.onFromTap,
    required this.onToTap,
    required this.onSwap,
  });

  @override
  State<_UnitRow> createState() => _UnitRowState();
}

class _UnitRowState extends State<_UnitRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipCtrl;
  late final Animation<double>   _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _flipAnim = CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _handleSwap() {
    HapticFeedback.selectionClick();
    SoundService.instance.swap();
    _flipCtrl.forward(from: 0);
    // Swap de datos en el midpoint de la animación
    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted) widget.onSwap();
    });
    // Segundo haptic al aterrizar
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) HapticFeedback.lightImpact();
    });
  }

  Widget _chip({
    required String dirLabel,
    required RadioUnit unit,
    required Color accentColor,
    required VoidCallback onTap,
    required bool isLeft,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.12),
                  accentColor.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.base),
              border: Border.all(color: accentColor.withOpacity(0.28)),
              boxShadow: [
                BoxShadow(
                    color: accentColor.withOpacity(0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dirLabel,
                    style: TextStyle(
                        color: accentColor.withOpacity(0.7), fontSize: 11, letterSpacing: 0.3, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Row(children: [
                  Text(unit.label,
                      style: TextStyle(
                          color: accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3)),
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more_rounded,
                      size: 14, color: accentColor.withOpacity(0.6)),
                ]),
                Text(unit.fullName,
                    style: TextStyle(color: accentColor.withOpacity(0.55), fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip(
          dirLabel:    'Desde',
          unit:        widget.fromUnit,
          accentColor: AppColors.primary,
          onTap:       widget.onFromTap,
          isLeft:      true,
        ),

        // Swap button con rotation propia
        AnimatedBuilder(
          animation: _flipAnim,
          builder: (_, child) => Transform.rotate(
            angle: _flipAnim.value * math.pi * 2,
            child: child,
          ),
          child: GestureDetector(
            onTap: _handleSwap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.swap_horiz_rounded,
                  size: 16, color: Colors.white),
            ),
          ),
        ),

        _chip(
          dirLabel:    'Hacia',
          unit:        widget.toUnit,
          accentColor: AppColors.accent,
          onTap:       widget.onToTap,
          isLeft:      false,
        ),
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String text;
  const _ErrorRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
        const SizedBox(width: 6),
        Text(text,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.error)),
      ]),
    );
  }
}

// ── Result Sheet con backdrop blur ───────────────────────────────────────────


// ── Unit Picker Sheet ─────────────────────────────────────────────────────────

class _UnitPickerSheet extends StatelessWidget {
  final RadioUnit selected;
  final RadioUnit excluded;
  final ValueChanged<RadioUnit> onSelect;
  final ScrollController scrollController;

  const _UnitPickerSheet({
    required this.selected,
    required this.excluded,
    required this.onSelect,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
        const SizedBox(height: 16),
        Text('Seleccioná unidad',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ...kUnits.asMap().entries.map((e) {
          final unit       = e.value;
          final isSelected = unit.id == selected.id;
          final isExcluded = unit.id == excluded.id;
          return _PickerUnitRow(
            key: ValueKey(unit.id),
            unit: unit,
            isSelected: isSelected,
            isExcluded: isExcluded,
            index: e.key,
            onSelect: isExcluded ? null : () => onSelect(unit),
          );
        }),
      ],
    );
  }
}

// Fila con micro-animación de press antes de confirmar la selección
class _PickerUnitRow extends StatefulWidget {
  final RadioUnit unit;
  final bool isSelected;
  final bool isExcluded;
  final int index;
  final VoidCallback? onSelect;

  const _PickerUnitRow({
    super.key,
    required this.unit,
    required this.isSelected,
    required this.isExcluded,
    required this.index,
    this.onSelect,
  });

  @override
  State<_PickerUnitRow> createState() => _PickerUnitRowState();
}

class _PickerUnitRowState extends State<_PickerUnitRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _bgOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 160));
    // Scale: 1.0 → 0.93 → 1.0 (punch)
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
    // BG flash: 0 → 1 → 0
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
    if (widget.onSelect == null) return;
    await _ctrl.forward(from: 0);
    widget.onSelect?.call();
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.unit;
    final isSelected = widget.isSelected;
    final isExcluded = widget.isExcluded;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => AnimatedScale(
        scale: _scale.value,
        duration: Duration.zero, // AnimationController handles timing
        child: Stack(
          children: [
            // Flash de confirmación
            Positioned.fill(
              child: AnimatedContainer(
                duration: Duration.zero,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withOpacity(_bgOpacity.value * 0.18),
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
              enabled: !isExcluded,
              leading: AnimatedScale(
                scale: _scale.value < 1.0
                    ? 0.88 + (_scale.value - 0.93) / (1.0 - 0.93) * 0.12
                    : 1.0,
                duration: Duration.zero,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.08)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.35)
                          : AppColors.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unit.label,
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
              title: Text(
                unit.fullName,
                style: TextStyle(
                  color: isExcluded
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 18)
                  : null,
              onTap: isExcluded ? null : _handleTap,
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

// ── Ratio hint — muestra el factor de conversión cuando no hay resultado ──────
class _LastResultChip extends StatelessWidget {
  final String value;
  final String fromLabel;
  final String toLabel;
  const _LastResultChip({required this.value, required this.fromLabel, required this.toLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            'Último: ',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              '$value $toLabel',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '← $fromLabel',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}

class _RatioHint extends StatelessWidget {
  final RadioUnit fromUnit;
  final RadioUnit toUnit;

  const _RatioHint({required this.fromUnit, required this.toUnit});

  @override
  Widget build(BuildContext context) {
    final ratio = DecayService.convert(1.0, fromUnit, toUnit);
    final formatted = DecayService.formatActivity(ratio);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '1 ${fromUnit.label}',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward_rounded,
                size: 13, color: AppColors.textSecondary),
          ),
          Text(
            '$formatted ${toUnit.label}',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Panel multi-unidades: referencia rápida clínica ───────────────────────────
// Muestra el valor en las 5 unidades más usadas en Medicina Nuclear.
// Se resaltan FROM y TO seleccionados para dar contexto visual.

class _AllUnitsPanel extends StatelessWidget {
  final double valueMBq;      // valor ya convertido a MBq
  final String highlightFromId;
  final String highlightToId;

  const _AllUnitsPanel({
    required this.valueMBq,
    required this.highlightFromId,
    required this.highlightToId,
  });

  // Unidades de referencia clínica — ids en orden de uso habitual en NM.
  // Factores derivados de kUnits.toMBq para garantizar consistencia con el modelo.
  static const _refIds = ['gbq', 'mbq', 'mci', 'uci', 'kbq'];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view_rounded, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                'Referencia rápida',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _refIds.map((id) {
              final unit = kUnits.firstWhere((u) => u.id == id);
              final isHighlighted = id == highlightFromId || id == highlightToId;
              final converted = valueMBq / unit.toMBq;
              final formatted = DecayService.formatActivity(converted);

              return Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: 7),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? AppColors.primary.withOpacity(0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isHighlighted
                        ? AppColors.primary.withOpacity(0.35)
                        : AppColors.border,
                    width: isHighlighted ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatted,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isHighlighted ? AppColors.primaryLight : AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      unit.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isHighlighted
                            ? AppColors.primaryLight.withOpacity(0.75)
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
