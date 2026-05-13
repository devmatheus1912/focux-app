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

  PersonalBrand({
    required this.nomePersonal,
    this.slogan,
    this.logoUrl,
    this.corPrimaria,
    this.corSecundaria,
    this.descricaoProfissional,
    this.instagram,
    required this.plano,
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
