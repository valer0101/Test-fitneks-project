import 'package:flutter/material.dart';
import '../app_theme.dart';

/// A button widget that works like ElevatedButton but with fitneksGradient
/// Can be used as a drop-in replacement for ElevatedButton where gradient is needed
class GradientElevatedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;

  const GradientElevatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// Factory constructor for icon button
  factory GradientElevatedButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    required Widget icon,
    required Widget label,
    ButtonStyle? style,
    FocusNode? focusNode,
    bool autofocus = false,
  }) {
    return GradientElevatedButton(
      key: key,
      onPressed: onPressed,
      style: style,
      focusNode: focusNode,
      autofocus: autofocus,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          label,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;
    final currentGradient = isDisabled
        ? const LinearGradient(colors: [Colors.grey, Colors.grey])
        : AppTheme.fitneksGradient;

    // Get padding from style or use default
    final EdgeInsetsGeometry padding = style?.padding?.resolve({}) ??
        const EdgeInsets.symmetric(vertical: 10, horizontal: 24);

    // Get borderRadius from style or use default
    double borderRadius = AppTheme.borderRadiusMedium;
    if (style?.shape?.resolve({}) is RoundedRectangleBorder) {
      final shape = style!.shape!.resolve({}) as RoundedRectangleBorder;
      final resolvedRadius = shape.borderRadius.resolve(TextDirection.ltr);
      borderRadius = resolvedRadius.topLeft.x;
    }

    // Get minimum size from style or use default (same as ElevatedButton)
    final Size? minimumSize = style?.minimumSize?.resolve({});
    final double minWidth = minimumSize?.width ?? 64.0;
    final double minHeight = minimumSize?.height ?? 36.0;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth,
        minHeight: minHeight,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: currentGradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            focusNode: focusNode,
            autofocus: autofocus,
            child: Padding(
              padding: padding,
              child: Align(
                alignment: Alignment.center,
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: DefaultTextStyle(
                  style: style?.textStyle?.resolve({}) ??
                      Theme.of(context)
                          .elevatedButtonTheme
                          .style
                          ?.textStyle
                          ?.resolve({}) ??
                      const TextStyle(color: Colors.white),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
