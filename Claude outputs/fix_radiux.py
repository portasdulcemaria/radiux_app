#!/usr/bin/env python3
"""Script de fix directo para Radiux — reemplaza tokens y corrige bugs."""
import re, sys, os

PROJ = os.path.expanduser("~/Desktop/radiux_app/radiux")

def fix(path, replacements):
    full = os.path.join(PROJ, path)
    with open(full, 'r') as f:
        src = f.read()
    orig = src
    for old, new in replacements:
        src = src.replace(old, new)
    if src == orig:
        print(f"  [sin cambios] {path}")
    else:
        with open(full, 'w') as f:
            f.write(src)
        print(f"  [OK] {path}")

print("=== Radiux Fix Script ===\n")

# 1. nuclear_background.dart — quitar BlendMode.plus
fix("lib/widgets/nuclear_background.dart", [
    ("..blendMode = BlendMode.plus;", "..blendMode = BlendMode.srcOver;"),
    (".blendMode = BlendMode.plus", ".blendMode = BlendMode.srcOver"),
])

# 2. glass_card.dart — tokens inválidos
fix("lib/widgets/glass_card.dart", [
    ("AppColors.textTertiary", "AppColors.textSecondary"),
    ("AppColors.shadowColor", "const Color(0x26000000)"),
    ("AppColors.cardAlt", "AppColors.cardHover"),
    ("Colors.black.withOpacity(0.15)", "const Color(0x26000000)"),
    ("AppColors.card.withOpacity(0.97)", "AppColors.card"),
    ("AppColors.surface.withOpacity(0.93)", "AppColors.surface"),
])

# 3. radiux_drawer.dart — tokens inválidos
fix("lib/widgets/radiux_drawer.dart", [
    ("AppColors.textTertiary", "AppColors.textSecondary"),
    ("AppColors.textDisabled", "AppColors.textSecondary"),
])

# 4. decaimiento_screen.dart — tokens inválidos + quitar ShaderMask problemático
decai_path = os.path.join(PROJ, "lib/screens/decaimiento/decaimiento_screen.dart")
with open(decai_path, 'r') as f:
    src = f.read()

orig = src
# Tokens inválidos
src = src.replace("AppColors.primarySubtle", "AppColors.primaryGlow")
src = src.replace("AppColors.textTertiary", "AppColors.textSecondary")
src = src.replace("AppColors.textDisabled", "AppColors.textSecondary")

# Quitar ShaderMask (shimmer) que crashea en iOS release
# Reemplazar el bloque AnimatedBuilder con ShaderMask por simple Text
shimmer_pattern = re.compile(
    r'AnimatedBuilder\(\s*animation: _shimmerCtrl,\s*builder: \(_, child\) \{.*?return ShaderMask\(.*?child: child!,\s*\);\s*\},\s*child: (Text\([^;]+;\s*\)),\s*\)',
    re.DOTALL
)
def replace_shimmer(m):
    return m.group(1)  # solo el Text, sin ShaderMask
src = shimmer_pattern.sub(replace_shimmer, src)

if src != orig:
    with open(decai_path, 'w') as f:
        f.write(src)
    print("  [OK] lib/screens/decaimiento/decaimiento_screen.dart")
else:
    print("  [sin cambios] lib/screens/decaimiento/decaimiento_screen.dart")

# 5. conversion_screen.dart — tokens inválidos
fix("lib/screens/conversion/conversion_screen.dart", [
    ("AppColors.textTertiary", "AppColors.textSecondary"),
    ("AppColors.textDisabled", "AppColors.textSecondary"),
])

print("\n=== Listo. Corré: flutter clean && flutter run --release ===")
