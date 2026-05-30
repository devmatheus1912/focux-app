// ignore_for_file: constant_identifier_names

enum SubscriptionPlan { FREE, PREMIUM, ENTERPRISE, ENTERPRISE_PRO }

SubscriptionPlan subscriptionPlanFromApi(String? value) {
  final raw = (value ?? '').trim().toUpperCase().replaceAll(' ', '_');
  switch (raw) {
    case 'ENTERPRISE_PRO':
    case 'ENTERPRISEPRO':
      return SubscriptionPlan.ENTERPRISE_PRO;
    case 'ENTERPRISE':
      return SubscriptionPlan.ENTERPRISE;
    case 'PREMIUM':
    case 'PRO':
      return SubscriptionPlan.PREMIUM;
    default:
      return SubscriptionPlan.FREE;
  }
}

extension SubscriptionPlanExt on SubscriptionPlan {
  int get level {
    switch (this) {
      case SubscriptionPlan.FREE:
        return 0;
      case SubscriptionPlan.PREMIUM:
        return 1;
      case SubscriptionPlan.ENTERPRISE:
        return 2;
      case SubscriptionPlan.ENTERPRISE_PRO:
        return 3;
    }
  }

  String get apiName => name.toUpperCase();

  bool canAccess(SubscriptionPlan requiredPlan) {
    return level >= requiredPlan.level;
  }
}
