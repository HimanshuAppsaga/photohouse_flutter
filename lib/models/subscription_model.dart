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
  });

  bool get isUnlimitedEvents => maxEvents == null;

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
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
  });

  bool get isStorageWarning => (usage?.storagePercent ?? 0.0) >= 80.0;
  bool get isStorageCritical => (usage?.storagePercent ?? 0.0) >= 95.0;
  bool get isStorageExceeded => (usage?.storagePercent ?? 0.0) >= 100.0;
  bool get canCreateEvent => usage?.canCreateEvent ?? true;

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
    };
  }
}
