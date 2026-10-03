// Design tokens. Material 3 with a deep-green seed; system font only;
// theme text styles so 200 percent text scale works. See PLAN.md 9.2.
import 'package:flutter/material.dart';

/// Seed color for the light and dark schemes.
const Color seedColor = Color(0xFF0B6E4F);

/// Semantic colors. Always paired with a text label, never color alone.
const Color liveColor = Color(0xFF16A34A);

/// Documented in PLAN.md 9.2.
const Color staleColor = Color(0xFFB45309);

/// Spacing scale in logical pixels.
const List<double> spacingScale = <double>[4, 8, 12, 16, 24, 32];

/// Corner radii.
const double radiusCard = 12;

/// Documented in PLAN.md 9.2.
const double radiusSheet = 20;

/// Six-colour line badge palette derived deterministically from line id.
const List<Color> badgePalette = <Color>[
  Color(0xFF0B6E4F),
  Color(0xFF1D4ED8),
  Color(0xFF7C3AED),
  Color(0xFFB45309),
  Color(0xFFBE123C),
  Color(0xFF0E7490),
];

/// Badge color for a line id.
Color badgeColorFor(int lineId) {
  return badgePalette[lineId % badgePalette.length];
}

/// Light theme.
ThemeData lightTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
    useMaterial3: true,
  );
}

/// Dark theme with near-black surfaces for OLED battery savings.
ThemeData darkTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF0A0A0A),
    ),
    useMaterial3: true,
  );
}
