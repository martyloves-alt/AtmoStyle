// Service de génération d'image — Hugging Face Inference Providers,
// palier gratuit (100 000 crédits/mois, aucune carte requise).
//
// ATTENTION, transparence : le format exact de cette requête est ma
// meilleure construction à partir de la documentation disponible, pas une
// certitude vérifiée. Le premier essai réel sert de test. Si la réponse ne
// correspond à aucun des deux formats gérés ci-dessous, l'erreur renvoyée
// inclut le corps brut de la réponse pour qu'on puisse corriger précisément.

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class HuggingFaceApiException implements Exception {
  final String message;
  HuggingFaceApiException(this.message);
  @override
  String toString() => message;
}

class HuggingFaceImageService {
  static const String _apiKey = String.fromEnvironment('HF_TOKEN');
  static const String _model = 'black-forest-labs/FLUX.2-dev';
  static const String _provider = 'fal-ai';
  static final Uri _endpoint =
      Uri.parse('https://router.huggingface.co/$_provider/$_model');

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<Uint8List> generateImage({
    required String prompt,
    required Uint8List referencePhotoBytes,
  }) async {
    if (!isConfigured) {
      throw HuggingFaceApiException(
        'Jeton Hugging Face manquant : HF_TOKEN doit être fourni au build.',
      );
    }

    final request = http.MultipartRequest('POST', _endpoint)
      ..headers['Authorization'] = 'Bearer $_apiKey'
      ..fields['prompt'] = prompt
      ..files.add(http.MultipartFile.fromBytes(
        'image',
        referencePhotoBytes,
        filename: 'reference.jpg',
      ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw HuggingFaceApiException(
        'Hugging Face a répondu ${response.statusCode} : ${response.body}',
      );
    }

    final contentType = response.headers['content-type'] ?? '';
    if (contentType.startsWith('image/')) {
      return response.bodyBytes;
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final imageUrl = decoded['image']?['url'] ?? decoded['images']?[0]?['url'];
      if (imageUrl is String) {
        final imageResponse = await http.get(Uri.parse(imageUrl));
        return imageResponse.bodyBytes;
      }
    } catch (_) {
      // Pas du JSON exploitable : on tombe sur l'erreur ci-dessous.
    }

    final preview = response.body.substring(0, response.body.length.clamp(0, 300));
    throw HuggingFaceApiException(
      'Réponse Hugging Face dans un format inattendu (${response.statusCode}) : $preview',
    );
  }
}
