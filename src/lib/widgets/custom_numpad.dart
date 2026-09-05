import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Teclado numérico custom — reemplaza el teclado del sistema.
/// Usar con TextField(readOnly: true).
class CustomNumpad extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onDone;
  final VoidCallback? onChanged;
  final String doneLabel;

  const CustomNumpad({
    super.key,
    required this.controller,
    required this.onDone,
    this.onChanged,
    this.doneLabel = "Calcular",
  });

  void _press(String key) {
    HapticFeedback.selectionClick();
    final text = controller.text;
    if (key == '⌫') {
      if (text.isNotEmpty) {
        controller.text = text.substring(0, text.length - 1);
        controller.selection = TextSelection.collapsed(offset: controller.text.length);
      }
    } else if (key == '.') {
      if (!text.contains('.') && !text.contains(',')) {
        controller.text = text.isEmpty ? '0.' : '$text.';
        controller.selection = TextSelection.collapsed(offset: controller.text.length);
      }
    } else {
      final digits = text.replaceAll('.', '').replaceAll(',', '').length;
      if (digits < 8) {
        controller.text = '$text$key';
        controller.selection = TextSelection.collapsed(offset: controller.text.length);
      }
    }
    onChanged?.call();
  }

  Widget _key(String label, {Color? textColor, bool wide = false, VoidCallback? customAction}) {
    final isDone = label == doneLabel;
    final isDel  = label == '⌫';
    return Expanded(
      flex: wide ? 2 : 1,
      child: GestureDetector(
        onTap: customAction ?? () => _press(label),
        child: Container(
          margin: const EdgeInsets.all(4),
          height: 56,
          decoration: BoxDecoration(
            color: isDone ? AppColors.primary : isDel ? AppColors.cardHover : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDone ? AppColors.primary : AppColors.border),
            boxShadow: isDone
                ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Center(
            child: isDel
                ? const Icon(Icons.backspace_outlined, color: AppColors.textSecondary, size: 18)
                : Text(
                    label,
                    style: TextStyle(
                      color: isDone ? Colors.white : (textColor ?? AppColors.textPrimary),
                      fontSize: isDone ? 15 : 20,
                      fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      padding: EdgeInsets.fromLTRB(8, 8, 8, bottomPad + 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [_key('7'), _key('8'), _key('9')]),
          Row(children: [_key('4'), _key('5'), _key('6')]),
          Row(children: [_key('1'), _key('2'), _key('3')]),
          Row(children: [
            _key('.', textColor: AppColors.textSecondary),
            _key('0'),
            _key('⌫'),
          ]),
          Row(children: [
            _key(doneLabel, wide: true, customAction: () {
              HapticFeedback.lightImpact();
              onDone();
            }),
          ]),
        ],
      ),
    );
  }
}
