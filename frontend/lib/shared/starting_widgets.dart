import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildBorderBar() {
  return Container(
    height: 30,
    color: const Color(0xFF7496B3),
  );
}

Widget buildAppTitle() {
  return Image.asset(
    'assets/dailytail-logotype-blue.png',
    height: 130,
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
  required BuildContext context,
  bool forceLightMode = false,
}) {
  final isDark = !forceLightMode && Theme.of(context).brightness == Brightness.dark;
  return SizedBox(
    width: 300,
    child: TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.inknutAntiqua(
        fontSize: 16,
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inknutAntiqua(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: isDark
              ? const BorderSide(color: Color(0xFF4A4A4A), width: 1)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF7496B3) : const Color(0xFF7496B3),
            width: 1.5,
          ),
        ),
        suffixIcon: suffixIcon,
      ),
    ),
  );
}
