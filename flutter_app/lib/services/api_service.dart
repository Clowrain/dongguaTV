import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../models/models.dart';

/// API 服务
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
    level: Level.warning, // 只显示警告和错误
  );

  late Dio _dio;
  bool _isInitialized = false;

  /// 初始化
  void init({String? baseUrl}) {
    final url = baseUrl ?? AppConfig().serverUrl;
    
    _dio = Dio(BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // 调试模式下可以取消注释以下代码查看日志
    // _dio.interceptors.add(LogInterceptor(
    //   requestBody: false,
    //   responseBody: false,
    //   logPrint: (obj) => _logger.d(obj),
    // ));

    _isInitialized = true;
  }

  /// 确保已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('ApiService not initialized. Call init() first.');
    }
  }

  /// 更新服务器地址
  void updateBaseUrl(String url) {
    // 移除末尾斜杠，避免与路径拼接时产生双斜杠
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    _dio.options.baseUrl = cleanUrl;
    AppConfig().serverUrl = cleanUrl;
    _logger.i('ApiService baseUrl updated: $cleanUrl');
  }

  // ============ 配置相关 API ============

  /// 获取服务器配置
  Future<Map<String, dynamic>> getConfig({String? token}) async {
    _ensureInitialized();
    try {
      final response = await _dio.get('/api/config', queryParameters: {
        if (token != null) 'token': token,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      _logger.e('getConfig error: $e');
      rethrow;
    }
  }

  /// 获取站点列表
  Future<List<Site>> getSites() async {
    _ensureInitialized();
    try {
      final response = await _dio.get('/api/sites');
      final data = response.data as Map<String, dynamic>;
      final sites = (data['sites'] as List<dynamic>?)
          ?.map((e) => Site.fromJson(e as Map<String, dynamic>))
          .where((s) => s.active)
          .toList() ?? [];
      return sites;
    } catch (e) {
      _logger.e('getSites error: $e');
      rethrow;
    }
  }

  // ============ 认证相关 API ============

  /// 检查是否需要密码
  Future<Map<String, dynamic>> checkAuth() async {
    _ensureInitialized();
    try {
      final response = await _dio.get('/api/auth/check');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      _logger.e('checkAuth error: $e');
      rethrow;
    }
  }

  /// 验证密码
  Future<Map<String, dynamic>> verifyPassword(String password) async {
    _ensureInitialized();
    try {
      final response = await _dio.post('/api/auth/verify', data: {
        'password': password,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      _logger.e('verifyPassword error: $e');
      rethrow;
    }
  }

  // ============ 搜索相关 API ============

  /// 流式搜索 (SSE)
  Stream<List<VideoItem>> searchStream(String keyword) async* {
    _ensureInitialized();
    
    try {
      final response = await _dio.get(
        '/api/search',
        queryParameters: {
          'wd': keyword,
          'stream': 'true',
          'smart': 'true',
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
          },
        ),
      );

      final stream = response.data.stream as Stream<List<int>>;
      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);
        
        // 解析 SSE 数据
        final lines = buffer.split('\n');
        buffer = lines.last; // 保留未完成的行
        
        for (final line in lines.take(lines.length - 1)) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isEmpty || jsonStr == '{}') continue;
            
            try {
              final data = json.decode(jsonStr);
              if (data is List) {
                final items = data
                    .map((e) => VideoItem.fromJson(e as Map<String, dynamic>))
                    .toList();
                yield items;
              }
            } catch (e) {
              _logger.w('Parse SSE data error: $e');
            }
          } else if (line.startsWith('event: done')) {
            // 搜索完成
            return;
          }
        }
      }
    } catch (e) {
      _logger.e('searchStream error: $e');
      rethrow;
    }
  }

  /// 单站点搜索
  Future<List<VideoItem>> searchSite(String keyword, String siteKey) async {
    _ensureInitialized();
    try {
      final response = await _dio.post('/api/search', data: {
        'keyword': keyword,
        'siteKey': siteKey,
      });
      final data = response.data as Map<String, dynamic>;
      final list = (data['list'] as List<dynamic>?)
          ?.map((e) => VideoItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];
      return list;
    } catch (e) {
      _logger.e('searchSite error: $e');
      rethrow;
    }
  }

  // ============ 详情相关 API ============

  /// 获取视频详情
  Future<VideoDetail?> getDetail(String vodId, String siteKey) async {
    _ensureInitialized();
    try {
      final response = await _dio.get('/api/detail', queryParameters: {
        'id': vodId,
        'site_key': siteKey,
      });
      final data = response.data as Map<String, dynamic>;
      final list = data['list'] as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        return VideoDetail.fromJson(
          list[0] as Map<String, dynamic>,
          siteKey: siteKey,
        );
      }
      return null;
    } catch (e) {
      _logger.e('getDetail error: $e');
      rethrow;
    }
  }

  // ============ TMDB 相关 API ============

  /// TMDB 代理请求
  /// [path] TMDB API 路径
  /// [params] 作为 Map 传递的参数（会被转换为 query parameters）
  /// [rawParams] 原始参数字符串，直接拼接到 URL（如 'with_origin_country=CN&sort_by=...'）
  Future<Map<String, dynamic>> tmdbProxy(
    String path, {
    Map<String, dynamic>? params,
    String? rawParams,
  }) async {
    _ensureInitialized();
    try {
      // 构建基础 URL
      String url = '/api/tmdb-proxy?path=${Uri.encodeComponent(path)}';
      
      // 添加 Map 参数
      if (params != null && params.isNotEmpty) {
        for (final entry in params.entries) {
          url += '&${entry.key}=${Uri.encodeComponent(entry.value.toString())}';
        }
      }
      
      // 添加原始参数字符串（已经是 key=value 格式）
      if (rawParams != null && rawParams.isNotEmpty) {
        url += '&$rawParams';
      }
      
      final response = await _dio.get(url);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      _logger.e('tmdbProxy error: $e');
      rethrow;
    }
  }

  /// 获取 TMDB 趋势列表
  Future<TmdbPageResponse> getTrending({
    String mediaType = 'all',
    String timeWindow = 'week',
    int page = 1,
  }) async {
    final data = await tmdbProxy(
      '/trending/$mediaType/$timeWindow',
      params: {'page': page},
    );
    return TmdbPageResponse.fromJson(data);
  }

  /// 获取榜单数据（按 web rowConfigs 的方式）
  /// [path] TMDB API 路径，如 '/trending/movie/week' 或 '/discover/tv'
  /// [params] 额外参数字符串，如 'with_origin_country=CN' 或 'with_genres=16'
  /// [sortMode] 排序模式：'newest' 按日期降序，null 按热度
  Future<TmdbPageResponse> fetchRow({
    required String path,
    String params = '',
    String? sortMode,
    int page = 1,
  }) async {
    // 构建排序参数（和 web 版本一致）
    String sortParam = '';
    if (sortMode != null && path.contains('/discover/')) {
      final isMovie = path.contains('/movie');
      if (sortMode == 'newest') {
        final dateField = isMovie ? 'primary_release_date.desc' : 'first_air_date.desc';
        sortParam = 'sort_by=$dateField&vote_count.gte=10';
      } else {
        sortParam = 'sort_by=popularity.desc';
      }
    }

    // 构建完整的额外参数
    final extraParams = [
      if (params.isNotEmpty) params,
      if (sortParam.isNotEmpty) sortParam,
      'page=$page',
    ].join('&');

    // 调用 tmdb-proxy，将 path 和额外参数传递
    final data = await tmdbProxy(path, rawParams: extraParams);
    return TmdbPageResponse.fromJson(data);
  }

  // ============ 历史记录相关 API ============

  /// 拉取观看历史
  Future<List<WatchHistory>> pullHistory(String token) async {
    _ensureInitialized();
    try {
      final response = await _dio.get('/api/history/pull', queryParameters: {
        'token': token,
      });
      final data = response.data as Map<String, dynamic>;
      final history = (data['history'] as List<dynamic>?)
          ?.map((e) => WatchHistory.fromJson(
                (e['data'] ?? e) as Map<String, dynamic>,
              ))
          .toList() ?? [];
      return history;
    } catch (e) {
      _logger.e('pullHistory error: $e');
      rethrow;
    }
  }

  /// 推送观看历史
  Future<void> pushHistory(String token, List<WatchHistory> history) async {
    _ensureInitialized();
    try {
      await _dio.post('/api/history/push', data: {
        'token': token,
        'history': history.map((h) => {
          'id': h.id,
          'data': h.toJson(),
          'updated_at': h.updatedAt.millisecondsSinceEpoch,
        }).toList(),
      });
    } catch (e) {
      _logger.e('pushHistory error: $e');
      rethrow;
    }
  }

  /// 检查站点延迟（服务器端测速）
  /// 返回延迟毫秒数，失败返回 null
  Future<int?> checkSiteLatency(String siteKey) async {
    _ensureInitialized();
    final url = '${_dio!.options.baseUrl}/api/check?key=$siteKey';
    try {
      final response = await _dio!.get('/api/check', queryParameters: {
        'key': siteKey,
      });
      
      if (response.data != null && response.data['latency'] != null) {
        return response.data['latency'] as int;
      }
      return null;
    } catch (e) {
      _logger.w('checkSiteLatency error for $siteKey, URL: $url, error: $e');
      return null;
    }
  }
}
