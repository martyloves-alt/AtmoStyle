// Service de génération d'image — Hugging Face Inference Providers,
// fournisseur fal-ai, tâche « image-text-to-image » (édition d'une photo
// à partir d'une consigne texte).
//
// Ce fichier n'est pas une reconstruction approximative : il reproduit le
// protocole du client officiel @huggingface/inference, lu ligne à ligne
// dans les sources ci-dessous. Chaque constante et chaque étape est
// rattachée à une source précise.
//
// SOURCES (lues le 2026-09-21, dépôts clonés et vérifiés) :
//
// 1. huggingface/huggingface.js — commit 0c7bdbab3dae4665d0270c65ad98ef6ce6ca4019
//    paquet @huggingface/inference v4.13.30
//    - packages/inference/src/providers/fal-ai.ts
//        · FalAITask.prepareHeaders        → en-têtes (l. 132-141)
//        · FalAiQueueTask.makeRoute        → `/<providerId>?_subdomain=queue` (l. 146-152)
//        · FalAiQueueTask.getResponseFromQueueApi → file d'attente (l. 153-214)
//        · FalAIImageToImageTask.preparePayloadAsync → corps JSON (l. 328-340)
//        · FalAIImageToImageTask.getResponse → { images: [{ url }] } (l. 342-372)
//        · dropEndpointSegmentOnDirectCalls → commentaire l. 220-231 : via le
//          routeur HF, le chemin d'URL EST l'identifiant fournisseur que le
//          routeur résout ; le réécrire donne « Model not supported by
//          provider fal-ai ». C'est la cause exacte des deux échecs 400.
//    - packages/inference/src/providers/providerHelper.ts
//        · makeBaseUrl → `https://router.huggingface.co/<provider>` (l. 109-111)
//        · makeUrl     → baseUrl + '/' + route (l. 126-132)
//    - VALIDATION DES RÉPONSES HTTP — la règle est `Response.ok` (vrai pour
//      tout code 200-299), jamais une égalité à 200 :
//        · envoi initial  → utils/request.ts l. 58   : `if (!response.ok)`
//        · statut         → fal-ai.ts     l. 187     : `if (!statusResponse.ok)`
//        · résultat       → fal-ai.ts     l. 207-213 : aucun contrôle du code,
//          seul l'échec de parsing JSON lève
//        · image finale   → fal-ai.ts     l. 363-364 : aucun contrôle du code
//      La file d'attente de fal répond 202 tant que la génération tourne ;
//      c'est exactement ce qu'un test `!= 200` prenait pour une erreur.
//      Divergence assumée : sur le résultat et l'image, ce fichier vérifie
//      la plage 200-299 alors que le client officiel ne vérifie rien — une
//      erreur silencieuse vaut moins qu'un message portant le code HTTP.
//    - packages/inference/src/config.ts → HF_ROUTER_URL (l. 2)
//    - packages/inference/src/lib/makeRequestOptions.ts → le `model` passé à
//      makeUrl est `inferenceProviderMapping.providerId`, pas l'identifiant
//      Hub (l. 93 et 145-148)
//    - packages/inference/test/fal-ai-url.spec.ts (l. 51-58) — test officiel
//      qui fige l'URL exacte reproduite ici :
//        providerId « fal-ai/flux-2/edit », authMethod « hf-token » →
//        https://router.huggingface.co/fal-ai/fal-ai/flux-2/edit?_subdomain=queue
//    - packages/tasks/src/tasks/image-text-to-image/data.ts (l. 39-50) →
//      black-forest-labs/FLUX.2-dev est le modèle recommandé de la tâche.
//
// 2. huggingface/hub-docs — commit 0249c808ba3cc2bcd95e2ecf35463007e45fb279
//    - docs/inference-providers/tasks/image-to-image.md → en-tête
//      d'authentification `Bearer hf_****` avec la permission
//      « Inference Providers ».
//
// POINT NON CONFIRMÉ, annoncé explicitement :
//    L'API Hub (huggingface.co/api/partners/fal-ai/models et
//    huggingface.co/api/models/...?expand[]=inferenceProviderMapping) est
//    bloquée par la politique réseau de l'environnement de build : le
//    mapping vivant « black-forest-labs/FLUX.2-dev → fal-ai/flux-2/edit »
//    n'a donc pas pu être relu en direct. Il reste que le routeur résout le
//    modèle À PARTIR DU CHEMIN D'URL (source 1, dropEndpointSegmentOnDirectCalls) :
//    l'identifiant Hub n'apparaît jamais dans la requête, seul
//    « fal-ai/flux-2/edit » compte, et c'est la valeur figée par le test
//    officiel. Si fal-ai retirait cet endpoint, l'erreur serait de nouveau
//    « Model not supported by provider fal-ai », remontée telle quelle
//    ci-dessous avec le code HTTP et le corps de la réponse.

