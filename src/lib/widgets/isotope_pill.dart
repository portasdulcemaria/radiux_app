import 'package:flutter/material.dart';
import '../models/isotope.dart';

enum IsotopePillSize { small, medium, large }

class IsotopePill extends StatelessWidget {
  final Isotope isotope;
  final IsotopePillSize size;

  const IsotopePill({
    super.key,
    required this.isotope,
    this.size = IsotopePillSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final (double dim, double fs, double radius) = switch (size) {
      IsotopePillSize.small  => (36.0, 8.0,  10.0),
      IsotopePillSize.medium => (46.0, 9.5,  13.0),
      IsotopePillSize.large  => (56.0, 11.0, 16.0),
    };

    final color = isotope.color;

    return Container(
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.22),
            color.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: color.withOpacity(0.40), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.20),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        isotope.symbol,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: fs,
          fontWeight: FontWeight.w800,
          height: 1.2,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
