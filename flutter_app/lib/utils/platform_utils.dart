import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 平台检测工具类
class PlatformUtils {
  static const MethodChannel _channel = MethodChannel('com.donggua.tv/platform');

  /// 是否是 Android TV
  static bool _isAndroidTV = false;
  static bool _platformChecked = false;

  /// 初始化平台检测（在应用启动时调用）
  static Future<void> init() async {
    if (_platformChecked) return;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<bool>('isAndroidTV');
        _isAndroidTV = result ?? false;
      } catch (e) {
        // 如果原生方法不可用，尝试通过屏幕特征判断
        _isAndroidTV = await _checkByScreenFeatures();
      }
    }

    _platformChecked = true;
  }

  /// 通过屏幕特征判断是否是 TV（备用方案）
  static Future<bool> _checkByScreenFeatures() async {
    // TV 通常是横屏、大屏幕
    // 这是一个简化的判断，实际应该通过原生代码检测
    return false;
  }

  /// 是否是 Android TV
  static bool get isAndroidTV => _isAndroidTV;

  /// 是否是移动设备
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS) && !_isAndroidTV;

  /// 是否是桌面设备
  static bool get isDesktop => !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  /// 是否是 Web
  static bool get isWeb => kIsWeb;

  /// 是否是 Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// 是否是 iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// 是否是 macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// 是否需要 D-pad 导航（TV 和部分设备）
  static bool get needsDPadNavigation => _isAndroidTV;

  /// 是否应该使用 10-foot UI（TV 大屏界面）
  static bool get use10FootUI => _isAndroidTV;

  /// 获取推荐的触摸目标尺寸
  static double get recommendedTouchTargetSize {
    if (_isAndroidTV) return 48.0; // TV 上的焦点目标
    return 44.0; // 移动设备上的触摸目标
  }

  /// 获取推荐的字体缩放
  static double get recommendedFontScale {
    if (_isAndroidTV) return 1.3; // TV 上字体需要更大
    return 1.0;
  }

  /// 获取推荐的间距倍数
  static double get recommendedSpacingScale {
    if (_isAndroidTV) return 1.5; // TV 上间距需要更大
    return 1.0;
  }
}
