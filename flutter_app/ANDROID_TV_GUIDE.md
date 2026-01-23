# Android TV 适配指南

本项目已完成 Android TV 的适配工作，以下是主要功能和使用说明。

## 📋 目录

1. [已实现的功能](#已实现的功能)
2. [快速开始](#快速开始)
3. [平台特性](#平台特性)
4. [使用组件](#使用组件)
5. [构建和测试](#构建和测试)
6. [文件结构](#文件结构)
7. [常见问题](#常见问题)

## 已实现的功能

### 1. 平台检测
- ✅ 自动检测 Android TV 设备
- ✅ 通过 `PlatformUtils.isAndroidTV` 判断当前运行平台
- ✅ 原生 Kotlin 代码检测 TV 模式

### 2. AndroidManifest 配置
- ✅ 添加 `android.software.leanback` 支持
- ✅ 触摸屏设置为非必需 (`android.hardware.touchscreen` required=false)
- ✅ 添加 `LEANBACK_LAUNCHER` category
- ✅ 添加 TV banner 图标

### 3. 遥控器/D-pad 导航
- ✅ 完整的键盘事件处理
- ✅ 方向键导航支持
- ✅ OK/Enter 键选择支持
- ✅ 返回键处理

#### 播放器快捷键
- **空格/播放暂停键**: 播放/暂停
- **左箭头**: 快退 10 秒
- **右箭头**: 快进 10 秒
- **Enter/OK**: 显示/隐藏控制条
- **返回键**: 退出播放器

### 4. 焦点管理系统
创建了完整的焦点管理组件：

#### `TvFocusable`
基础可聚焦 Widget，提供焦点边框和动画效果。

```dart
TvFocusable(
  autofocus: true,
  onTap: () => print('Tapped'),
  child: YourWidget(),
)
```

#### `TvFocusableButton`
TV 专用按钮，自动处理焦点和点击。

```dart
TvFocusableButton(
  onPressed: () => print('Pressed'),
  child: Text('按钮'),
)
```

### 5. TV UI 组件 (10-foot UI)
提供了针对大屏优化的 UI 组件：

#### `TvCard`
```dart
TvCard(
  onTap: () {},
  child: YourContent(),
)
```

#### `TvGridView`
```dart
TvGridView(
  crossAxisCount: 4,
  children: items,
)
```

#### `TvListTile`
```dart
TvListTile(
  title: Text('标题'),
  subtitle: Text('副标题'),
  onTap: () {},
)
```

#### `TvText`
自动根据 TV 平台调整字体大小。

```dart
TvText('这是文本', style: TextStyle(...))
```

### 6. 视频播放器 TV 优化

#### TV 专用控制器 `DongguaTvControls`
- 更大的控制按钮（适合 10-foot UI）
- 完整的遥控器支持
- 焦点管理和键盘导航
- 自动隐藏控制条

使用方法：
```dart
FlickVideoPlayer(
  flickManager: manager,
  flickVideoWithControlsFullscreen: FlickVideoWithControls(
    controls: PlatformUtils.isAndroidTV
        ? DongguaTvControls(
            title: videoTitle,
            episodeName: episodeName,
            onBack: () {},
            hasNextEpisode: true,
            onNextEpisode: () {},
          )
        : DongguaLandscapeControls(...),
  ),
)
```

## 平台特性

### 推荐尺寸
- **触摸目标**: `PlatformUtils.recommendedTouchTargetSize`
  - TV: 48.0
  - 移动设备: 44.0

- **字体缩放**: `PlatformUtils.recommendedFontScale`
  - TV: 1.3
  - 其他: 1.0

- **间距缩放**: `PlatformUtils.recommendedSpacingScale`
  - TV: 1.5
  - 其他: 1.0

### 使用示例
```dart
final scale = PlatformUtils.recommendedSpacingScale;
final fontScale = PlatformUtils.recommendedFontScale;

// 自动适配的间距
padding: EdgeInsets.all(16 * scale),

// 自动适配的字体
fontSize: 14 * fontScale,
```

## 构建和测试

### 快速开始

#### 步骤 1: 构建 APK
```bash
cd flutter_app
flutter build apk --release
```

#### 步骤 2: 安装到 TV
```bash
# 通过 USB
adb install build/app/outputs/flutter-apk/app-release.apk

# 或通过 WiFi
adb connect <TV_IP>:5555
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Android TV APK 构建

#### 开发版本
```bash
flutter build apk --debug
```

#### 发布版本
```bash
flutter build apk --release --split-per-abi
```
这会生成针对不同架构优化的 APK：
- `app-armeabi-v7a-release.apk` (32位 ARM)
- `app-arm64-v8a-release.apk` (64位 ARM - 推荐)
- `app-x86_64-release.apk` (x86 模拟器)

### 在 Android TV 模拟器测试
1. 打开 Android Studio
2. 创建 Android TV 设备 (AVD Manager > Create Virtual Device > TV)
   - 推荐: 1080p TV (1920x1080)
   - API Level: 29 或更高
3. 启动模拟器
4. 运行应用: `flutter run`

### 真机测试

#### 启用开发者选项（以小米电视为例）
1. 打开设置 > 关于
2. 连续点击 "版本号" 7次
3. 返回设置，找到 "开发者选项"
4. 启用 "USB 调试" 和 "ADB 调试"

#### 无线 ADB 连接
```bash
# 1. 首次需要 USB 连接
adb tcpip 5555

# 2. 断开 USB，通过 WiFi 连接
adb connect <TV_IP_ADDRESS>:5555

# 3. 验证连接
adb devices

# 4. 运行应用
flutter run
```

#### 查看日志
```bash
# 实时查看日志
adb logcat | grep flutter

# 或使用 Flutter 工具
flutter logs
```

## 注意事项

1. **自动初始化**: 平台检测在 `main.dart` 中自动初始化，无需手动调用
2. **条件渲染**: 在需要的地方使用 `PlatformUtils.isAndroidTV` 判断平台
3. **焦点顺序**: 使用 `autofocus: true` 设置默认焦点
4. **触摸兼容**: 所有 TV 组件同时支持触摸操作，兼容移动设备

## 文件结构

```
flutter_app/
├── lib/
│   ├── utils/
│   │   └── platform_utils.dart          # 平台检测工具
│   ├── widgets/
│   │   ├── tv/
│   │   │   ├── tv_focusable.dart        # 焦点管理组件
│   │   │   ├── tv_widgets.dart          # TV UI 组件
│   │   │   └── tv.dart                  # 导出文件
│   │   ├── player/
│   │   │   └── controls/
│   │   │       └── donggua_tv_controls.dart  # TV 播放器控制
│   │   └── screens/
│   │       └── tv_home_media_card.dart  # TV 媒体卡片
│   └── main.dart                        # 入口文件（已添加初始化）
└── android/
    └── app/src/main/
        ├── AndroidManifest.xml          # TV 配置
        └── kotlin/.../MainActivity.kt    # TV 检测原生代码
```

## 后续优化建议

1. **首页优化**: 将 `HomeMediaCard` 替换为 `TvHomeMediaCard` 以提供更好的 TV 体验
2. **详情页**: 添加 TV 专用的详情页布局
3. **搜索**: 实现 TV 键盘输入支持
4. **设置**: 添加 TV 遥控器快捷键配置
5. **Banner 图标**: 为 TV Launcher 创建专用的 1280x720 banner 图片

## 相关资源

- [Android TV 开发指南](https://developer.android.com/training/tv)
- [Flutter Focus 系统文档](https://docs.flutter.dev/development/ui/advanced/focus)
- [Material Design for TV](https://material.io/design/platform-guidance/android-tv.html)

## 常见问题

### Q: 为什么应用在 TV Launcher 中不显示？
A: 检查以下几点：
1. `AndroidManifest.xml` 中是否添加了 `LEANBACK_LAUNCHER` category
2. 是否声明了 `android.software.leanback` feature
3. 是否设置了 `touchscreen` 为非必需

### Q: 遥控器按键无响应怎么办？
A:
1. 确保使用了 `TvFocusable` 组件包装可交互元素
2. 检查是否有元素设置了 `autofocus: true`
3. 使用 `flutter run` 查看是否有焦点相关的错误日志

### Q: 如何调试 TV 应用的焦点问题？
A:
```dart
// 添加焦点调试
Focus(
  onFocusChange: (hasFocus) {
    debugPrint('焦点状态: $hasFocus');
  },
  child: YourWidget(),
)
```

### Q: TV 上字体看起来太小？
A: 确保使用了 `PlatformUtils.recommendedFontScale`：
```dart
fontSize: 16 * PlatformUtils.recommendedFontScale
```

### Q: 如何禁用触摸滑动，只使用遥控器？
A: 在需要的地方添加平台判断：
```dart
if (!PlatformUtils.isAndroidTV) {
  // 触摸手势代码
}
```

### Q: 播放器控制条不显示？
A: 检查：
1. 是否在全屏模式下使用了 `DongguaTvControls`
2. 按下 OK/Enter 键尝试切换显示状态
3. 查看控制台是否有错误

### Q: 如何在 TV 和手机上使用不同的布局？
A:
```dart
Widget build(BuildContext context) {
  if (PlatformUtils.isAndroidTV) {
    return TvLayout();
  }
  return MobileLayout();
}
```

### Q: TV Banner 图标不显示？
A:
1. 确保 Banner 文件存在于 `res/drawable` 目录
2. 检查 `AndroidManifest.xml` 中的引用是否正确
3. 重新构建 APK

### Q: 如何测试不同的焦点顺序？
A: 使用 `FocusTraversalGroup` 和 `FocusOrder`：
```dart
FocusTraversalGroup(
  policy: OrderedTraversalPolicy(),
  child: Column(
    children: [
      FocusTraversalOrder(order: NumericFocusOrder(1), child: Button1()),
      FocusTraversalOrder(order: NumericFocusOrder(2), child: Button2()),
    ],
  ),
)
```

### Q: 性能优化建议？
A:
1. 使用 `const` 构造函数减少重建
2. 图片使用 `CachedNetworkImage` 缓存
3. 列表使用 `ListView.builder` 懒加载
4. 避免在焦点变化时做重量级操作

### Q: 如何支持游戏手柄？
A: Flutter 自动支持游戏手柄的方向键和按钮，与遥控器使用相同的键盘事件。

### Q: 多国语言支持？
A: 使用 Flutter 的国际化功能，TV 会自动使用系统语言设置。

## 更新日志

### v1.0.0 (2026-01-23)
- ✅ 完成 Android TV 基础适配
- ✅ 实现焦点管理系统
- ✅ 添加 TV 专用播放器控制器
- ✅ 优化 10-foot UI
- ✅ 支持遥控器导航

### 下一步计划
- [ ] 搜索页虚拟键盘优化
- [ ] 语音搜索支持
- [ ] 个性化推荐
- [ ] 家长控制功能

## 贡献

欢迎提交 Issue 和 Pull Request 来改进 Android TV 支持！

## 许可证

本项目遵循原项目的许可证。
