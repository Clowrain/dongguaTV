import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// 本地缓存服务
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  late Box<Map> _historyBox;
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  /// 初始化
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    _historyBox = await Hive.openBox<Map>('watch_history');
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  // ============ 服务器配置 ============

  /// 保存服务器地址
  Future<void> saveServerUrl(String url) async {
    await _prefs.setString('server_url', url);
  }

  /// 获取服务器地址
  String? getServerUrl() {
    return _prefs.getString('server_url');
  }

  /// 保存认证 Token
  Future<void> saveAuthToken(String token) async {
    await _prefs.setString('auth_token', token);
  }

  /// 获取认证 Token
  String? getAuthToken() {
    return _prefs.getString('auth_token');
  }

  /// 清除认证
  Future<void> clearAuth() async {
    await _prefs.remove('auth_token');
  }

  // ============ 观看历史 ============

  /// 获取所有观看历史
  List<WatchHistory> getWatchHistory() {
    final items = <WatchHistory>[];
    for (final key in _historyBox.keys) {
      final data = _historyBox.get(key);
      if (data != null) {
        try {
          items.add(WatchHistory.fromJson(Map<String, dynamic>.from(data)));
        } catch (_) {}
      }
    }
    // 按更新时间倒序排列
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  /// 获取单个观看历史
  WatchHistory? getHistoryById(String id) {
    final data = _historyBox.get(id);
    if (data != null) {
      return WatchHistory.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  /// 保存观看历史
  Future<void> saveHistory(WatchHistory history) async {
    await _historyBox.put(history.id, history.toJson());
  }

  /// 删除观看历史
  Future<void> deleteHistory(String id) async {
    await _historyBox.delete(id);
  }

  /// 清空所有观看历史
  Future<void> clearHistory() async {
    await _historyBox.clear();
  }

  /// 批量保存观看历史 (用于同步)
  Future<void> saveHistoryBatch(List<WatchHistory> items) async {
    final map = <String, Map>{};
    for (final item in items) {
      map[item.id] = item.toJson();
    }
    await _historyBox.putAll(map);
  }

  // ============ 搜索历史 ============

  /// 获取搜索历史
  List<String> getSearchHistory() {
    return _prefs.getStringList('search_history') ?? [];
  }

  /// 添加搜索历史
  Future<void> addSearchHistory(String keyword) async {
    final history = getSearchHistory();
    // 移除重复项
    history.remove(keyword);
    // 添加到开头
    history.insert(0, keyword);
    // 保留最近 20 条
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }
    await _prefs.setStringList('search_history', history);
  }

  /// 删除搜索历史
  Future<void> removeSearchHistory(String keyword) async {
    final history = getSearchHistory();
    history.remove(keyword);
    await _prefs.setStringList('search_history', history);
  }

  /// 清空搜索历史
  Future<void> clearSearchHistory() async {
    await _prefs.remove('search_history');
  }

  // ============ 其他设置 ============

  /// 保存设置
  Future<void> setSetting(String key, dynamic value) async {
    if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is String) {
      await _prefs.setString(key, value);
    }
  }

  /// 获取 bool 设置
  bool getBoolSetting(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  /// 获取 int 设置
  int getIntSetting(String key, {int defaultValue = 0}) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  /// 获取 String 设置
  String getStringSetting(String key, {String defaultValue = ''}) {
    return _prefs.getString(key) ?? defaultValue;
  }
}
