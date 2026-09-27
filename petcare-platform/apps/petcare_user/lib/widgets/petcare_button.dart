import 'package:flutter/material.dart';
import '../core/theme.dart';

enum PetButtonType { primary, secondary, outline, text }

class PetCareButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final PetButtonType type;
  final double? width;
  final double height;
  final Color? customColor;

  const PetCareButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.type = PetButtonType.primary,
    this.width,
    this.height = 52,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget childContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == PetButtonType.primary ? Colors.white : PetColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: _textColor(),
          ),
        ),
      ],
    );

    Widget button;
    switch (type) {
      case PetButtonType.primary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: customColor ?? PetColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: PetColors.primary.withOpacity(0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: childContent,
        );
        break;
      case PetButtonType.secondary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: PetColors.sageLight,
            foregroundColor: PetColors.sage,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: childContent,
        );
        break;
      case PetButtonType.outline:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: customColor ?? PetColors.dark,
            side: BorderSide(
              color: customColor ?? PetColors.border,
              width: 1.3,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: childContent,
        );
        break;
      case PetButtonType.text:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: customColor ?? PetColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: childContent,
        );
        break;
    }

    if (width != null) {
      return SizedBox(width: width, height: height, child: button);
    }
    return SizedBox(height: height, child: button);
  }

  Color _textColor() {
    switch (type) {
      case PetButtonType.primary:
        return Colors.white;
      case PetButtonType.secondary:
        return PetColors.sage;
      case PetButtonType.outline:
        return customColor ?? PetColors.dark;
      case PetButtonType.text:
        return customColor ?? PetColors.primary;
    }
  }
}
