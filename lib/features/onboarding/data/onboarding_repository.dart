import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import 'onboarding_status_data.dart';

class OnboardingStep {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool completed;
  final String actionRoute;
  final int estimatedMinutes;

  OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.completed,
    required this.actionRoute,
    required this.estimatedMinutes,
  });

  factory OnboardingStep.fromJson(Map<String, dynamic> j) => OnboardingStep(
    id: j['id'] as String? ?? '',
    title: j['title'] as String? ?? '',
    description: j['description'] as String? ?? '',
    icon: j['icon'] as String? ?? 'check',
    completed: j['completed'] as bool? ?? false,
    actionRoute: j['actionRoute'] as String? ?? '/dashboard/personal',
    estimatedMinutes: (j['estimatedMinutes'] as num?)?.toInt() ?? 2,
  );
}

class OnboardingWizard {
  final List<OnboardingStep> steps;
  final int completedCount;
  final int totalCount;
  final int progressPercent;
  final String nextActionLabel;
  final String nextActionRoute;
  final bool wizardCompleto;
  final bool allStepsDone;

  OnboardingWizard({
    required this.steps,
    required this.completedCount,
    required this.totalCount,
    required this.progressPercent,
    required this.nextActionLabel,
    required this.nextActionRoute,
    required this.wizardCompleto,
    required this.allStepsDone,
  });

  factory OnboardingWizard.fromJson(Map<String, dynamic> j) => OnboardingWizard(
    steps:
        (j['steps'] as List<dynamic>? ?? [])
            .map((e) => OnboardingStep.fromJson(e as Map<String, dynamic>))
            .toList(),
    completedCount: (j['completedCount'] as num?)?.toInt() ?? 0,
    totalCount: (j['totalCount'] as num?)?.toInt() ?? 0,
    progressPercent: (j['progressPercent'] as num?)?.toInt() ?? 0,
    nextActionLabel: j['nextActionLabel'] as String? ?? '',
    nextActionRoute: j['nextActionRoute'] as String? ?? '/dashboard/personal',
    wizardCompleto: j['wizardCompleto'] as bool? ?? false,
    allStepsDone: j['allStepsDone'] as bool? ?? false,
  );

  int get remainingMinutes => steps
      .where((step) => !step.completed)
      .fold(0, (sum, step) => sum + step.estimatedMinutes);
}

class OnboardingRepository {
  final Dio _dio;
  OnboardingRepository(ApiClient c) : _dio = c.dio;

  Future<OnboardingStatusData> getStatus() async {
    final r = await _dio.get('/api/onboarding/status');
    return OnboardingStatusData.fromJson(r.data as Map<String, dynamic>);
  }

  Future<OnboardingWizard> wizard() async {
    final r = await _dio.get('/api/onboarding/wizard');
    return OnboardingWizard.fromJson(r.data as Map<String, dynamic>);
  }

  Future<OnboardingWizard> marcarCompleto() async {
    final r = await _dio.post('/api/onboarding/wizard/completo');
    return OnboardingWizard.fromJson(r.data as Map<String, dynamic>);
  }
}
