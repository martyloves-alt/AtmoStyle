// Service de génération d'image — appel direct à l'API Gemini (modèle
// "Nano Banana"), sans SDK ni Firebase : un simple appel HTTP avec la clé.
//
// La clé n'est jamais dans le code source : elle est injectée au moment du
// build via --dart-define, à partir d'un secret GitHub Actions (voir
// ci.yml et les instructions de configuration).

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GeminiApiException implements Exception {
  final String message;
  GeminiApiException(this.message);
  @override
  String toString() => message;
}

class GeminiImageService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _model = 'gemini-2.5-flash-image';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<Uint8List> generateImage({
    required String prompt,
    required Uint8List referencePhotoBytes,
  }) async {
    if (!isConfigured) {
      throw GeminiApiException(
        'Clé API Gemini manquante : GEMINI_API_KEY doit être fournie au build.',
      );
    }

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Encode(referencePhotoBytes),
              },
            },
          ],
        },
      ],
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': _apiKey,
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw GeminiApiException('Gemini a répondu ${response.statusCode} : ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw GeminiApiException("Réponse Gemini sans candidat d'image.");
    }

    final parts = (candidates.first['content']?['parts'] as List?) ?? [];
    for (final part in parts) {
      final inlineData = part['inline_data'] ?? part['inlineData'];
      if (inlineData != null && inlineData['data'] != null) {
        return base64Decode(inlineData['data'] as String);
      }
    }

    throw GeminiApiException('Aucune image dans la réponse Gemini.');
  }
}
