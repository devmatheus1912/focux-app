import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/pt.dart';
import '../widgets/fx_grouped_action_sheet.dart';

/// Lado da foto salva. Maior avatar do app × 3 de densidade, com folga.
const fotoDePerfilLado = 1024;

class FotoDePerfil {
  const FotoDePerfil({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

/// Entrada única da foto de perfil: personal e aluno escolhem a origem e
/// recortam em círculo. Nulo quando a pessoa desiste em qualquer passo.
Future<FotoDePerfil?> escolherFotoDePerfil(BuildContext context) async {
  final origem = await showFxGroupedActionSheet<ImageSource>(
    context,
    titulo: ptS.fotoEscolherTitulo,
    grupos: [
      FxActionGroup<ImageSource>(null, [
        FxActionItem(
          valor: ImageSource.camera,
          rotulo: ptS.fotoCamera,
          icone: Icons.photo_camera_outlined,
        ),
        FxActionItem(
          valor: ImageSource.gallery,
          rotulo: ptS.fotoGaleria,
          icone: Icons.photo_library_outlined,
        ),
      ]),
    ],
  );
  if (origem == null) return null;

  final escolhida = await ImagePicker().pickImage(source: origem);
  if (escolhida == null) return null;

  final recortada = await ImageCropper().cropImage(
    sourcePath: escolhida.path,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    maxWidth: fotoDePerfilLado,
    maxHeight: fotoDePerfilLado,
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 90,
    uiSettings: [
      IOSUiSettings(
        title: ptS.fotoAjustar,
        doneButtonTitle: ptS.fotoConcluir,
        cancelButtonTitle: ptS.fotoCancelar,
        cropStyle: CropStyle.circle,
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
      ),
      AndroidUiSettings(
        toolbarTitle: ptS.fotoAjustar,
        cropStyle: CropStyle.circle,
        lockAspectRatio: true,
        initAspectRatio: CropAspectRatioPreset.square,
      ),
    ],
  );
  if (recortada == null) return null;
  return FotoDePerfil(
    bytes: await recortada.readAsBytes(),
    filename: 'perfil.jpg',
  );
}
