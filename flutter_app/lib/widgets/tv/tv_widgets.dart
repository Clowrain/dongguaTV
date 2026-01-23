import 'package:flutter/material.dart';
import '../../utils/platform_utils.dart';
import 'tv_focusable.dart';

/// TV 适配的卡片组件
///
/// 针对 10-foot UI 优化的卡片组件，具有更大的尺寸和焦点效果
class TvCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool autofocus;
  final FocusNode? focusNode;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const TvCard({
    super.key,
    required this.child,
    this.onTap,
    this.autofocus = false,
    this.focusNode,
    this.width,
    this.height,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final scale = PlatformUtils.recommendedSpacingScale;

    return TvFocusable(
      autofocus: autofocus,
      focusNode: focusNode,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8 * scale),
      child: Container(
        width: width,
        height: height,
        margin: margin ?? EdgeInsets.all(8 * scale),
        padding: padding ?? EdgeInsets.all(12 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// TV 适配的网格视图
///
/// 为 TV 优化的网格布局，使用更大的间距和焦点管理
class TvGridView extends StatelessWidget {
  final int crossAxisCount;
  final List<Widget> children;
  final double? childAspectRatio;
  final ScrollPhysics? physics;

  const TvGridView({
    super.key,
    required this.crossAxisCount,
    required this.children,
    this.childAspectRatio,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final scale = PlatformUtils.recommendedSpacingScale;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16 * scale,
      mainAxisSpacing: 16 * scale,
      childAspectRatio: childAspectRatio ?? 0.7,
      padding: EdgeInsets.all(16 * scale),
      physics: physics,
      children: children,
    );
  }
}

/// TV 适配的列表项
class TvListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool autofocus;
  final FocusNode? focusNode;

  const TvListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final scale = PlatformUtils.recommendedSpacingScale;
    final fontScale = PlatformUtils.recommendedFontScale;

    return TvFocusable(
      autofocus: autofocus,
      focusNode: focusNode,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8 * scale),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 12 * scale,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: 16 * scale),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 16 * fontScale,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    child: title,
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 4 * scale),
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 14 * fontScale,
                        color: Colors.white70,
                      ),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: 16 * scale),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// TV 适配的水平滚动列表
class TvHorizontalList extends StatelessWidget {
  final List<Widget> children;
  final double height;
  final EdgeInsetsGeometry? padding;

  const TvHorizontalList({
    super.key,
    required this.children,
    required this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final scale = PlatformUtils.recommendedSpacingScale;

    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: padding ?? EdgeInsets.symmetric(horizontal: 16 * scale),
        itemCount: children.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 12 * scale),
            child: children[index],
          );
        },
      ),
    );
  }
}

/// TV 适配的文本
///
/// 根据平台自动调整字体大小
class TvText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TvText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final fontScale = PlatformUtils.recommendedFontScale;
    final baseStyle = style ?? const TextStyle();

    return Text(
      text,
      style: baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 14) * fontScale,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
