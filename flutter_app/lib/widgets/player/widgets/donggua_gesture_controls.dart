import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../player.dart';

/// 立即获胜的垂直拖动手势识别器
/// 在 addPointer 阶段就声明手势，确保能战胜父级的滚动手势
class _ImmediateVerticalDragGestureRecognizer extends VerticalDragGestureRecognizer {
  _ImmediateVerticalDragGestureRecognizer({super.debugOwner});

  @override
  void addPointer(PointerDownEvent event) {
    // 立即声明这个手势，确保能在竞争中获胜
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
    super.addPointer(event);
  }
}

/// 立即获胜的水平拖动手势识别器
class _ImmediateHorizontalDragGestureRecognizer extends HorizontalDragGestureRecognizer {
  _ImmediateHorizontalDragGestureRecognizer({super.debugOwner});

  @override
  void addPointer(PointerDownEvent event) {
    // 立即声明这个手势，确保能在竞争中获胜
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
    super.addPointer(event);
  }
}

/// 手势控制层
/// 
/// 支持：
/// - 水平滑动：调节播放进度
/// - 左半边上下滑动：亮度调节
/// - 右半边上下滑动：音量调节
/// - 点击/双击：由子组件处理（不干扰）
class DongguaGestureControls extends StatefulWidget {
  const DongguaGestureControls({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<DongguaGestureControls> createState() => _DongguaGestureControlsState();
}

class _DongguaGestureControlsState extends State<DongguaGestureControls> {
  // 手势状态
  bool _isDragging = false;
  String _adjustType = ''; // 'volume', 'brightness', 或 'seek'
  String? _panDirection; // 'horizontal' 或 'vertical'
  Offset _startPosition = Offset.zero;
  double _currentValue = 0;
  double _displayValue = 0;
  
  // 进度调节相关
  Duration _seekStartPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;
  Duration _seekPosition = Duration.zero;
  
  // 显示指示器
  bool _showIndicator = false;
  
  // 屏幕尺寸
  double _screenWidth = 0;
  double _screenHeight = 0;
  
  /// 初始化获取当前亮度
  Future<void> _initBrightness() async {
    if (kIsWeb) {
      _currentValue = 0.5;
      return;
    }
    try {
      final brightness = await ScreenBrightness.instance.application;
      _currentValue = brightness;
    } catch (e) {
      _currentValue = 0.5;
    }
  }
  
  /// 设置屏幕亮度
  Future<void> _setBrightness(double value) async {
    if (kIsWeb) return;
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(value);
    } catch (e) {
      // 忽略错误
    }
  }
  
  /// 重置屏幕亮度
  Future<void> _resetBrightness() async {
    if (kIsWeb) return;
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (e) {
      // 忽略错误
    }
  }

  void _onDragStart(Offset position) {
    _startPosition = position;
    _panDirection = null;
    _isDragging = true;
    
    // 根据位置预设调节类型
    if (position.dx < _screenWidth / 2) {
      _adjustType = 'brightness';
      _initBrightness();
    } else {
      _adjustType = 'volume';
      final videoManager = Provider.of<FlickVideoManager>(context, listen: false);
      _currentValue = videoManager.videoPlayerValue?.volume ?? 1.0;
    }
    _displayValue = _currentValue;
    
    // 获取当前播放位置
    final videoManager = Provider.of<FlickVideoManager>(context, listen: false);
    _seekStartPosition = videoManager.videoPlayerValue?.position ?? Duration.zero;
    _videoDuration = videoManager.videoPlayerValue?.duration ?? Duration.zero;
  }

  void _onDragUpdate(Offset position, Offset delta) {
    final deltaX = position.dx - _startPosition.dx;
    final deltaY = _startPosition.dy - position.dy;
    
    // 确定方向
    if (_panDirection == null) {
      if (deltaX.abs() > deltaY.abs()) {
        _panDirection = 'horizontal';
        _adjustType = 'seek';
      } else {
        _panDirection = 'vertical';
      }
    }
    
    if (_panDirection == 'horizontal') {
      _handleSeekUpdate(deltaX);
    } else {
      _handleVerticalUpdate(deltaY);
    }
  }

  void _handleVerticalUpdate(double deltaY) {
    const sensitivity = 1.5;
    final delta = (deltaY / _screenHeight) * sensitivity;
    _displayValue = (_currentValue + delta).clamp(0.0, 1.0);
    
    setState(() {
      _showIndicator = true;
    });
    
    if (_adjustType == 'volume') {
      final controlManager = Provider.of<FlickControlManager>(context, listen: false);
      controlManager.setVolume(_displayValue);
    } else if (_adjustType == 'brightness') {
      _setBrightness(_displayValue);
    }
  }

  void _handleSeekUpdate(double deltaX) {
    if (_videoDuration.inMilliseconds == 0) return;
    
    final seekRatio = deltaX / _screenWidth * 0.5;
    final seekDelta = Duration(milliseconds: (_videoDuration.inMilliseconds * seekRatio).toInt());
    
    _seekPosition = _seekStartPosition + seekDelta;
    if (_seekPosition < Duration.zero) _seekPosition = Duration.zero;
    if (_seekPosition > _videoDuration) _seekPosition = _videoDuration;
    
    _displayValue = _seekPosition.inMilliseconds / _videoDuration.inMilliseconds;
    
    setState(() {
      _showIndicator = true;
    });
  }

  void _onDragEnd() {
    if (_adjustType == 'seek' && _videoDuration.inMilliseconds > 0) {
      final controlManager = Provider.of<FlickControlManager>(context, listen: false);
      controlManager.seekTo(_seekPosition);
    }
    
    _isDragging = false;
    _panDirection = null;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_isDragging) {
        setState(() {
          _showIndicator = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _resetBrightness();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _screenWidth = constraints.maxWidth;
        _screenHeight = constraints.maxHeight;

        // 使用立即获胜的手势识别器
        // 在 addPointer 阶段就声明手势，确保能战胜父级的滚动手势
        return RawGestureDetector(
          gestures: {
            // 垂直拖动手势 - 用于与父级滚动竞争并立即获胜
            _ImmediateVerticalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<_ImmediateVerticalDragGestureRecognizer>(
              () => _ImmediateVerticalDragGestureRecognizer(debugOwner: this),
              (_ImmediateVerticalDragGestureRecognizer instance) {
                instance
                  ..onStart = (details) {
                    _onDragStart(details.localPosition);
                  }
                  ..onUpdate = (details) {
                    _onDragUpdate(details.localPosition, details.delta);
                  }
                  ..onEnd = (details) {
                    _onDragEnd();
                  };
              },
            ),
            // 水平拖动手势 - 用于进度调节
            _ImmediateHorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<_ImmediateHorizontalDragGestureRecognizer>(
              () => _ImmediateHorizontalDragGestureRecognizer(debugOwner: this),
              (_ImmediateHorizontalDragGestureRecognizer instance) {
                instance
                  ..onStart = (details) {
                    _onDragStart(details.localPosition);
                  }
                  ..onUpdate = (details) {
                    _onDragUpdate(details.localPosition, details.delta);
                  }
                  ..onEnd = (details) {
                    _onDragEnd();
                  };
              },
            ),
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // 子组件（控制层）
              widget.child,

              // 调节指示器
              if (_showIndicator)
                IgnorePointer(
                  child: Center(
                    child: _buildIndicator(),
                  ),
                ),
            ],
          ),
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
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
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
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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
