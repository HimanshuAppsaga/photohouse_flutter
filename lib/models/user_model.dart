class UserModel {
  final dynamic id;
  final String name;
  final String email;
  final String role;
  final int tenantId;
  final String studioName;
  final bool emailVerifide;
  final String plan;

  const UserModel({
    this.id = 1,
    required this.name,
    required this.email,
    this.role = 'Photographer',
    this.tenantId = 1,
    this.studioName = 'PhotoHouse Studio',
    this.emailVerifide = true,
    this.plan = 'PRO',
  });

  static const UserModel sampleUser = UserModel(
    id: 1,
    name: 'Maulik Ladumor',
    email: 'maulik@photohouse.com',
    role: 'Admin',
    tenantId: 1,
    studioName: 'PhotoHouse Studio',
    emailVerifide: true,
    plan: 'PRO',
  );

  String get formattedName {
    if (name.isNotEmpty) return name;
    if (email.isNotEmpty) {
      final username = email.split('@').first;
      if (username.isNotEmpty) {
        return username[0].toUpperCase() + username.substring(1);
      }
    }
    return 'User';
  }

  String get firstLetter {
    final displayName = formattedName;
    if (displayName.isNotEmpty) {
      return displayName[0].toUpperCase();
    }
    return 'U';
  }

  factory UserModel.fromInput({required String emailOrUsername}) {
    String extractedName = emailOrUsername.split('@').first.split('.').first;
    if (extractedName.isNotEmpty) {
      extractedName = extractedName[0].toUpperCase() + extractedName.substring(1);
    } else {
      extractedName = 'User';
    }
    return UserModel(
      id: 1,
      name: extractedName,
      email: emailOrUsername.contains('@') ? emailOrUsername : '$emailOrUsername@example.com',
      role: 'User',
      tenantId: 1,
      studioName: '$extractedName Studio',
      emailVerifide: true,
      plan: 'PRO',
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 1,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'User',
      tenantId: json['tenant_id'] ?? json['tenantId'] ?? 1,
      studioName: json['studio_name'] ?? json['studioName'] ?? '',
      emailVerifide: json['email_verifide'] ?? json['emailVerified'] ?? false,
      plan: json['plan'] ?? 'PRO',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'tenant_id': tenantId,
      'studio_name': studioName,
      'email_verifide': emailVerifide,
      'plan': plan,
    };
  }
}
