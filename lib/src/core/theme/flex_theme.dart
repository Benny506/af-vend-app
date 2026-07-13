import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../extensions/text_style_extension.dart';

class FlexTheme {
  static ThemeData light(
    FlexScheme colorScheme,
    bool useMaterial3,
  ) =>
      FlexThemeData.light(
        useMaterial3: useMaterial3,
        colors: const FlexSchemeColor(
          primary: Color(0xFF344F16),       // Forest green
          primaryContainer: Color(0xFF1A2D07),
          secondary: Color(0xFFE48629),     // Orange
          secondaryContainer: Color(0xFFF8B55B), // Golden amber
          tertiary: Color(0xFF3D8B7A),      // Teal
          tertiaryContainer: Color(0xFFFAF8F5),
        ),
        scaffoldBackground: const Color(0xFFF7F4EE), // Warm parchment
        subThemesData: const FlexSubThemesData(
          useMaterial3Typography: true,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          inputDecoratorRadius: 10.0,
          inputDecoratorFocusedHasBorder: true,
          inputDecoratorUnfocusedHasBorder: true,
          cardRadius: 12.0,
          cardElevation: 1.0,
          elevatedButtonRadius: 10.0,
          outlinedButtonRadius: 10.0,
          textButtonRadius: 10.0,
          appBarBackgroundSchemeColor: SchemeColor.primary,
        ),
        blendLevel: 4,
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: GoogleFonts.comfortaa().fontFamily,
        textTheme: GoogleFonts.comfortaaTextTheme().copyWith(
          headlineLarge: headlineLarge,
          headlineMedium: headlineMedium,
          headlineSmall: headlineSmall,
          bodyLarge: bodyLarge,
          bodyMedium: bodyMedium,
          bodySmall: bodySmall,
        ),
        typography: Typography.material2021(platform: defaultTargetPlatform),
      ).copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFE48629),
          selectionColor: Color(0xFFF8B55B),
          selectionHandleColor: Color(0xFFE48629),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Color(0xFFE48629), width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Color(0xFFE8E2D6), width: 1.0),
          ),
        ),
        cardColor: Colors.white,
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE8E2D6), width: 1.0),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE8E2D6),
          thickness: 1.0,
        ),
        listTileTheme: ListTileThemeData(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE8E2D6), width: 0.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        expansionTileTheme: const ExpansionTileThemeData(
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: Color(0xFFE8E2D6), width: 1.0),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: Color(0xFFE8E2D6), width: 1.0),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFFF7F4EE),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFFAF8F5),
          side: const BorderSide(color: Color(0xFFE8E2D6), width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE8E2D6), width: 0.5),
          ),
        ),
      );

  // ========================================================================================== //
  static ThemeData dark(
    FlexScheme colorScheme,
    bool useMaterial3,
  ) =>
      FlexThemeData.dark(
        useMaterial3: useMaterial3,
        colors: const FlexSchemeColor(
          primary: Color(0xFFF8B55B),       // Golden/Amber
          primaryContainer: Color(0xFF1C1800),
          secondary: Color(0xFF344F16),     // Forest green
          secondaryContainer: Color(0xFF0E0C00),
          tertiary: Color(0xFF3D8B7A),
          tertiaryContainer: Color(0xFF252000),
        ),
        scaffoldBackground: const Color(0xFF0E0C00),
        subThemesData: const FlexSubThemesData(
          inputDecoratorBorderType: FlexInputBorderType.outline,
          inputDecoratorRadius: 8.0,
          inputDecoratorFocusedHasBorder: true,
          inputDecoratorUnfocusedHasBorder: true,
        ),
        blendLevel: 7,
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: GoogleFonts.comfortaa().fontFamily,
        textTheme: GoogleFonts.comfortaaTextTheme().copyWith(
          headlineLarge: headlineLarge.dark(),
          headlineMedium: headlineMedium.dark(),
          headlineSmall: headlineSmall.dark(),
          bodyLarge: bodyLarge.dark(),
          bodyMedium: bodyMedium.dark(),
          bodySmall: bodySmall.dark(),
        ),
        typography: Typography.material2021(platform: defaultTargetPlatform),
      ).copyWith(
        cardColor: const Color(0xFF1C1800),
        cardTheme: CardThemeData(
          color: const Color(0xFF1C1800),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF2E2800), width: 1.0),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF2E2800),
          thickness: 1.0,
        ),
        listTileTheme: ListTileThemeData(
          tileColor: const Color(0xFF1C1800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF2E2800), width: 0.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        expansionTileTheme: const ExpansionTileThemeData(
          backgroundColor: Color(0xFF1C1800),
          collapsedBackgroundColor: Color(0xFF1C1800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: Color(0xFF2E2800), width: 1.0),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: Color(0xFF2E2800), width: 1.0),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF0E0C00),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1C1800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF252000),
          side: const BorderSide(color: Color(0xFF2E2800), width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFF1C1800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF2E2800), width: 0.5),
          ),
        ),
      );

  // ========================================================================================== //

  // Headline 1
  // 34px Bold
  static final headlineLarge =
      GoogleFonts.comfortaa(fontSize: 34, color: Colors.black);

  // Headline 2
  // 28px Semi-bold
  static final headlineMedium =
      GoogleFonts.comfortaa(fontSize: 28, color: Colors.black);
  // Headline 3
  // 22px Medium
  static final headlineSmall =
      GoogleFonts.comfortaa(fontSize: 22, color: Colors.black);

  // Body 1
  // 17px Medium
  static final bodyLarge = GoogleFonts.comfortaa(fontSize: 17, color: Colors.black);

  // Body 2
  // 15px Medium
  static final bodyMedium =
      GoogleFonts.comfortaa(fontSize: 15, color: Colors.black);

  // Body 3
  // 13px Medium
  static final bodySmall = GoogleFonts.comfortaa(fontSize: 13, color: Colors.black);
}
