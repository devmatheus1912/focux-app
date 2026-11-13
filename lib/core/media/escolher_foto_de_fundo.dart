import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/pt.dart';
import '../theme/fx_icons.dart';
import '../widgets/fx_grouped_action_sheet.dart';

/// Foto de fundo do cartão de story (9:16), recortada no aparelho. Não sobe
/// para o servidor: é a imagem do aluno e só vai para onde ele compartilhar.
/// Nulo quando a pessoa desiste em qualquer passo.
Future<Uint8List?> escolherFotoDeFundo(BuildContext context) async {
  final origem = await showFxGroupedActionSheet<ImageSource>(
    context,
    titulo: ptS.fotoEscolherTitulo,
    grupos: [
      FxActionGroup<ImageSource>(null, [
        FxActionItem(
          valor: ImageSource.camera,
          rotulo: ptS.fotoCamera,
          icone: FxIcons.camera,
        ),
        FxActionItem(
          valor: ImageSource.gallery,
          rotulo: ptS.fotoGaleria,
          icone: FxIcons.galeria,
        ),
      ]),
    ],
  );
  if (origem == null) return null;

  final escolhida = await ImagePicker().pickImage(source: origem);
  if (escolhida == null) return null;

  final recortada = await ImageCropper().cropImage(
    sourcePath: escolhida.path,
    aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
    maxWidth: 1080,
    maxHeight: 1920,
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 90,
    uiSettings: [
      IOSUiSettings(
        title: ptS.fotoAjustar,
        doneButtonTitle: ptS.fotoConcluir,
        cancelButtonTitle: ptS.fotoCancelar,
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
      ),
      AndroidUiSettings(
        toolbarTitle: ptS.fotoAjustar,
        lockAspectRatio: true,
      ),
    ],
  );
  if (recortada == null) return null;
  return recortada.readAsBytes();
}
