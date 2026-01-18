import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../../flick_video_player.dart';

/// 东瓜视频手势控制组件
/// 
/// 整合所有手势到一个 GestureDetector 中，避免冲突：
/// - onTap: 显示/隐藏控制层
/// - onDoubleTap: 左半快退，右半快进
/// - onVerticalDrag: 左半亮度，右半音量
/// - onHorizontalDrag: 进度调节
/// 
/// 支持平台: iOS, Android, macOS, Android TV
class DongguaVideoAction extends StatefulWidget {
  const DongguaVideoAction({
    super.key,
    this.child,
    this.seekDuration = const Duration(seconds: 10),
  });

  final Widget? child;
  final Duration seekDuration;

  @override
  State<DongguaVideoAction> createState() => _DongguaVideoActionState();
}

class _DongguaVideoActionState extends State<DongguaVideoAction> {
  // 拖动状态
  String? _dragDirection; // 'horizontal' 或 'vertical'
  String _adjustType = ''; // 'volume', 'brightness', 'seek'
  Offset _dragStart = Offset.zero;
  double _currentValue = 0;
  double _displayValue = 0;
  
  // 进度调节
  Duration _seekStartPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;
  Duration _seekPosition = Duration.zero;
  
  // 指示器
  bool _showIndicator = false;

  Future<void> _initBrightness() async {
    if (kIsWeb) {
      _currentValue = 0.5;
      return;
    }
    try {
      _currentValue = await ScreenBrightness.instance.application;
    } catch (e) {
      _currentValue = 0.5;
    }
  }

  Future<void> _setBrightness(double value) async {
    if (kIsWeb) return;
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(value);
    } catch (e) {}
  }

  Future<void> _resetBrightness() async {
    if (kIsWeb) return;
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (e) {}
  }

  @override
  void dispose() {
    _resetBrightness();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayManager = Provider.of<FlickDisplayManager>(context);
    final controlManager = Provider.of<FlickControlManager>(context, listen: false);
    final videoManager = Provider.of<FlickVideoManager>(context, listen: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        return Stack(
          children: [
            // 主手势检测器
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                
                // 点击 - 显示/隐藏控制层
                onTap: () {
                  displayManager.handleVideoTap();
                },
                
                // 双击 - 快进/快退
                onDoubleTapDown: (details) {
                  final x = details.localPosition.dx;
                  if (x < screenWidth / 2) {
                    controlManager.seekBackward(widget.seekDuration);
                  } else {
                    controlManager.seekForward(widget.seekDuration);
                  }
                },
                
                // 拖动开始
                onPanStart: (details) {
                  _dragStart = details.localPosition;
                  _dragDirection = null;
                  
                  // 预设调节类型
                  if (details.localPosition.dx < screenWidth / 2) {
                    _adjustType = 'brightness';
                    _initBrightness();
                  } else {
                    _adjustType = 'volume';
                    _currentValue = videoManager.videoPlayerValue?.volume ?? 1.0;
                  }
                  _displayValue = _currentValue;
                  
                  // 获取播放位置
                  _seekStartPosition = videoManager.videoPlayerValue?.position ?? Duration.zero;
                  _videoDuration = videoManager.videoPlayerValue?.duration ?? Duration.zero;
                },
                
                // 拖动更新
                onPanUpdate: (details) {
                  final deltaX = details.localPosition.dx - _dragStart.dx;
                  final deltaY = _dragStart.dy - details.localPosition.dy;
                  
                  // 确定方向（第一次超过阈值时）
                  if (_dragDirection == null && (deltaX.abs() > 10 || deltaY.abs() > 10)) {
                    _dragDirection = deltaX.abs() > deltaY.abs() ? 'horizontal' : 'vertical';
                    if (_dragDirection == 'horizontal') {
                      _adjustType = 'seek';
                    }
                  }
                  
                  if (_dragDirection == 'horizontal') {
                    // 进度调节
                    if (_videoDuration.inMilliseconds > 0) {
                      final seekRatio = deltaX / screenWidth * 0.5;
                      final seekDelta = Duration(
                        milliseconds: (_videoDuration.inMilliseconds * seekRatio).toInt()
                      );
                      _seekPosition = (_seekStartPosition + seekDelta);
                      if (_seekPosition < Duration.zero) _seekPosition = Duration.zero;
                      if (_seekPosition > _videoDuration) _seekPosition = _videoDuration;
                      _displayValue = _seekPosition.inMilliseconds / _videoDuration.inMilliseconds;
                      
                      setState(() => _showIndicator = true);
                    }
                  } else if (_dragDirection == 'vertical') {
                    // 音量/亮度调节
                    const sensitivity = 1.5;
                    final delta = (deltaY / screenHeight) * sensitivity;
                    _displayValue = (_currentValue + delta).clamp(0.0, 1.0);
                    
                    setState(() => _showIndicator = true);
                    
                    if (_adjustType == 'volume') {
                      controlManager.setVolume(_displayValue);
                    } else if (_adjustType == 'brightness') {
                      _setBrightness(_displayValue);
                    }
                  }
                },
                
                // 拖动结束
                onPanEnd: (details) {
                  if (_dragDirection == 'horizontal' && _adjustType == 'seek') {
                    if (_videoDuration.inMilliseconds > 0) {
                      controlManager.seekTo(_seekPosition);
                    }
                  }
                  
                  _dragDirection = null;
                  
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      setState(() => _showIndicator = false);
                    }
                  });
                },
                
                child: widget.child ?? const SizedBox.expand(),
              ),
            ),
            
            // 调节指示器
            if (_showIndicator)
              IgnorePointer(
                child: Center(child: _buildIndicator()),
              ),
          ],
        );
      },
    );
  }

  Widget _buildIndicator() {
    if (_adjustType == 'seek') {
      return _buildSeekIndicator();
    }
    
    final icon = _adjustType == 'volume'
        ? (_displayValue > 0 ? Icons.volume_up : Icons.volume_off)
        : Icons.brightness_6;
    final label = _adjustType == 'volume' ? '音量' : '亮度';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: _displayValue,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(_displayValue * 100).toInt()}%',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSeekIndicator() {
    final seekDelta = _seekPosition - _seekStartPosition;
    final isForward = seekDelta >= Duration.zero;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isForward ? Icons.fast_forward : Icons.fast_rewind,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            '${isForward ? '+' : ''}${_formatDuration(seekDelta)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatDuration(_seekPosition)} / ${_formatDuration(_videoDuration)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 150,
            child: LinearProgressIndicator(
              value: _displayValue.clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final isNegative = duration.isNegative;
    final d = isNegative ? -duration : duration;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${isNegative ? '-' : ''}${d.inHours}:$minutes:$seconds';
    }
    return '${isNegative ? '-' : ''}$minutes:$seconds';
  }
}
