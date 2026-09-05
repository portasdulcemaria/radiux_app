import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Isotope {
  final String id;
  final String symbol;
  final String name;
  final double halfLifeHours;
  final String category;
  final Color color;

  const Isotope({
    required this.id,
    required this.symbol,
    required this.name,
    required this.halfLifeHours,
    required this.category,
    required this.color,
  });

  String get halfLifeDisplay {
    if (halfLifeHours < 1) {
      final minutes = (halfLifeHours * 60).round();
      return 'T½ = $minutes min';
    } else if (halfLifeHours < 24) {
      final h = halfLifeHours;
      return 'T½ = ${_fmt(h)} horas';
    } else {
      final days = halfLifeHours / 24;
      return 'T½ = ${_fmt(days)} días';
    }
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}

final List<Isotope> kIsotopes = [
  Isotope(
    id: 'tc99m',
    symbol: '⁹⁹ᵐTc',
    name: 'Tecnecio 99m',
    halfLifeHours: 6.0067,
    category: 'Diagnóstico SPECT',
    color: AppColors.tcColor,
  ),
  Isotope(
    id: 'i131',
    symbol: '¹³¹I',
    name: 'Yodo 131',
    halfLifeHours: 192.48, // 8.02 days
    category: 'Terapia / Diagnóstico',
    color: AppColors.iColor,
  ),
  Isotope(
    id: 'i123',
    symbol: '¹²³I',
    name: 'Yodo 123',
    halfLifeHours: 13.22,
    category: 'Diagnóstico SPECT',
    color: AppColors.iColor,
  ),
  Isotope(
    id: 'f18',
    symbol: '¹⁸F',
    name: 'Flúor 18',
    halfLifeHours: 1.8295,
    category: 'Diagnóstico PET',
    color: AppColors.f18Color,
  ),
  Isotope(
    id: 'ga67',
    symbol: '⁶⁷Ga',
    name: 'Galio 67',
    halfLifeHours: 78.26,
    category: 'Diagnóstico SPECT',
    color: AppColors.gaColor,
  ),
  Isotope(
    id: 'ga68',
    symbol: '⁶⁸Ga',
    name: 'Galio 68',
    halfLifeHours: 1.1296,
    category: 'Diagnóstico PET',
    color: AppColors.gaColor,
  ),
  Isotope(
    id: 'lu177',
    symbol: '¹⁷⁷Lu',
    name: 'Lutecio 177',
    halfLifeHours: 159.408, // 6.6 days
    category: 'Terapia',
    color: AppColors.luColor,
  ),
  Isotope(
    id: 'tl201',
    symbol: '²⁰¹Tl',
    name: 'Talio 201',
    halfLifeHours: 72.912, // 3.038 days
    category: 'Diagnóstico SPECT',
    color: AppColors.tl201Color,
  ),
  Isotope(
    id: 'in111',
    symbol: '¹¹¹In',
    name: 'Indio 111',
    halfLifeHours: 67.32,
    category: 'Diagnóstico SPECT',
    color: AppColors.gaColor,
  ),
  Isotope(
    id: 'sr90',
    symbol: '⁹⁰Sr',
    name: 'Estroncio 90',
    halfLifeHours: 252720.0, // 28.8 years
    category: 'Terapia',
    color: AppColors.error,
  ),
  Isotope(
    id: 'y90',
    symbol: '⁹⁰Y',
    name: 'Itrio 90',
    halfLifeHours: 64.05,
    category: 'Terapia',
    color: AppColors.accentLight,
  ),
  Isotope(
    id: 'ra223',
    symbol: '²²³Ra',
    name: 'Radio 223',
    halfLifeHours: 273.36, // 11.39 days
    category: 'Terapia',
    color: AppColors.warning,
  ),
];
