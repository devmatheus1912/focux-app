import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/perfil/providers/perfil_provider.dart';
import '../../features/perfil/data/white_label_repository.dart';
import '../../features/planos/providers/plano_features_provider.dart';
import 'focux_pdf_kit.dart';

/// Baixa o logo do personal para o PDF. Sem rede ou URL ruim: sem logo, e o
/// documento sai igual (nunca falha por causa da marca).
Future<pw.MemoryImage?> baixarLogoParaPdf(String? url, {Dio? dio}) async {
  final endereco = (url ?? '').trim();
  if (!endereco.toLowerCase().startsWith('http')) return null;
  try {
    final cliente = dio ?? Dio();
    final r = await cliente.get<List<int>>(
      endereco,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 6),
        sendTimeout: const Duration(seconds: 6),
      ),
    );
    final bytes = r.data;
    if (bytes == null || bytes.isEmpty) return null;
    return pw.MemoryImage(Uint8List.fromList(bytes));
  } catch (_) {
    return null;
  }
}

/// Marca dos PDFs do personal: com white-label no plano, o documento leva o
/// nome, a cor, o slogan e o logo dele; sem plano, segue a marca Focux.
Future<FocuxPdfBrand> carregarMarcaDoPdf(WidgetRef ref) async {
  try {
    final perfil = await ref.read(perfilProvider.future);
    final recursos = ref.read(planoFeaturesProvider).value;
    if (recursos?.whiteLabel != true) return FocuxPdfBrand.focux();
    WhiteLabelConfig? config;
    try {
      config = await ref.read(whiteLabelConfigProvider.future);
    } catch (_) {
      config = null;
    }
    final nomeApp = (config?.appDisplayName ?? '').trim();
    return FocuxPdfBrand.doPersonal(
      nome: nomeApp.isNotEmpty ? nomeApp : perfil.nome,
      corHex: perfil.corPrimaria,
      slogan: perfil.slogan,
      logo: await baixarLogoParaPdf(perfil.logoUrl),
      ocultarFocux: config?.ocultarMarcaFocux ?? false,
    );
  } catch (_) {
    return FocuxPdfBrand.focux();
  }
}
