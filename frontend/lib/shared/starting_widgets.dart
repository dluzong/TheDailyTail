import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildBorderBar() {
  return Container(
    height: 30,
    color: const Color(0xFF7496B3),
  );
}

Widget buildAppTitle() {
  return Text(
    "The Daily Tail",
    style: GoogleFonts.inknutAntiqua(
      fontSize: 30,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF7496B3),
    ),
  );
}

Widget buildDogIcon({double size = 120}) {
  return Image.asset(
    'assets/dog.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
  );
}

Widget buildAppButton({
  required String text,
  required VoidCallback onPressed,
  double width = 180,
}) {
  return SizedBox(
    width: width,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8DB6D9),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Georgia',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

Widget buildAppTextField({
  required String hint,
  bool obscure = false,
  TextEditingController? controller,
  Widget? suffixIcon,
}) {
  return SizedBox(
    width: 300,
    child: TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.inknutAntiqua(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inknutAntiqua(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon,
      ),
    ),
  );
}
