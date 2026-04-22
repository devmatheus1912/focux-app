import 'package:flutter/foundation.dart';
import '../models/subscription_plan.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionPlan _currentPlan = SubscriptionPlan.FREE;

  SubscriptionPlan get currentPlan => _currentPlan;

  void upgradePlan(SubscriptionPlan newPlan) {
    _currentPlan = newPlan;
    notifyListeners();
  }
}
