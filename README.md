# Radiux v2.0 — App de Medicina Nuclear

App nativa Flutter para conversión de unidades de actividad radiactiva y cálculo de decaimiento radioactivo.

## Stack
- **Flutter** (Dart) — cross-platform iOS + Android
- **flutter_animate** — microanimaciones Vercel-style
- **google_fonts** — tipografía Inter
- **intl** — formato de fechas en español

## Pantallas

| Pantalla | Descripción |
|----------|-------------|
| `SplashScreen` | Onboarding con animaciones de entrada escalonadas |
| `ConversionScreen` | Conversión entre 10 unidades de actividad |
| `DecaimientoScreen` | Cálculo de decaimiento con 12 isótopos clínicos |
| `RadiuxDrawer` | Menú lateral con navegación y secciones futuras |

## Isótopos incluidos

- ⁹⁹ᵐTc · Tecnecio 99m (T½ = 6.01h) — SPECT
- ¹³¹I · Yodo 131 (T½ = 8.02d) — Terapia
- ¹²³I · Yodo 123 (T½ = 13.22h) — SPECT
- ¹⁸F · Flúor 18 (T½ = 109.8min) — PET
- ⁶⁷Ga · Galio 67 (T½ = 78.26h) — SPECT
- ⁶⁸Ga · Galio 68 (T½ = 67.7min) — PET
- ¹⁷⁷Lu · Lutecio 177 (T½ = 6.6d) — Terapia
- ²⁰¹Tl · Talio 201 (T½ = 3.04d) — SPECT
- ¹¹¹In · Indio 111 (T½ = 67.3h) — SPECT
- ⁹⁰Y · Itrio 90 (T½ = 64.05h) — Terapia
- ²²³Ra · Radio 223 (T½ = 11.39d) — Terapia

## Fórmula de decaimiento

```
A(t) = A₀ × 2^(−t / T½)
```

## Setup

```bash
flutter pub get
flutter run
```

## Decisiones de diseño

- **Referencia visual**: Vercel — glassmorphism, gradient borders animados, glow effects
- **Tema**: Dark-only, con paleta indigo + teal
- **Microanimaciones**: spring curves, scale on press, staggered entry
- **UX**: HapticFeedback en todas las interacciones, resultados inline, copia al portapapeles
