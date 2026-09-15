class SubscriptionPlanModel {
  final dynamic id;
  final String name;
  final String slug;
  final int? maxEvents;
  final int? storageBytes;
  final String? storageLabel;
  final bool ftpSftpEnabled;
  final bool teamMembersEnabled;
  final int maxTeamMembers;
  final num? priceInr;
  final String? formattedPrice;
  final String? tagline;
  final List<String> features;
  final bool isPopular;

  const SubscriptionPlanModel({
    this.id,
    required this.name,
    required this.slug,
    this.maxEvents,
    this.storageBytes,
    this.storageLabel,
    this.ftpSftpEnabled = false,
    this.teamMembersEnabled = false,
    this.maxTeamMembers = 0,
    this.priceInr,
    this.formattedPrice,
    this.tagline,
    this.features = const [],
    this.isPopular = false,
  });

  bool get isUnlimitedEvents => maxEvents == null;

  String get resolvedTagline {
    if (tagline != null && tagline!.isNotEmpty) return tagline!;
    switch (slug.toLowerCase()) {
      case 'starter':
        return 'Best for: solo photographers';
      case 'professional':
      case 'pro':
        return 'Best for: growing studios';
      case 'studio':
        return 'Best for: camera-to-cloud studio';
      case 'enterprise':
        return 'Best for: large scale agencies';
      default:
        return 'Best for: photography studios';
    }
  }

  String get resolvedPriceFormatted {
    if (formattedPrice != null && formattedPrice!.isNotEmpty) {
      return formattedPrice!.endsWith('/mo') ? formattedPrice! : '$formattedPrice/mo';
    }
    if (priceInr != null) {
      final formattedNum = priceInr!.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
      return '₹$formattedNum/mo';
    }
    return 'Free';
  }

  List<String> get resolvedFeatures {
    if (features.isNotEmpty) return features;
    final list = <String>[];
    if (maxEvents == null) {
      list.add('Unlimited events');
    } else {
      list.add('Up to $maxEvents events');
    }

    if (storageLabel != null && storageLabel!.isNotEmpty) {
      list.add('$storageLabel storage');
    }

    if (ftpSftpEnabled) {
      list.add('FTP/SFTP camera uploads');
    }

    if (teamMembersEnabled && maxTeamMembers > 0) {
      list.add('Up to $maxTeamMembers team members');
    }

    if (slug.toLowerCase() == 'starter') {
      list.add('Email support');
    } else {
      list.add('Priority support');
    }

    return list;
  }

  static const List<SubscriptionPlanModel> defaultPlans = [
    SubscriptionPlanModel(
      id: 1,
      name: 'Starter',
      slug: 'starter',
      priceInr: 899,
      formattedPrice: '₹899/mo',
      tagline: 'Best for: solo photographers',
      storageLabel: '100 GB',
      storageBytes: 107374182400,
      maxEvents: null,
      ftpSftpEnabled: false,
      teamMembersEnabled: false,
      maxTeamMembers: 0,
      features: [
        'Unlimited events',
        '100 GB storage',
        'Email support',
      ],
    ),
    SubscriptionPlanModel(
      id: 2,
      name: 'Professional',
      slug: 'professional',
      priceInr: 1499,
      formattedPrice: '₹1,499/mo',
      tagline: 'Best for: growing studios',
      storageLabel: '500 GB',
      storageBytes: 536870912000,
      maxEvents: null,
      ftpSftpEnabled: false,
      teamMembersEnabled: true,
      maxTeamMembers: 3,
      isPopular: true,
      features: [
        'Unlimited events',
        '500 GB storage',
        'Up to 3 team members',
        'Priority support',
      ],
    ),
    SubscriptionPlanModel(
      id: 3,
      name: 'Studio',
      slug: 'studio',
      priceInr: 2099,
      formattedPrice: '₹2,099/mo',
      tagline: 'Best for: camera-to-cloud studio',
      storageLabel: '1 TB',
      storageBytes: 1099511627776,
      maxEvents: null,
      ftpSftpEnabled: true,
      teamMembersEnabled: true,
      maxTeamMembers: 10,
      features: [
        'Unlimited events',
        '1TB storage',
        'FTP/SFTP camera uploads',
        'Up to 10 team members',
        'Priority support',
      ],
    ),
  ];

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedFeatures = [];
    if (json['features'] is List) {
      parsedFeatures = (json['features'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return SubscriptionPlanModel(
      id: json['id'],
      name: json['name'] as String? ?? 'Free Plan',
      slug: json['slug'] as String? ?? 'free',
      maxEvents: json['max_events'] as int?,
      storageBytes: json['storage_bytes'] is int
          ? json['storage_bytes'] as int
          : (json['storage_bytes'] is num ? (json['storage_bytes'] as num).toInt() : null),
      storageLabel: json['storage_label'] as String?,
      ftpSftpEnabled: json['ftp_sftp_enabled'] as bool? ?? false,
      teamMembersEnabled: json['team_members_enabled'] as bool? ?? false,
      maxTeamMembers: json['max_team_members'] as int? ?? 0,
      priceInr: json['price_inr'] as num?,
      formattedPrice: json['formatted_price'] as String?,
      tagline: json['tagline'] as String? ?? json['description'] as String?,
      features: parsedFeatures,
      isPopular: json['is_popular'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'max_events': maxEvents,
      'storage_bytes': storageBytes,
      'storage_label': storageLabel,
      'ftp_sftp_enabled': ftpSftpEnabled,
      'team_members_enabled': teamMembersEnabled,
      'max_team_members': maxTeamMembers,
      'price_inr': priceInr,
      'formatted_price': formattedPrice,
      'tagline': tagline,
      'features': features,
      'is_popular': isPopular,
    };
  }
}

class SubscriptionUsageModel {
  final int storageUsedBytes;
  final int storageLimitBytes;
  final String storageUsedFormatted;
  final double storagePercent;
  final int eventCount;
  final bool canCreateEvent;

  const SubscriptionUsageModel({
    this.storageUsedBytes = 0,
    this.storageLimitBytes = 0,
    this.storageUsedFormatted = '0 B',
    this.storagePercent = 0.0,
    this.eventCount = 0,
    this.canCreateEvent = true,
  });

  factory SubscriptionUsageModel.fromJson(Map<String, dynamic> json) {
    num percentNum = 0.0;
    if (json['storage_percent'] is num) {
      percentNum = json['storage_percent'] as num;
    }

    return SubscriptionUsageModel(
      storageUsedBytes: json['storage_used_bytes'] as int? ?? 0,
      storageLimitBytes: json['storage_limit_bytes'] as int? ?? 0,
      storageUsedFormatted: json['storage_used_formatted'] as String? ?? '0 B',
      storagePercent: percentNum.toDouble(),
      eventCount: json['event_count'] as int? ?? 0,
      canCreateEvent: json['can_create_event'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storage_used_bytes': storageUsedBytes,
      'storage_limit_bytes': storageLimitBytes,
      'storage_used_formatted': storageUsedFormatted,
      'storage_percent': storagePercent,
      'event_count': eventCount,
      'can_create_event': canCreateEvent,
    };
  }
}

class SubscriptionModel {
  final String status;
  final bool isActive;
  final bool isTrialing;
  final bool isExpired;
  final bool isExpiringSoon;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? trialEndsAt;
  final DateTime? cancelledAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final SubscriptionPlanModel? plan;
  final SubscriptionUsageModel? usage;
  final List<SubscriptionPlanModel> availablePlans;

  const SubscriptionModel({
    this.status = 'none',
    this.isActive = false,
    this.isTrialing = false,
    this.isExpired = false,
    this.isExpiringSoon = false,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.trialEndsAt,
    this.cancelledAt,
    this.startDate,
    this.endDate,
    this.plan,
    this.usage,
    this.availablePlans = const [],
  });

  bool get isStorageWarning => (usage?.storagePercent ?? 0.0) >= 80.0;
  bool get isStorageCritical => (usage?.storagePercent ?? 0.0) >= 95.0;
  bool get isStorageExceeded => (usage?.storagePercent ?? 0.0) >= 100.0;
  bool get canCreateEvent => usage?.canCreateEvent ?? true;

  bool isCurrentPlan(SubscriptionPlanModel p) {
    if (plan == null) return false;
    if (p.slug.isNotEmpty && plan!.slug.isNotEmpty) {
      return p.slug.toLowerCase() == plan!.slug.toLowerCase();
    }
    return p.name.toLowerCase() == plan!.name.toLowerCase();
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'active':
        return 'ACTIVE';
      case 'trialing':
        return 'TRIALING';
      case 'expired':
        return 'EXPIRED';
      case 'cancelled':
        return 'CANCELLED';
      case 'none':
      default:
        return 'NO PLAN';
    }
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> data = json;
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      data = json['data'] as Map<String, dynamic>;
    }

    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    List<SubscriptionPlanModel> parsedPlans = [];
    if (data['plans'] is List && (data['plans'] as List).isNotEmpty) {
      parsedPlans = (data['plans'] as List)
          .whereType<Map<String, dynamic>>()
          .map((p) => SubscriptionPlanModel.fromJson(p))
          .toList();
    } else if (data['available_plans'] is List && (data['available_plans'] as List).isNotEmpty) {
      parsedPlans = (data['available_plans'] as List)
          .whereType<Map<String, dynamic>>()
          .map((p) => SubscriptionPlanModel.fromJson(p))
          .toList();
    } else if (data['all_plans'] is List && (data['all_plans'] as List).isNotEmpty) {
      parsedPlans = (data['all_plans'] as List)
          .whereType<Map<String, dynamic>>()
          .map((p) => SubscriptionPlanModel.fromJson(p))
          .toList();
    } else if (json['plans'] is List && (json['plans'] as List).isNotEmpty) {
      parsedPlans = (json['plans'] as List)
          .whereType<Map<String, dynamic>>()
          .map((p) => SubscriptionPlanModel.fromJson(p))
          .toList();
    } else {
      parsedPlans = List<SubscriptionPlanModel>.from(SubscriptionPlanModel.defaultPlans);
    }

    return SubscriptionModel(
      status: data['status'] as String? ?? 'none',
      isActive: data['is_active'] as bool? ?? false,
      isTrialing: data['is_trialing'] as bool? ?? false,
      isExpired: data['is_expired'] as bool? ?? false,
      isExpiringSoon: data['is_expiring_soon'] as bool? ?? false,
      currentPeriodStart: parseDate(data['current_period_start']),
      currentPeriodEnd: parseDate(data['current_period_end']),
      trialEndsAt: parseDate(data['trial_ends_at']),
      cancelledAt: parseDate(data['cancelled_at']),
      startDate: parseDate(data['start_date']),
      endDate: parseDate(data['end_date']),
      plan: data['plan'] is Map<String, dynamic>
          ? SubscriptionPlanModel.fromJson(data['plan'] as Map<String, dynamic>)
          : null,
      usage: data['usage'] is Map<String, dynamic>
          ? SubscriptionUsageModel.fromJson(data['usage'] as Map<String, dynamic>)
          : null,
      availablePlans: parsedPlans,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'is_active': isActive,
      'is_trialing': isTrialing,
      'is_expired': isExpired,
      'is_expiring_soon': isExpiringSoon,
      'current_period_start': currentPeriodStart?.toIso8601String(),
      'current_period_end': currentPeriodEnd?.toIso8601String(),
      'trial_ends_at': trialEndsAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'plan': plan?.toJson(),
      'usage': usage?.toJson(),
      'available_plans': availablePlans.map((p) => p.toJson()).toList(),
    };
  }
}
