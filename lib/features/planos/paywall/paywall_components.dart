import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/legal/focux_legal.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../assinatura/data/plano.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/plan_entitlements.dart';
import '../../subscription/store_subscription_policy.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../../subscription/subscription_products.dart';
import '../../../core/widgets/fx_glass_surface.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import 'paywall_catalog.dart';
import 'paywall_glass.dart';

export 'paywall_glass.dart';
export 'paywall_plan_studio.dart';
export 'paywall_compare_stage.dart';

part 'paywall_subscriber_ui.part.dart';
part 'paywall_usage_and_strips.part.dart';
part 'paywall_plan_cards.part.dart';
part 'paywall_plan_cards_studio.part.dart';
part 'paywall_plan_cards_enterprise.part.dart';
part 'paywall_plan_cards_intro.part.dart';
part 'paywall_plan_cards_collapsible.part.dart';
part 'paywall_roi_legal.part.dart';
