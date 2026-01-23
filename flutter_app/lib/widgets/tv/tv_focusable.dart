import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/platform_utils.dart';

/// TV 焦点管理 Widget
///
/// 为子组件提供焦点管理和键盘导航支持
/// 主要用于 Android TV 的 D-pad 导航
class TvFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool autofocus;
  final FocusNode? focusNode;
  final Color? focusColor;
  final double? focusBorderWidth;
  final BorderRadius? borderRadius;

  const TvFocusable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.autofocus = false,
    this.focusNode,
    this.focusColor,
    this.focusBorderWidth,
    this.borderRadius,
  });

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      // 处理确认键（遥控器的 OK/Enter 键）
      if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        widget.onTap?.call();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // 如果不是 TV 平台，直接返回可点击的 Widget
    if (!PlatformUtils.isAndroidTV) {
      return GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: widget.child,
      );
    }

    // TV 平台使用 Focus widget
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: _isFocused
                ? Border.all(
                    color: widget.focusColor ?? Theme.of(context).colorScheme.primary,
                    width: widget.focusBorderWidth ?? 3.0,
                  )
                : null,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// TV 可聚焦的按钮
class TvFocusableButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool autofocus;
  final FocusNode? focusNode;
  final Color? backgroundColor;
  final Color? focusColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const TvFocusableButton({
    super.key,
    required this.child,
    this.onPressed,
    this.autofocus = false,
    this.focusNode,
    this.backgroundColor,
    this.focusColor,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      autofocus: autofocus,
      focusNode: focusNode,
      focusColor: focusColor,
      borderRadius: borderRadius,
      onTap: onPressed,
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).colorScheme.primary,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: child,
      ),
    );
  }
}

/// TV 导航键监听器
///
/// 用于在整个应用中监听和处理导航键事件
class TvKeyHandler extends StatelessWidget {
  final Widget child;
  final Function(LogicalKeyboardKey key)? onKeyPressed;

  const TvKeyHandler({
    super.key,
    required this.child,
    this.onKeyPressed,
  });

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (!PlatformUtils.isAndroidTV) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent) {
      onKeyPressed?.call(event.logicalKey);

      // 处理返回键
      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.goBack) {
        return KeyEventResult.handled;
      }

      // 处理菜单键
      if (event.logicalKey == LogicalKeyboardKey.contextMenu) {
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.isAndroidTV) {
      return child;
    }

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: child,
    );
  }
}
