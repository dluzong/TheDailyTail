import 'package:flutter/services.dart';

// Format date input as MM/DD/YYYY
class DateSlashFormatter extends TextInputFormatter {
  const DateSlashFormatter();
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    String filtered = text.replaceAll(RegExp(r'[^0-9/]'), '');
    String digits = filtered.replaceAll('/', '');
    if (digits.length > 8) {
      digits = digits.substring(0, 8);
    }

    bool userTypedSlash = text.endsWith('/') && !oldValue.text.endsWith('/');

    StringBuffer buffer = StringBuffer();
    int digitIndex = 0;

    if (digitIndex < digits.length) {
      if (digitIndex + 1 < digits.length) {
        buffer.write(digits.substring(digitIndex, digitIndex + 2));
        digitIndex += 2;
      } else {
        if (userTypedSlash ||
            (filtered.contains('/') && filtered.indexOf('/') <= 2)) {
          buffer.write('0${digits[digitIndex]}');
          digitIndex += 1;
        } else {
          buffer.write(digits[digitIndex]);
          digitIndex += 1;
        }
      }

      if (digitIndex < digits.length ||
          (userTypedSlash && buffer.length <= 2)) {
        buffer.write('/');
      }
    }

    if (digitIndex < digits.length) {
      int dayStart = digitIndex;
      if (digitIndex + 1 < digits.length) {
        buffer.write(digits.substring(digitIndex, digitIndex + 2));
        digitIndex += 2;
      } else {
        int slashCount = filtered.split('/').length - 1;
        if (slashCount >= 2 ||
            (userTypedSlash && buffer.toString().contains('/'))) {
          buffer.write('0${digits[digitIndex]}');
          digitIndex += 1;
        } else {
          buffer.write(digits[digitIndex]);
          digitIndex += 1;
        }
      }

      if (digitIndex < digits.length ||
          (userTypedSlash && digitIndex > dayStart)) {
        buffer.write('/');
      }
    }

    if (digitIndex < digits.length) {
      buffer.write(digits.substring(digitIndex));
    }

    final formatted = buffer.toString();
    int cursorPosition = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
