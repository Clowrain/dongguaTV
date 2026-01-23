import 'dart:async';
import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import '../../models/models.dart';
import '../../services/services.dart';

/// 带延迟信息的源
class SourceWithLatency {
  final VideoItem source;
  int? latency; // null = 测试中, -1 = 超时/失败
  String testType; // direct, proxy, server
  bool useProxy; // 是否使用代理
  String? proxyUrl; // 代理 URL
  VideoDetail? cachedDetail; // 缓存的详情数据

  SourceWithLatency({
    required this.source,
    this.latency,
    this.testType = 'server',
    this.useProxy = false,
    this.proxyUrl,
    this.cachedDetail,
  });
}

/// 源测速器
class SourceLatencyTester {
  final Function(SourceWithLatency) onSourceTested;
  final Function() onComplete;

  SourceLatencyTester({
    required this.onSourceTested,
    required this.onComplete,
  });

  /// 测试所有源的延迟
  Future<void> testAllSources(List<SourceWithLatency> sources) async {
    const fastThreshold = 600; // 快速返回阈值 (ms)
    const earlyReturnCount = 2; // 找到这么多快速线路就提前返回
    const maxWaitTime = Duration(seconds: 5); // 最大等待时间

    bool hasEarlyReturned = false;

    // 设置超时自动选择定时器
    Future.delayed(maxWaitTime, () {
      if (!hasEarlyReturned) {
        onComplete();
      }
    });

    final futures = <Future>[];
    for (final source in sources) {
      futures.add(
        Future(() async {
          try {
            await testSourceLatency(source);
          } catch (e) {
            // 单个源测速失败
            source.latency = 9999;
            source.testType = 'failed';
            onSourceTested(source);
          }
        }).then((_) {
          // 每个测速完成后检查是否可以提前返回
          if (!hasEarlyReturned) {
            final fastSources = sources.where((s) =>
                s.testType == 'direct' && s.latency != null && s.latency! > 0 && s.latency! < fastThreshold
            ).toList();

            if (fastSources.length >= earlyReturnCount) {
              hasEarlyReturned = true;
              onComplete();
            }
          }
        }),
      );
    }

    await Future.wait(futures);

    if (!hasEarlyReturned) {
      onComplete();
    }
  }

  /// 测试单个源的延迟
  Future<void> testSourceLatency(SourceWithLatency source) async {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 5);
    dio.options.receiveTimeout = const Duration(seconds: 5);

    try {
      // 1. 获取该源的视频详情
      VideoDetail? detail;
      try {
        detail = await ApiService().getDetail(
          source.source.vodId,
          source.source.siteKey,
        );
        source.cachedDetail = detail;
      } catch (e) {
        // 详情获取失败，回退到服务器测速
        await _fallbackToServerTest(source);
        return;
      }

      // 2. 解析出第一个视频 URL（m3u8）
      String? videoUrl;
      if (detail != null && detail.playSources.isNotEmpty) {
        final firstSource = detail.playSources.first;
        if (firstSource.episodes.isNotEmpty) {
          videoUrl = firstSource.episodes.first.url;
        }
      }

      if (videoUrl == null || !videoUrl.startsWith('http')) {
        await _fallbackToServerTest(source);
        return;
      }

      // 3. 直连测试 m3u8 URL
      bool directSuccess = false;
      int directLatency = 0;
      const int slowThreshold = 1500;

      try {
        final stopwatch = Stopwatch()..start();
        await dio.head(
          videoUrl,
          options: Options(validateStatus: (_) => true),
        );
        stopwatch.stop();
        directLatency = stopwatch.elapsedMilliseconds;

        if (directLatency < 5000) {
          directSuccess = true;
          source.latency = directLatency;
          source.testType = 'direct';
          onSourceTested(source);
        }
      } catch (e) {
        // 直连失败，继续尝试代理
      }

      // 4. 如果直连失败或太慢，尝试代理
      final corsProxyUrl = AppConfig().corsProxyUrl;
      final shouldTryProxy = !directSuccess || (directSuccess && directLatency > slowThreshold);

      if (shouldTryProxy && corsProxyUrl.isNotEmpty) {
        try {
          final proxyUrl = '$corsProxyUrl/?url=${Uri.encodeComponent(videoUrl)}';
          final stopwatch = Stopwatch()..start();

          await dio.head(
            proxyUrl,
            options: Options(validateStatus: (_) => true),
          );
          stopwatch.stop();
          final proxyLatency = stopwatch.elapsedMilliseconds;

          // 如果直连失败则用代理，如果代理快30%以上也用代理
          final useProxy = !directSuccess || (proxyLatency < directLatency * 0.7);

          if (useProxy) {
            source.latency = proxyLatency;
            source.testType = 'proxy';
            source.useProxy = true;
            source.proxyUrl = corsProxyUrl;
            onSourceTested(source);
            return;
          }
        } catch (e) {
          // 代理也失败
        }
      }

      // 5. 都失败了，回退服务器测速
      if (!directSuccess) {
        await _fallbackToServerTest(source);
      }
    } catch (e) {
      source.latency = 9999;
      source.testType = 'failed';
      onSourceTested(source);
    }
  }

  /// 回退到服务器测速
  Future<void> _fallbackToServerTest(SourceWithLatency source) async {
    try {
      final latency = await ApiService().checkSiteLatency(source.source.siteKey);
      source.latency = latency ?? 9999;
      source.testType = 'server';
      onSourceTested(source);
    } catch (e) {
      source.latency = 9999;
      source.testType = 'server';
      onSourceTested(source);
    }
  }
}
