// ignore_for_file: constant_identifier_names

enum SubscriptionPlan { FREE, PREMIUM, ENTERPRISE }

SubscriptionPlan subscriptionPlanFromApi(String? value) {
  switch ((value ?? '').trim().toUpperCase()) {
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
    }
  }

  String get apiName => name.toUpperCase();

  bool canAccess(SubscriptionPlan requiredPlan) {
    return level >= requiredPlan.level;
  }
}
