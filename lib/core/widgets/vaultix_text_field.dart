import 'package:flutter/material.dart';

class VaultixTextField extends StatefulWidget {
  const VaultixTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.isPassword = false,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.onChanged,
    this.autofocus = false,
    this.onSubmitted,
    this.hintText,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final String? hintText;

  @override
  State<VaultixTextField> createState() => _VaultixTextFieldState();
}

class _VaultixTextFieldState extends State<VaultixTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword && _obscured,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      onChanged: widget.onChanged,
      autofocus: widget.autofocus,
      onFieldSubmitted: widget.onSubmitted,
      enableSuggestions: !widget.isPassword,
      autocorrect: !widget.isPassword,
      style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        prefixIcon: widget.icon != null
            ? Icon(widget.icon, color: scheme.onSurface.withValues(alpha: 0.72))
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                tooltip: _obscured ? 'Show' : 'Hide',
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    _obscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    key: ValueKey(_obscured),
                  ),
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
    );
  }
}