import 'dart:async';
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

  /// Identifiant côté fal-ai (PAS l'identifiant Hub). Le routeur Hugging Face
  /// résout le modèle à partir de ce chemin — c'est précisément ce qui
  /// manquait aux deux tentatives précédentes.
  static const String _providerModelId = 'fal-ai/flux-2/edit';
  static const String _provider = 'fal-ai';
  static const String _routerUrl = 'https://router.huggingface.co';

  /// Délai global : l'écran ne doit jamais rester bloqué.
  static const Duration _globalTimeout = Duration(seconds: 120);

  /// Intervalle d'interrogation de la file d'attente (delay(500) côté client
  /// officiel, getResponseFromQueueApi).
  static const Duration _pollInterval = Duration(milliseconds: 500);

  /// Statuts terminaux d'échec de la file d'attente fal-ai. Le client
  /// officiel ne les énumère pas (il boucle jusqu'à COMPLETED) : sans cette
  /// coupure, un échec ne serait vu qu'au bout des 120 s.
  static const Set<String> _failureStatuses = {'ERROR', 'FAILED', 'CANCELLED'};

  /// https://router.huggingface.co/fal-ai/fal-ai/flux-2/edit?_subdomain=queue
  /// Le double segment est correct : base = routeur + fournisseur, route =
  /// identifiant fournisseur, qui commence lui-même par « fal-ai/ ».
  static final Uri _endpoint =
      Uri.parse('$_routerUrl/$_provider/$_providerModelId?_subdomain=queue');

  bool get isConfigured => _apiKey.isNotEmpty;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      };

  Future<Uint8List> generateImage({
    required String prompt,
    required Uint8List referencePhotoBytes,
  }) async {
    if (!isConfigured) {
      throw HuggingFaceApiException(
        'Jeton Hugging Face manquant : HF_TOKEN doit être fourni au build.',
      );
    }

    final deadline = DateTime.now().add(_globalTimeout);

    try {
      return await _generate(
        prompt: prompt,
        referencePhotoBytes: referencePhotoBytes,
        deadline: deadline,
      ).timeout(_globalTimeout);
    } on TimeoutException {
      throw HuggingFaceApiException(
        "Génération interrompue : délai de ${_globalTimeout.inSeconds} s dépassé.",
      );
    }
  }

  Future<Uint8List> _generate({
    required String prompt,
    required Uint8List referencePhotoBytes,
    required DateTime deadline,
  }) async {
    // Corps JSON — fal-ai.ts, FalAIImageToImageTask.preparePayloadAsync :
    // l'image part en data-URL base64, dupliquée sur `image_url` et
    // `image_urls`, le commentaire l. 337 précisant que les endpoints FLUX.2
    // attendent la forme tableau.
    final dataUrl =
        'data:${_mimeType(referencePhotoBytes)};base64,${base64Encode(referencePhotoBytes)}';

    final submitResponse = await http.post(
      _endpoint,
      headers: _headers,
      body: jsonEncode({
        'prompt': prompt,
        'image_url': dataUrl,
        'image_urls': [dataUrl],
      }),
    );

    if (!_isOk(submitResponse.statusCode)) {
      throw HuggingFaceApiException(
        'Hugging Face a refusé la demande (${submitResponse.statusCode}) : '
        '${_preview(submitResponse.body)}',
      );
    }

    final queue = _decodeJson(submitResponse, 'la mise en file d\'attente');

    final requestId = queue['request_id'];
    final responseUrl = queue['response_url'];
    if (requestId is! String || responseUrl is! String) {
      throw HuggingFaceApiException(
        "Réponse inattendue de Hugging Face : ni request_id ni response_url "
        "exploitables (${submitResponse.statusCode}) : ${_preview(submitResponse.body)}",
      );
    }

    // getResponseFromQueueApi : les URL de statut et de résultat sont
    // reconstruites à partir du chemin de `response_url`, qui peut différer
    // du modèle appelé, en repassant par le routeur.
    const base = '$_routerUrl/$_provider';
    final modelPath = Uri.parse(responseUrl).path;
    final statusUrl = Uri.parse('$base$modelPath/status?_subdomain=queue');
    final resultUrl = Uri.parse('$base$modelPath?_subdomain=queue');

    var status = queue['status'];

    while (status != 'COMPLETED') {
      if (DateTime.now().isAfter(deadline)) {
        throw HuggingFaceApiException(
          "Génération interrompue : délai de ${_globalTimeout.inSeconds} s "
          "dépassé (dernier statut : $status).",
        );
      }

      await Future<void>.delayed(_pollInterval);

      final statusResponse = await http.get(statusUrl, headers: _headers);
      if (!_isOk(statusResponse.statusCode)) {
        throw HuggingFaceApiException(
          'Suivi de la génération impossible (${statusResponse.statusCode}) : '
          '${_preview(statusResponse.body)}',
        );
      }

      final decoded = _decodeJson(statusResponse, 'le statut');
      status = decoded['status'];

      // Le client officiel boucle sur tout ce qui n'est pas COMPLETED
      // (fal-ai.ts l. 183) sans énumérer les statuts intermédiaires : une
      // liste d'autorisation ferait échouer à tort un statut inconnu mais
      // valide. On ne coupe donc que sur un échec explicite ; tout le reste
      // continue d'être interrogé, borné par le délai global.
      if (_failureStatuses.contains(status)) {
        throw HuggingFaceApiException(
          'Génération échouée côté fal-ai (statut « $status ») : '
          '${_preview(statusResponse.body)}',
        );
      }
    }

    final resultResponse = await http.get(resultUrl, headers: _headers);
    if (!_isOk(resultResponse.statusCode)) {
      throw HuggingFaceApiException(
        'Récupération du résultat impossible (${resultResponse.statusCode}) : '
        '${_preview(resultResponse.body)}',
      );
    }

    final result = _decodeJson(resultResponse, 'le résultat');

    // FalAIImageToImageTask.getResponse : { images: Array<{ url: string }> }
    final images = result['images'];
    if (images is! List || images.isEmpty) {
      throw HuggingFaceApiException(
        'Réponse Hugging Face sans image (${resultResponse.statusCode}) : '
        '${_preview(resultResponse.body)}',
      );
    }
    final first = images.first;
    final imageUrl = first is Map ? first['url'] : null;
    if (imageUrl is! String) {
      throw HuggingFaceApiException(
        "Réponse Hugging Face sans URL d'image (${resultResponse.statusCode}) : "
        '${_preview(resultResponse.body)}',
      );
    }

    final imageResponse = await http.get(Uri.parse(imageUrl));
    if (!_isOk(imageResponse.statusCode)) {
      throw HuggingFaceApiException(
        "Téléchargement de l'image généré impossible "
        '(${imageResponse.statusCode}) : ${_preview(imageResponse.body)}',
      );
    }
    return imageResponse.bodyBytes;
  }

  Map<String, dynamic> _decodeJson(http.Response response, String etape) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // On retombe sur l'erreur ci-dessous, corps brut inclus.
    }
    throw HuggingFaceApiException(
      'Réponse illisible de Hugging Face pour $etape '
      '(${response.statusCode}) : ${_preview(response.body)}',
    );
  }

  /// fal-ai décode la data-URL d'après le type MIME déclaré : il doit
  /// correspondre aux octets réellement envoyés.
  String _mimeType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    // PhotoService enregistre du JPEG : repli le plus sûr.
    return 'image/jpeg';
  }

  /// Règle du client officiel : la validation se fait sur `Response.ok`,
  /// vrai pour tout code 200-299 — pas sur l'égalité à 200. C'est ce qui
  /// manquait : la file d'attente de fal répond 202 tant que la génération
  /// est en cours, et un test `!= 200` le prenait pour une erreur.
  bool _isOk(int statusCode) => statusCode >= 200 && statusCode < 300;

  String _preview(String body) =>
      body.substring(0, body.length.clamp(0, 300));
}
