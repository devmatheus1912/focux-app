// ignore_for_file: constant_identifier_names

enum SubscriptionPlan { FREE, PRO, ENTERPRISE }

SubscriptionPlan subscriptionPlanFromApi(String? value) {
  final raw = (value ?? '').trim().toUpperCase().replaceAll(' ', '_');
  switch (raw) {
    case 'ENTERPRISE_PRO':
    case 'ENTERPRISEPRO':
    case 'ENTERPRISE':
      return SubscriptionPlan.ENTERPRISE;
    case 'PREMIUM':
    case 'PRO':
      return SubscriptionPlan.PRO;
    default:
      return SubscriptionPlan.FREE;
  }
}

extension SubscriptionPlanExt on SubscriptionPlan {
  int get level {
    switch (this) {
      case SubscriptionPlan.FREE:
        return 0;
      case SubscriptionPlan.PRO:
        return 1;
      case SubscriptionPlan.ENTERPRISE:
        return 2;
    }
  }

  String get apiName => name.toUpperCase();

  bool canAccess(SubscriptionPlan requiredPlan) {
    return level >= requiredPlan.level;
  }
}
