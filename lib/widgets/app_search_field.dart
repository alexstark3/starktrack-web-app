import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final IconData prefixIcon;
  final Widget? suffixIcon;

  const AppSearchField({
    super.key,
    this.controller,
    required this.hintText,
    this.onChanged,
    this.prefixIcon = Icons.search,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          constraints: const BoxConstraints.tightFor(height: 38),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDark
                ? Theme.of(context).colorScheme.onSurface
                : colors.textColor,
          ),
          prefixIcon: Icon(prefixIcon,
              color: isDark
                  ? Theme.of(context).colorScheme.onSurface
                  : colors.darkGray),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor:
              isDark ? colors.lightGray : Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: Colors.black.withValues(alpha: 0.3), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: Colors.black.withValues(alpha: 0.3), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.primaryBlue, width: 2),
          ),
        ),
        style: TextStyle(
          color: isDark
              ? Theme.of(context).colorScheme.onSurface
              : colors.textColor,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
