import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';

class PersonalBrand {
  final String nomePersonal;
  final String? slogan;
  final String? logoUrl;
  final String? corPrimaria;
  final String? corSecundaria;
  final String? descricaoProfissional;
  final String? instagram;
  final String plano;
  final String? appDisplayName;
  final bool hideFocuxBranding;
  final bool whiteLabelActive;
  final String? customDomain;
  final bool customDomainVerified;
  final String? publicLandingUrl;
  final String? capturaUrl;

  PersonalBrand({
    required this.nomePersonal,
    this.slogan,
    this.logoUrl,
    this.corPrimaria,
    this.corSecundaria,
    this.descricaoProfissional,
    this.instagram,
    required this.plano,
    this.appDisplayName,
    this.hideFocuxBranding = false,
    this.whiteLabelActive = false,
    this.customDomain,
    this.customDomainVerified = false,
    this.publicLandingUrl,
    this.capturaUrl,
  });

  factory PersonalBrand.fromJson(Map<String, dynamic> j) => PersonalBrand(
    nomePersonal: j['nomePersonal'] as String? ?? '',
    slogan: j['slogan'] as String?,
    logoUrl: j['logoUrl'] as String?,
    corPrimaria: j['corPrimaria'] as String?,
    corSecundaria: j['corSecundaria'] as String?,
    descricaoProfissional: j['descricaoProfissional'] as String?,
    instagram: j['instagram'] as String?,
    plano: j['plano'] as String? ?? 'FREE',
    appDisplayName: j['appDisplayName'] as String?,
    hideFocuxBranding: j['hideFocuxBranding'] as bool? ?? false,
    whiteLabelActive: j['whiteLabelActive'] as bool? ?? false,
    customDomain: j['customDomain'] as String?,
    customDomainVerified: j['customDomainVerified'] as bool? ?? false,
    publicLandingUrl: j['publicLandingUrl'] as String?,
    capturaUrl: j['capturaUrl'] as String?,
  );

  bool get isEnterprise => plano == 'ENTERPRISE';
}

final personalBrandProvider = FutureProvider.autoDispose<PersonalBrand>((
  ref,
) async {
  final dio = ref.read(apiClientProvider).dio;
  final r = await dio.get('/api/aluno/personal-brand');
  return PersonalBrand.fromJson(r.data as Map<String, dynamic>);
});
