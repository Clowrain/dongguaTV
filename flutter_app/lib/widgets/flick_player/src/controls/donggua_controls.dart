import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../flick_video_player.dart';

/// 东瓜TV 播放器竖屏控制层
/// 
/// 包含顶部栏（返回、标题、更多选项）和底部控制栏
/// 
/// ## 插槽系统
/// - [topLeftSlot]: 顶部左侧区域（默认返回按钮）
/// - [topRightSlot]: 顶部右侧区域（默认更多选项按钮）
/// - [centerSlot]: 中央区域（默认播放/暂停按钮）
/// - [bottomSlot]: 底部区域（默认进度条和控制按钮）
/// - [overlaySlot]: 浮层区域（如弹幕、字幕等）
class DongguaPortraitControls extends StatelessWidget {
  const DongguaPortraitControls({
    super.key,
    this.iconSize = 20,
    this.fontSize = 12,
    this.title = '',
    this.episodeName = '',
    this.onBack,
    this.onMoreOptions,
    this.progressBarSettings,
    // 插槽
    this.topLeftSlot,
    this.topRightSlot,
    this.centerSlot,
    this.bottomSlot,
    this.overlaySlot,
    // 手势回调
    this.onGestureStart,
    this.onGestureEnd,
  });

  final double iconSize;
  final double fontSize;
  final String title;
  final String episodeName;
  final VoidCallback? onBack;
  final VoidCallback? onMoreOptions;
  final FlickProgressBarSettings? progressBarSettings;
  
  /// 顶部左侧插槽（默认返回按钮）
  final Widget? topLeftSlot;
  
  /// 顶部右侧插槽（默认更多选项按钮）
  final Widget? topRightSlot;
  
  /// 中央插槽（默认播放/暂停按钮）
  final Widget? centerSlot;
  
  /// 底部插槽（默认进度条和控制按钮）
  final Widget? bottomSlot;
  
  /// 浮层插槽（弹幕、字幕等）
  final Widget? overlaySlot;
  
  /// 手势开始时回调（父级应禁用滚动）
  final VoidCallback? onGestureStart;
  
  /// 手势结束时回调（父级应恢复滚动）
  final VoidCallback? onGestureEnd;

  @override
  Widget build(BuildContext context) {
    // 默认中央控制按钮
    final defaultCenterControl = FlickPlayToggle(
      size: 40,
      color: Colors.black,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(40),
      ),
    );
    
    return Stack(
      children: <Widget>[
        // 浮层插槽（弹幕等）- 放在最底层
        if (overlaySlot != null)
          Positioned.fill(child: overlaySlot!),
          
        // 中间播放控制 - 使用统一的手势处理
        Positioned.fill(
          child: DongguaVideoAction(
            onGestureStart: onGestureStart,
            onGestureEnd: onGestureEnd,
            child: Center(
              child: FlickVideoBuffer(
                child: FlickAutoHideChild(
                  showIfVideoNotInitialized: false,
                  child: centerSlot ?? defaultCenterControl,
                ),
              ),
            ),
          ),
        ),
        // 顶部栏 - 加载/错误时显示，播放后自动隐藏
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: FlickAutoHideChild(
            showIfVideoNotInitialized: true, // 视频未初始化时显示
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(150),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  // 左侧插槽（默认返回按钮）
                  topLeftSlot ?? (onBack != null
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: onBack,
                      )
                    : const SizedBox()),
                  const Spacer(),
                  // 右侧插槽（默认更多选项按钮）
                  topRightSlot ?? (onMoreOptions != null
                    ? IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: onMoreOptions,
                      )
                    : const SizedBox()),
                ],
              ),
            ),
          ),
        ),
        // 底部控制栏 - 带渐变遮罩
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: FlickAutoHideChild(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withAlpha(180),
                    Colors.black.withAlpha(100),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(10, 30, 10, 10),
              child: bottomSlot ?? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FlickVideoProgressBar(
                    flickProgressBarSettings: progressBarSettings ?? FlickProgressBarSettings(
                      height: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      // 播放/暂停
                      FlickPlayToggle(size: iconSize),
                      SizedBox(width: iconSize / 2),
                      // 静音
                      FlickSoundToggle(size: iconSize),
                      SizedBox(width: iconSize / 2),
                      // 时间
                      Row(
                        children: <Widget>[
                          FlickCurrentPosition(fontSize: fontSize),
                          Text(
                            ' / ',
                            style: TextStyle(color: Colors.white, fontSize: fontSize),
                          ),
                          FlickTotalDuration(fontSize: fontSize),
                        ],
                      ),
                      const Expanded(child: SizedBox()),
                      // 全屏
                      FlickFullScreenToggle(size: iconSize),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 东瓜TV 播放器全屏控制层
class DongguaLandscapeControls extends StatelessWidget {
  const DongguaLandscapeControls({
    super.key,
    this.title = '',
    this.episodeName = '',
    this.onBack,
    this.onGestureStart,
    this.onGestureEnd,
  });

  final String title;
  final String episodeName;
  final VoidCallback? onBack;
  
  /// 手势开始时回调
  final VoidCallback? onGestureStart;
  
  /// 手势结束时回调
  final VoidCallback? onGestureEnd;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // 中间播放控制 - 使用统一的手势处理
        Positioned.fill(
          child: DongguaVideoAction(
            onGestureStart: onGestureStart,
            onGestureEnd: onGestureEnd,
            child: Center(
              child: FlickVideoBuffer(
                child: FlickAutoHideChild(
                  showIfVideoNotInitialized: false,
                  child: FlickPlayToggle(
                    size: 50,
                    color: Colors.black,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // 顶部栏 - 加载/错误时显示，播放后自动隐藏
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: FlickAutoHideChild(
            showIfVideoNotInitialized: true, // 视频未初始化时显示
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(180),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: MediaQuery.of(context).padding.left + 16, // 适配左侧刘海
                right: MediaQuery.of(context).padding.right + 16, // 适配右侧刘海
                bottom: 8,
              ),
              child: Row(
                children: [
                  // 返回/退出全屏
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      final controlManager = Provider.of<FlickControlManager>(context, listen: false);
                      controlManager.exitFullscreen();
                    },
                  ),
                  const SizedBox(width: 8),
                  // 标题
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (episodeName.isNotEmpty)
                          Text(
                            episodeName,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 底部控制栏 - 带渐变遮罩
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: FlickAutoHideChild(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withAlpha(180),
                    Colors.black.withAlpha(100),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              padding: EdgeInsets.only(
                left: MediaQuery.of(context).padding.left + 16,
                right: MediaQuery.of(context).padding.right + 16,
                bottom: MediaQuery.of(context).padding.bottom + 10,
                top: 30,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FlickVideoProgressBar(
                    flickProgressBarSettings: FlickProgressBarSettings(
                      height: 5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      FlickPlayToggle(size: 28),
                      const SizedBox(width: 16),
                      FlickSoundToggle(size: 28),
                      const SizedBox(width: 16),
                      Row(
                        children: <Widget>[
                          FlickCurrentPosition(fontSize: 14),
                          const Text(
                            ' / ',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          FlickTotalDuration(fontSize: 14),
                        ],
                      ),
                      const Expanded(child: SizedBox()),
                      FlickFullScreenToggle(size: 28),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
