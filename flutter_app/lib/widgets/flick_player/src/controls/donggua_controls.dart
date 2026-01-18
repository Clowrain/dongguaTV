import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../flick_video_player.dart';

/// 东瓜TV 播放器竖屏控制层
/// 
/// 包含顶部栏（返回、标题、更多选项）和底部控制栏
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
  });

  final double iconSize;
  final double fontSize;
  final String title;
  final String episodeName;
  final VoidCallback? onBack;
  final VoidCallback? onMoreOptions;
  final FlickProgressBarSettings? progressBarSettings;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // 中间播放控制
        Positioned.fill(
          child: FlickShowControlsAction(
            child: FlickSeekVideoAction(
              child: Center(
                child: FlickVideoBuffer(
                  child: FlickAutoHideChild(
                    showIfVideoNotInitialized: false,
                    child: FlickPlayToggle(
                      size: 40,
                      color: Colors.black,
                      padding: const EdgeInsets.all(12),
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
                  // 返回按钮
                  if (onBack != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: onBack,
                    ),
                  const Spacer(),
                  // 更多选项按钮
                  if (onMoreOptions != null)
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: onMoreOptions,
                    ),
                ],
              ),
            ),
          ),
        ),
        // 底部控制栏
        Positioned.fill(
          child: FlickAutoHideChild(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
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
  });

  final String title;
  final String episodeName;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // 中间播放控制
        Positioned.fill(
          child: FlickShowControlsAction(
            child: FlickSeekVideoAction(
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
                left: 16,
                right: 16,
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
        // 底部控制栏
        Positioned.fill(
          child: FlickAutoHideChild(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 10,
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
