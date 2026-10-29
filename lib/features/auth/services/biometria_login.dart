import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Nome que o aparelho dá à biometria, para o rótulo do botão.
enum BiometriaTipo {
  faceId('Face ID'),
  touchId('Touch ID'),
  digital('digital'),
  generica('biometria');

  const BiometriaTipo(this.rotulo);
  final String rotulo;
}

/// Credencial guardada para o login por biometria.
class CredencialBiometria {
  const CredencialBiometria({
    required this.email,
    required this.senha,
    required this.aluno,
    this.personalSlug,
  });

  final String email;
  final String senha;
  final bool aluno;
  final String? personalSlug;
}

/// O que a biometria pergunta ao sistema (trocado por um falso nos testes).
abstract class BiometriaSistema {
  Future<BiometriaTipo?> tipoDisponivel();
  Future<bool> autenticar(String motivo);
}

/// Onde a credencial fica (Keychain/Keystore; falso na memória nos testes).
abstract class BiometriaCofre {
  Future<CredencialBiometria?> ler();
  Future<void> gravar(CredencialBiometria credencial);
  Future<void> apagar();
}

class BiometriaSistemaLocalAuth implements BiometriaSistema {
  BiometriaSistemaLocalAuth([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<BiometriaTipo?> tipoDisponivel() async {
    if (kIsWeb) return null;
    try {
      if (!await _auth.isDeviceSupported()) return null;
      final tipos = await _auth.getAvailableBiometrics();
      if (tipos.isEmpty) return null;
      if (tipos.contains(BiometricType.face)) return BiometriaTipo.faceId;
      if (tipos.contains(BiometricType.fingerprint)) {
        return Platform.isIOS ? BiometriaTipo.touchId : BiometriaTipo.digital;
      }
      return BiometriaTipo.generica;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> autenticar(String motivo) async {
    try {
      return await _auth.authenticate(
        localizedReason: motivo,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}

class BiometriaCofreSeguro implements BiometriaCofre {
  const BiometriaCofreSeguro();

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const _kEmail = 'bio_email';
  static const _kSenha = 'bio_senha';
  static const _kAluno = 'bio_aluno';
  static const _kSlug = 'bio_slug';

  @override
  Future<CredencialBiometria?> ler() async {
    final email = await _storage.read(key: _kEmail);
    final senha = await _storage.read(key: _kSenha);
    if (email == null || senha == null) return null;
    final slug = await _storage.read(key: _kSlug);
    return CredencialBiometria(
      email: email,
      senha: senha,
      aluno: await _storage.read(key: _kAluno) == 'true',
      personalSlug: slug == null || slug.isEmpty ? null : slug,
    );
  }

  @override
  Future<void> gravar(CredencialBiometria c) async {
    await _storage.write(key: _kEmail, value: c.email);
    await _storage.write(key: _kSenha, value: c.senha);
    await _storage.write(key: _kAluno, value: c.aluno.toString());
    await _storage.write(key: _kSlug, value: c.personalSlug ?? '');
  }

  @override
  Future<void> apagar() async {
    for (final k in [_kEmail, _kSenha, _kAluno, _kSlug]) {
      await _storage.delete(key: k);
    }
  }
}

/// Login por Face ID/biometria: opcional, só neste aparelho, e a credencial só
/// é lida depois de a biometria confirmar. Sai ao desativar ou quando a senha
/// deixa de valer.
class BiometriaLogin {
  BiometriaLogin({
    BiometriaSistema? sistema,
    BiometriaCofre? cofre,
    DateTime Function()? agora,
  }) : _sistema = sistema ?? BiometriaSistemaLocalAuth(),
       _cofre = cofre ?? const BiometriaCofreSeguro(),
       _agora = agora ?? DateTime.now;

  final BiometriaSistema _sistema;
  final BiometriaCofre _cofre;
  final DateTime Function() _agora;

  static const _kAtiva = 'biometria_login_ativa';
  static const _kSilencioAte = 'biometria_login_silencio_ate';
  static const silencio = Duration(days: 30);

  Future<BiometriaTipo?> tipo() => _sistema.tipoDisponivel();

  Future<bool> ativa() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAtiva) ?? false;
  }

  /// Botão do login: ativa neste aparelho e com biometria cadastrada.
  Future<BiometriaTipo?> tipoParaEntrar() async {
    if (!await ativa()) return null;
    return tipo();
  }

  /// Oferece ativar? Só com biometria disponível, ainda desligada e fora do
  /// período de "agora não".
  Future<BiometriaTipo?> tipoParaOferecer() async {
    if (await ativa()) return null;
    final prefs = await SharedPreferences.getInstance();
    final ate = prefs.getInt(_kSilencioAte);
    if (ate != null && _agora().millisecondsSinceEpoch < ate) return null;
    return tipo();
  }

  Future<void> adiarOferta() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _kSilencioAte,
      _agora().add(silencio).millisecondsSinceEpoch,
    );
  }

  /// Confirma a biometria e só então guarda a credencial.
  Future<bool> ativar(CredencialBiometria credencial, String motivo) async {
    if (!await _sistema.autenticar(motivo)) return false;
    await _cofre.gravar(credencial);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAtiva, true);
    return true;
  }

  /// Login bem-sucedido com a senha: mantém a credencial em dia (senha nova).
  Future<void> atualizarSeAtiva(CredencialBiometria credencial) async {
    if (await ativa()) await _cofre.gravar(credencial);
  }

  /// `null` se cancelou, falhou ou não há credencial.
  Future<CredencialBiometria?> entrar(String motivo) async {
    if (!await ativa()) return null;
    if (!await _sistema.autenticar(motivo)) return null;
    return _cofre.ler();
  }

  Future<void> desativar() async {
    await _cofre.apagar();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAtiva);
  }
}

final biometriaLoginProvider = Provider<BiometriaLogin>(
  (ref) => BiometriaLogin(),
);
