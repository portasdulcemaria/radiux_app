import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'radiation_icon.dart';

class RadiuxDrawer extends StatelessWidget {
  /// Callback para navegar a un tab del HomeScreen.
  /// 0 = Conversión, 1 = Decaimiento, 2 = Actividad, 3 = Turno
  final void Function(int tabIndex)? onNavigate;

  const RadiuxDrawer({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const RadiationIcon(
                          size: 24,
                          color: Colors.white,
                          glowColor: Color(0x665C5CFF),
                          glowBlur: 6,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Radiux',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Medicina Nuclear',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg),
                  const Divider(color: AppColors.border, height: 1),
                ],
              ),
            ),

            // ── Nav items ────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Calculadoras'),
                    SizedBox(height: AppSpacing.xs),
                    _DrawerItem(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Conversión de unidades',
                      color: AppColors.primary,
                      onTap: () => onNavigate?.call(0),
                    ).animate().fadeIn(delay: 60.ms, duration: 220.ms).slideX(begin: -0.08, end: 0),
                    _DrawerItem(
                      icon: Icons.science_outlined,
                      label: 'Decaimiento radiactivo',
                      color: AppColors.accent,
                      onTap: () => onNavigate?.call(1),
                    ).animate().fadeIn(delay: 100.ms, duration: 220.ms).slideX(begin: -0.08, end: 0),
                    SizedBox(height: AppSpacing.base),
                    _SectionLabel('Registros'),
                    SizedBox(height: AppSpacing.xs),
                    _DrawerItem(
                      icon: Icons.history_rounded,
                      label: 'Actividad del turno',
                      color: AppColors.textSecondary,
                      onTap: () => onNavigate?.call(2),
                    ).animate().fadeIn(delay: 140.ms, duration: 220.ms).slideX(begin: -0.08, end: 0),
                    SizedBox(height: AppSpacing.base),
                    _SectionLabel('Preferencias'),
                    SizedBox(height: AppSpacing.xs),
                    _DrawerItem(
                      icon: Icons.settings_outlined,
                      label: 'Configuración',
                      color: AppColors.textSecondary,
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon(context, 'Configuración');
                      },
                    ).animate().fadeIn(delay: 180.ms, duration: 220.ms).slideX(begin: -0.08, end: 0),
                    SizedBox(height: AppSpacing.base),
                    _SectionLabel('Legal'),
                    SizedBox(height: AppSpacing.xs),
                    _DrawerItem(
                      icon: Icons.gavel_rounded,
                      label: 'Términos y condiciones',
                      color: AppColors.textSecondary,
                      onTap: () {
                        Navigator.pop(context);
                        _showLegal(context, 'Términos y condiciones', _kTerminos);
                      },
                    ).animate().fadeIn(delay: 220.ms, duration: 220.ms).slideX(begin: -0.08, end: 0),
                    _DrawerItem(
                      icon: Icons.shield_outlined,
                      label: 'Política de privacidad',
                      color: AppColors.textSecondary,
                      onTap: () {
                        Navigator.pop(context);
                        _showLegal(context, 'Política de privacidad', _kPrivacidad);
                      },
                    ).animate().fadeIn(delay: 260.ms, duration: 220.ms).slideX(begin: -0.08, end: 0),
                    _DrawerItem(
                      icon: Icons.info_outline_rounded,
                      label: 'Acerca de Radiux',
                      color: AppColors.textSecondary,
                      onTap: () {
                        Navigator.pop(context);
                        _showAbout(context);
                      },
                    ).animate().fadeIn(delay: 300.ms, duration: 220.ms).slideX(begin: -0.08, end: 0),
                    SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),

            // ── Footer ────────────────────────────────────────────────────────
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Text(
                'Radiux v2.0 · Uso clínico supervisado',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Radiux v2.0'),
        content: const Text(
          'Calculadora de medicina nuclear para conversión de unidades de actividad radiactiva y cálculo de decaimiento por isótopo.\n\nDesarrollada para uso clínico supervisado en servicios de Medicina Nuclear.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text(feature),
        content: Text('$feature estará disponible en una próxima versión de Radiux.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showLegal(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
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
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.base),
              Expanded(
                child: SingleChildScrollView(
                  controller: sc,
                  child: Text(
                    body,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
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

5. Contacto
Para reportar errores o sugerencias, contactar al equipo de desarrollo a través de los canales oficiales de la institución.
''';

const _kPrivacidad = '''
Política de privacidad — Radiux v2.0

1. Datos recopilados
Radiux no recopila, almacena ni transmite datos personales de pacientes ni del usuario. Todos los cálculos se procesan localmente en el dispositivo.

2. Datos de uso
La aplicación puede registrar métricas anónimas de uso (funcionalidades utilizadas, frecuencia) para mejorar la experiencia. Ningún dato es identificable.

3. Almacenamiento local
Las preferencias del usuario (unidades por defecto, isótopos frecuentes) se almacenan exclusivamente en el dispositivo y no son compartidas.

4. Terceros
Radiux no comparte datos con terceros ni integra servicios de análisis externos que puedan comprometer la privacidad.

5. Cumplimiento
Esta aplicación cumple con las normativas de protección de datos aplicables en el ámbito sanitario de la región de uso.
''';

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final String? badge;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.color,
    this.isActive = false,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        tileColor: isActive ? AppColors.primaryGlow : Colors.transparent,
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: color.withOpacity(0.12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isActive ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cardHover,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
