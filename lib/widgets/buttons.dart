import 'package:flutter/material.dart';
import '../app/theme.dart';

class CMButton extends StatefulWidget {
  const CMButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.variant = CMButtonVariant.primary,
    this.size = CMButtonSize.large,
    this.isLoading = false,
    this.isFullWidth = true,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final CMButtonVariant variant;
  final CMButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final String? semanticLabel;

  @override
  State<CMButton> createState() => _CMButtonState();
}

class _CMButtonState extends State<CMButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96,
      upperBound: 1.0,
    );
    _scaleAnimation = CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic);
    _pressController.value = 1.0;
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _pressController.reverse();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _pressController.forward();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _pressController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color backgroundColor;
    Color foregroundColor;
    Color? splashColor;
    Color? highlightColor;
    BorderSide? borderSide;

    switch (widget.variant) {
      case CMButtonVariant.primary:
        backgroundColor = isEnabled ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4);
        foregroundColor = Colors.white;
        break;
      case CMButtonVariant.secondary:
        backgroundColor = isEnabled ? AppColors.secondary : AppColors.secondary.withValues(alpha: 0.4);
        foregroundColor = Colors.white;
        break;
      case CMButtonVariant.outline:
        backgroundColor = isEnabled ? Colors.transparent : Colors.transparent;
        foregroundColor = isEnabled ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4);
        borderSide = BorderSide(
          color: isEnabled ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        );
        break;
      case CMButtonVariant.destructive:
        backgroundColor = isEnabled ? AppColors.expense : AppColors.expense.withValues(alpha: 0.4);
        foregroundColor = Colors.white;
        break;
      case CMButtonVariant.ghost:
        backgroundColor = isEnabled ? Colors.transparent : Colors.transparent;
        foregroundColor = isEnabled ? AppColors.textPrimary : AppColors.textSecondary;
        break;
    }

    double horizontalPadding;
    double verticalPadding;
    double fontSize;
    double iconSize;
    double borderRadius = 12;

    switch (widget.size) {
      case CMButtonSize.small:
        horizontalPadding = 16;
        verticalPadding = 10;
        fontSize = 14;
        iconSize = 16;
        borderRadius = 8;
        break;
      case CMButtonSize.medium:
        horizontalPadding = 20;
        verticalPadding = 14;
        fontSize = 15;
        iconSize = 18;
        borderRadius = 10;
        break;
      case CMButtonSize.large:
        horizontalPadding = 24;
        verticalPadding = 16;
        fontSize = 16;
        iconSize = 20;
        borderRadius = 12;
        break;
    }

    Widget buttonChild = widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: iconSize),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                ),
              ),
            ],
          );

    final button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: borderSide != null ? Border.fromBorderSide(borderSide) : null,
            boxShadow: isEnabled && widget.variant != CMButtonVariant.outline && widget.variant != CMButtonVariant.ghost
                ? [
                    BoxShadow(
                      color: backgroundColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(child: buttonChild),
        ),
      ),
    );

    final constrainedButton = widget.isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;

    return Semantics(
      label: widget.semanticLabel ?? widget.label,
      button: true,
      enabled: isEnabled,
      child: constrainedButton,
    );
  }
}

enum CMButtonVariant {
  primary,
  secondary,
  outline,
  destructive,
  ghost,
}

enum CMButtonSize {
  small,
  medium,
  large,
}

class CMIconButton extends StatefulWidget {
  const CMIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.variant = CMIconButtonVariant.standard,
    this.size = CMIconButtonSize.medium,
    this.semanticLabel,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final CMIconButtonVariant variant;
  final CMIconButtonSize size;
  final String? semanticLabel;
  final String? tooltip;

  @override
  State<CMIconButton> createState() => _CMIconButtonState();
}

class _CMIconButtonState extends State<CMIconButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.9,
      upperBound: 1.0,
    );
    _scaleAnimation = CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic);
    _pressController.value = 1.0;
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) _pressController.reverse();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null) _pressController.forward();
  }

  void _handleTapCancel() {
    if (widget.onPressed != null) _pressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null;

    Color backgroundColor;
    Color foregroundColor;
    double size;
    double borderRadius = 12;

    switch (widget.size) {
      case CMIconButtonSize.small:
        size = 36;
        break;
      case CMIconButtonSize.medium:
        size = 44;
        break;
      case CMIconButtonSize.large:
        size = 52;
        break;
    }

    switch (widget.variant) {
      case CMIconButtonVariant.standard:
        backgroundColor = isEnabled ? AppColors.primary.withValues(alpha: 0.1) : AppColors.divider;
        foregroundColor = isEnabled ? AppColors.primary : AppColors.textSecondary;
        break;
      case CMIconButtonVariant.filled:
        backgroundColor = isEnabled ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4);
        foregroundColor = Colors.white;
        break;
      case CMIconButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled ? AppColors.primary : AppColors.textSecondary;
        break;
      case CMIconButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled ? AppColors.textPrimary : AppColors.textSecondary;
        break;
    }

    final child = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: widget.variant == CMIconButtonVariant.outline
                ? Border.all(color: isEnabled ? AppColors.primary : AppColors.divider, width: 1.5)
                : null,
          ),
          child: Icon(widget.icon, color: foregroundColor, size: size * 0.5),
        ),
      ),
    );

    return Semantics(
      label: widget.semanticLabel,
      button: true,
      enabled: isEnabled,
      child: widget.tooltip != null ? Tooltip(message: widget.tooltip!, child: child) : child,
    );
  }
}

enum CMIconButtonVariant {
  standard,
  filled,
  outline,
  ghost,
}

enum CMIconButtonSize {
  small,
  medium,
  large,
}