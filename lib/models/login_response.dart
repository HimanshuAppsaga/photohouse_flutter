import 'user_model.dart';

class LoginResponse {
  final UserModel user;
  final String token;
  final String tokenType;

  const LoginResponse({
    required this.user,
    required this.token,
    required this.tokenType,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: UserModel.fromJson(json['user']),
      token: json['token'],
      tokenType: json['token_type'] ?? 'Bearer',
    );
  }
}
