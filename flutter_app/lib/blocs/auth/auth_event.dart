import 'package:equatable/equatable.dart';

/// 认证事件基类
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// 检查认证状态
class AuthCheckRequested extends AuthEvent {}

/// 设置服务器地址
class AuthServerSet extends AuthEvent {
  final String serverUrl;

  const AuthServerSet(this.serverUrl);

  @override
  List<Object?> get props => [serverUrl];
}

/// 提交密码
class AuthPasswordSubmitted extends AuthEvent {
  final String password;

  const AuthPasswordSubmitted(this.password);

  @override
  List<Object?> get props => [password];
}

/// 登出
class AuthLogoutRequested extends AuthEvent {}
