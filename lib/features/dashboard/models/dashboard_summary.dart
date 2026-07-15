class DashboardSummary {
  final int totalProperties;
  final int available;
  final int sold;
  final int rented;
  final int requirements;
  final int users;

  const DashboardSummary({
    required this.totalProperties,
    required this.available,
    required this.sold,
    required this.rented,
    required this.requirements,
    required this.users,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalProperties: json['totalProperties'] ?? 0,
      available: json['available'] ?? 0,
      sold: json['sold'] ?? 0,
      rented: json['rented'] ?? 0,
      requirements: json['requirements'] ?? 0,
      users: json['users'] ?? 0,
    );
  }
}

class RecentActivity {
  final String id;
  final String module;
  final String action;
  final String description;
  final String timestamp;
  final String user;

  const RecentActivity({
    required this.id,
    required this.module,
    required this.action,
    required this.description,
    required this.timestamp,
    required this.user,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'] ?? '',
      module: json['module'] ?? '',
      action: json['action'] ?? '',
      description: json['description'] ?? '',
      timestamp: json['timestamp'] ?? '',
      user: json['user'] ?? 'System',
    );
  }
}

class RecentProperty {
  final String code;
  final String title;
  final String area;
  final double price;
  final String status;
  final String areaName;
  final String createdBy;
  final String createdAt;

  const RecentProperty({
    required this.code,
    required this.title,
    required this.area,
    required this.price,
    required this.status,
    required this.areaName,
    required this.createdBy,
    required this.createdAt,
  });

  factory RecentProperty.fromJson(Map<String, dynamic> json) {
    return RecentProperty(
      code: json['code'] ?? '',
      title: json['title'] ?? '',
      area: json['area'] ?? 'N/A',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'N/A',
      areaName: json['areaName'] ?? 'N/A',
      createdBy: json['createdBy'] ?? 'System',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class DashboardData {
  final DashboardSummary summary;
  final List<RecentActivity> activity;
  final List<RecentProperty> recentProperties;
  final List<ChecklistItem> checklist;
  final List<DashboardFollowup> followups;

  const DashboardData({
    required this.summary,
    required this.activity,
    required this.recentProperties,
    required this.checklist,
    required this.followups,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      summary: DashboardSummary.fromJson(json['summary'] ?? {}),
      activity: (json['activity'] as List?)
              ?.map((item) => RecentActivity.fromJson(item))
              .toList() ??
          [],
      recentProperties: (json['recentProperties'] as List?)
              ?.map((item) => RecentProperty.fromJson(item))
              .toList() ??
          [],
      checklist: (json['checklist'] as List?)
              ?.map((item) => ChecklistItem.fromJson(item))
              .toList() ??
          [],
      followups: (json['followups'] as List?)
              ?.map((item) => DashboardFollowup.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class ChecklistItem {
  final String id;
  final String title;
  final bool isCompleted;
  final String dueDate;

  const ChecklistItem({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.dueDate,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      dueDate: json['due_date'] ?? '',
    );
  }
}

class DashboardFollowup {
  final String id;
  final String clientName;
  final String mobile;
  final String followupDate;
  final String? notes;
  final String status;
  final String? propertyCode;
  final String? propertyTitle;
  final String? requirementCustomerName;

  const DashboardFollowup({
    required this.id,
    required this.clientName,
    required this.mobile,
    required this.followupDate,
    this.notes,
    required this.status,
    this.propertyCode,
    this.propertyTitle,
    this.requirementCustomerName,
  });

  factory DashboardFollowup.fromJson(Map<String, dynamic> json) {
    final property = json['property'] as Map<String, dynamic>?;
    final requirement = json['requirement'] as Map<String, dynamic>?;
    return DashboardFollowup(
      id: json['id'] ?? '',
      clientName: json['client_name'] ?? '',
      mobile: json['mobile'] ?? '',
      followupDate: json['followup_date'] ?? '',
      notes: json['notes'],
      status: json['status'] ?? 'Pending',
      propertyCode: property?['property_code'],
      propertyTitle: property?['title'],
      requirementCustomerName: requirement?['customer_name'],
    );
  }
}
