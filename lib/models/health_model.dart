class HealthModel {
  final String status;
  final String app;

  const HealthModel({
    required this.status,
    required this.app,
  });

  static const HealthModel sample = HealthModel(
    status: 'ok',
    app: 'PhotoHouse',
  );

  bool get isHealthy => status.toLowerCase() == 'ok';

  factory HealthModel.fromJson(Map<String, dynamic> json) {
    return HealthModel(
      status: json['status']?.toString() ?? 'unknown',
      app: json['app']?.toString() ?? 'PhotoHouse',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'app': app,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthModel &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          app == other.app;

  @override
  int get hashCode => status.hashCode ^ app.hashCode;

  @override
  String toString() => 'HealthModel(status: $status, app: $app)';
}
