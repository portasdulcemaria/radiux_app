import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/nuclear_background.dart';
import '../widgets/radiux_app_bar.dart';
import 'package:provider/provider.dart';
import '../services/language_provider.dart';
import '../l10n/app_strings.dart';
import 'conversion/conversion_screen.dart';
import 'decaimiento/decaimiento_screen.dart';
import 'history/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _switchTab(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      drawer: _SettingsDrawer(),
      appBar: RadiuxAppBar(
        title: 'Radiux',
        showMenuButton: false,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, size: 22, color: AppColors.textSecondary),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'Menú',
        ),
        actions: [_InfoButton(context: context)],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedNuclearBackground(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: IndexedStack(
              key: ValueKey(_currentIndex),
              index: _currentIndex,
              children: [
                const ConversionScreen(),
                const DecaimientoScreen(),
                HistoryScreen(onGoToDecaimiento: () => _switchTab(1)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _RadiuxBottomNav(
        currentIndex: _currentIndex,
        onTap: _switchTab,
      ),
    );
  }
}

class _RadiuxBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _RadiuxBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.swap_horiz_rounded,
                label: s.unitConversion,
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.science_outlined,
                label: s.radioactiveDecay,
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: s.shiftActivity,
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryGlow : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Info button ───────────────────────────────────────────────────────────────
class _InfoButton extends StatelessWidget {
  final BuildContext context;
  const _InfoButton({required this.context});

  @override
  Widget build(BuildContext _) {
    return IconButton(
      icon: const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.textSecondary),
      onPressed: () => _showInfoSheet(context),
      tooltip: 'Acerca de',
    );
  }

  void _showInfoSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.92,
        minChildSize: 0.35,
        expand: false,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Radiux v2.0',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text(
                'Calculadora de medicina nuclear para conversión de unidades de actividad radiactiva y cálculo de decaimiento por isótopo. Desarrollada para uso clínico supervisado.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 24),
              _InfoTile(
                icon: Icons.gavel_rounded,
                label: 'Términos y condiciones',
                onTap: () => _showLegal(ctx, 'Términos y condiciones', _kTerminos),
              ),
              _InfoTile(
                icon: Icons.shield_outlined,
                label: 'Política de privacidad',
                onTap: () => _showLegal(ctx, 'Política de privacidad', _kPrivacidad),
              ),
              const SizedBox(height: 16),
              const Text(
                'Uso clínico supervisado',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLegal(BuildContext ctx, String title, String body) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, sc) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: sc,
                  child: Text(body, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _InfoTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 18, color: AppColors.textSecondary),
      title: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

const _kTerminos = '''
Términos y condiciones de uso — Radiux v2.0

1. Uso informativo
Radiux es una herramienta de apoyo clínico para profesionales de Medicina Nuclear. Los cálculos no reemplazan el criterio médico ni los protocolos institucionales vigentes.

2. Responsabilidad
El usuario es responsable de verificar los valores obtenidos antes de su aplicación clínica. Los desarrolladores no asumen responsabilidad por errores derivados de un uso incorrecto.

3. Licencia
Esta aplicación es de uso exclusivo del profesional o institución que la ha obtenido. Está prohibida su redistribución o modificación sin autorización expresa.

4. Actualizaciones
Los términos pueden actualizarse sin previo aviso. Se recomienda revisar periódicamente esta sección.
''';

const _kPrivacidad = '''
Política de privacidad — Radiux v2.0

1. Datos recopilados
Radiux no recopila, almacena ni transmite datos personales de pacientes ni del usuario. Todos los cálculos se procesan localmente en el dispositivo.

2. Datos de uso
La aplicación puede registrar métricas anónimas de uso para mejorar la experiencia. Ningún dato es identificable.

3. Almacenamiento local
Las preferencias del usuario se almacenan exclusivamente en el dispositivo y no son compartidas.

4. Terceros
Radiux no comparte datos con terceros ni integra servicios de análisis externos.
''';

// ── Settings Drawer ───────────────────────────────────────────────────────────
class _SettingsDrawer extends StatelessWidget {
  const _SettingsDrawer();

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ajustes',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Radiux v2.0',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border, height: 1),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerSection('Idioma'),
                  ...AppStrings.supportedLanguages.map((lang) {
                    final isSelected = langProvider.locale.languageCode == lang.code;
                    return ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      tileColor: isSelected ? AppColors.primaryGlow : Colors.transparent,
                      leading: Text(lang.flag, style: const TextStyle(fontSize: 22)),
                      title: Text(lang.nativeName,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                        )),
                      subtitle: Text(lang.name,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: isSelected
                        ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18)
                        : null,
                      onTap: () {
                        context.read<LanguageProvider>().setLocale(lang.locale);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Text('Uso clínico supervisado',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String label;
  const _DrawerSection(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      child: Text(label.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          letterSpacing: 1.2, color: AppColors.textSecondary)),
    );
  }
}
