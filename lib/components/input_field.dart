import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool? readOnly;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters; // Add inputFormatters parameter

  CustomTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.hintText,
    this.keyboardType,
    this.readOnly,
    this.onChanged,
    this.inputFormatters, // Initialize inputFormatters
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: TextField(

        inputFormatters: inputFormatters ??
            [
              keyboardType == TextInputType.number
                  ? FilteringTextInputFormatter.digitsOnly
                  : FilteringTextInputFormatter.singleLineFormatter,
            ],
        keyboardType: keyboardType,
        controller: controller,
        obscureText: obscureText,

        readOnly: readOnly ?? false,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: label,
          hintText: hintText, // Add hintText here
        ),
        onChanged: onChanged,
      ),
    );
  }
}
