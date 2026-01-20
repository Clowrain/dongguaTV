import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/watch_history.dart';

/// 观看历史服务 - 使用 ChangeNotifier 管理状态
class WatchHistoryService extends ChangeNotifier {
  static const String _storageKey = 'watch_history_list';
  static const int _maxHistoryCount = 100;
  
  List<WatchHistory> _histories = [];
  bool _isLoaded = false;
  
  /// 获取所有历史记录（按时间倒序）
  List<WatchHistory> get histories => _histories;
  
  /// 是否已加载
  bool get isLoaded => _isLoaded;
  
  /// 获取最近 N 条历史
  List<WatchHistory> getRecent(int limit) {
    return _histories.take(limit).toList();
  }
  
  /// 初始化加载
  Future<void> load() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(jsonStr);
        _histories = jsonList
            .map((e) => WatchHistory.fromJson(e as Map<String, dynamic>))
            .toList();
        // 按时间倒序排列
        _histories.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }
    } catch (e) {
      debugPrint('加载观看历史失败: $e');
      _histories = [];
    }
    
    _isLoaded = true;
    notifyListeners();
  }
  
  /// 保存到本地存储
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(_histories.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('保存观看历史失败: $e');
    }
  }
  
  /// 添加或更新历史记录
  Future<void> save(WatchHistory history) async {
    // 查找是否已存在（按 id 匹配）
    final existingIndex = _histories.indexWhere((h) => h.id == history.id);
    
    if (existingIndex >= 0) {
      // 已存在，更新并移到最前
      _histories.removeAt(existingIndex);
    }
    
    // 添加到最前面
    _histories.insert(0, history);
    
    // 超过上限则删除最旧的
    if (_histories.length > _maxHistoryCount) {
      _histories = _histories.take(_maxHistoryCount).toList();
    }
    
    await _save();
    notifyListeners();
  }
  
  /// 更新播放进度
  Future<void> updateProgress(String id, int progress, int duration) async {
    final index = _histories.indexWhere((h) => h.id == id);
    if (index >= 0) {
      final updated = _histories[index].copyWith(
        progress: progress,
        duration: duration,
      );
      _histories[index] = updated;
      // 移到最前
      if (index > 0) {
        _histories.removeAt(index);
        _histories.insert(0, updated);
      }
      await _save();
      notifyListeners();
    }
  }
  
  /// 获取单个视频的历史记录
  WatchHistory? get(String id) {
    try {
      return _histories.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// 根据 vodName 查找历史（用于从搜索结果恢复）
  WatchHistory? getByVodName(String vodName) {
    try {
      return _histories.firstWhere((h) => h.vodName == vodName);
    } catch (e) {
      return null;
    }
  }
  
  /// 删除单条记录
  Future<void> remove(String id) async {
    _histories.removeWhere((h) => h.id == id);
    await _save();
    notifyListeners();
  }
  
  /// 清空全部历史
  Future<void> clear() async {
    _histories.clear();
    await _save();
    notifyListeners();
  }
}
