// ignore_for_file: constant_identifier_names

enum SubscriptionPlan { FREE, PRO, PREMIUM }

extension SubscriptionPlanExt on SubscriptionPlan {
  int get level {
    switch (this) {
      case SubscriptionPlan.FREE: return 0;
      case SubscriptionPlan.PRO: return 1;
      case SubscriptionPlan.PREMIUM: return 2;
    }
  }

  bool canAccess(SubscriptionPlan requiredPlan) {
    return level >= requiredPlan.level;
  }
}
