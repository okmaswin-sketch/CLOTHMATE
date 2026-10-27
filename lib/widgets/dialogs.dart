import 'package:flutter/material.dart';

Future<T?> showCMDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  Duration duration = const Duration(milliseconds: 180),
  Curve curve = Curves.easeOutCubic,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor ?? Colors.black54,
    transitionDuration: duration,
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
      final reverseCurve = CurvedAnimation(parent: animation, curve: Curves.easeInCubic);
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

Future<T?> showCMDialogReplacing<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showCMDialog<T>(context: context, builder: builder, barrierDismissible: barrierDismissible);
}

class CMAlertDialog extends StatelessWidget {
  const CMAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.actionsAlignment = MainAxisAlignment.end,
    this.actionsPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.shape,
    this.backgroundColor,
    this.elevation = 4,
    this.insetPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final MainAxisAlignment actionsAlignment;
  final EdgeInsetsGeometry actionsPadding;
  final ShapeBorder? shape;
  final Color? backgroundColor;
  final double elevation;
  final EdgeInsets insetPadding;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: backgroundColor,
      elevation: elevation,
      insetPadding: insetPadding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w600),
                  child: title!,
                ),
                const SizedBox(height: 16),
              ],
              if (content != null) ...[
                Flexible(child: content!),
                const SizedBox(height: 20),
              ],
              if (actions != null && actions!.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: actionsAlignment,
                  children: actions!
                      .map((action) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: action,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> showCMBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
  ShapeBorder? shape,
  Duration duration = const Duration(milliseconds: 220),
  Curve curve = Curves.easeOutCubic,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor,
    shape: shape ?? const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    clipBehavior: Clip.antiAlias,
    transitionAnimationController: null,
    builder: (context) {
      return AnimatedPadding(
        duration: duration,
        curve: curve,
        padding: MediaQuery.of(context).viewInsets,
        child: builder(context),
      );
    },
  );
}

class CMBottomSheet extends StatelessWidget {
  const CMBottomSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.handleColor,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? handleColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: handleColor ?? theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class CMActionSheet extends StatelessWidget {
  const CMActionSheet({
    super.key,
    this.title,
    required this.actions,
    this.cancelAction,
  });

  final Widget? title;
  final List<CMActionSheetAction> actions;
  final CMActionSheetAction? cancelAction;

  @override
  Widget build(BuildContext context) {
    return CMBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600),
                child: title!,
              ),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor),
          ],
          ...actions.map((action) => _ActionTile(action: action)).toList(),
          if (cancelAction != null) ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            const SizedBox(height: 8),
            _ActionTile(action: cancelAction!, isCancel: true),
          ],
        ],
      ),
    );
  }
}

class CMActionSheetAction {
  const CMActionSheetAction({
    required this.label,
    this.icon,
    this.onPressed,
    this.isDestructive = false,
    this.isEnabled = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final bool isEnabled;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action, this.isCancel = false});

  final CMActionSheetAction action;
  final bool isCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = action.isDestructive
        ? theme.colorScheme.error
        : (isCancel ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodyLarge?.color);

    return InkWell(
      onTap: action.isEnabled ? () {
        Navigator.of(context).pop();
        action.onPressed?.call();
      } : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (action.icon != null) ...[
              Icon(action.icon, color: color, size: 22),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                action.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: action.isEnabled ? color : theme.disabledColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}