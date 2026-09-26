import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

class CustomSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;

  const CustomSearchBar({
    super.key,
    required this.hintText,
    this.onChanged,
    this.controller,
    this.trailingIcon = Icons.tune_rounded,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: context.borderColor),
        boxShadow: context.cardShadow,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.bodyMedium.copyWith(color: context.textPrimaryColor),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: hintText,
          hintStyle: AppTypography.caption.copyWith(color: context.textMutedColor),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: context.textSecondaryColor,
            size: 20,
          ),
          suffixIcon: trailingIcon != null
              ? InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  onTap: onTrailingTap,
                  child: Icon(
                    trailingIcon,
                    color: context.textSecondaryColor,
                    size: 18,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
