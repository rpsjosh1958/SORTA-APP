import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextStyle get chunkyHeading => GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
        height: 1.1,
      );

  static TextStyle get chunkySubHeading => GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      );

  static TextStyle get bodyBold => GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get buttonText => GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w900,
      );
}
