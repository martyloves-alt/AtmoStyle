// Service de photo de référence — capture/sélection et stockage local.
//
// La photo ne quitte le téléphone que lors d'un appel explicite à l'API
// Gemini (voir gemini_image_service.dart) : elle n'est envoyée à aucun
// autre serveur, et n'est stockée que localement sur l'appareil.

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class PhotoService {
  static const String _fileName = 'reference_photo.jpg';

  Future<File> get _referenceFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<File?> getReferencePhoto() async {
    final file = await _referenceFile;
    return await file.exists() ? file : null;
  }

  Future<File?> pickAndSaveReferencePhoto({required ImageSource source}) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final destination = await _referenceFile;
    final bytes = await picked.readAsBytes();
    await destination.writeAsBytes(bytes);
    return destination;
  }
}
