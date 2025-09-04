import 'package:flutter/material.dart';
import 'package:wellread2frontend/constants.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({super.key, this.controller, this.onSubmitted});
  final TextEditingController? controller;
  final Function(String)? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool obscureText = true;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: 'Password',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kTextTabBarHeight * 0.5),
        ),
        suffixIcon: IconButton(
          padding: const EdgeInsets.symmetric(horizontal: kPadding),
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: () => setState(() => obscureText = !obscureText),
        ),
      ),
      obscureText: obscureText,
      onSubmitted: widget.onSubmitted,
    );
  }
}
