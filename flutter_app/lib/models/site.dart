import 'package:equatable/equatable.dart';

/// 资源站点模型
class Site extends Equatable {
  /// 唯一标识
  final String key;
  
  /// 站点名称
  final String name;
  
  /// API 地址
  final String api;
  
  /// 是否启用
  final bool active;

  const Site({
    required this.key,
    required this.name,
    required this.api,
    this.active = true,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      api: json['api'] as String? ?? '',
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'name': name,
      'api': api,
      'active': active,
    };
  }

  @override
  List<Object?> get props => [key, name, api, active];
}
