// AtmoStyle — Contrat JSON du moteur déterministe.
//
// Ce fichier ne contient AUCUNE règle de décision : uniquement les
// structures de données échangées entre l'écran de questions, le moteur
// déterministe (prochaine étape) et l'appel à l'API Gemini pour l'image.
//
// fromJson/toJson sont écrits à la main, volontairement : pas de
// json_serializable ni de freezed, donc pas d'étape build_runner requise.
// Ça reste buildable tel quel par GitHub Actions, sans build local.
//
// ─────────────────────────────────────────────────────────────────────────
// Exemple concret :
//
// ENTRÉE (EngineInput)
// {
//   "textile": "wax",
//   "context": "dinerPrive",
//   "accessory": "montreAutomatique",
//   "fragrance": "boiseIntense",
//   "weather": { "temperatureCelsius": 24.0, "condition": "pluvieux" },
//   "targetDay": "aujourdHui"
// }
//
// SORTIE (EngineOutput) — calculée par le moteur, pas par ce fichier
// {
//   "weatherHeadline": "Aujourd'hui : 24°C, Averses",
//   "outfitSummary": "Veste croisée européenne, touches de Wax, bottines imperméables.",
//   "garmentPieces": ["Veste croisée européenne", "Chemise en Wax", "Bottines imperméables"],
//   "accessoryNote": "Montre à mouvement automatique bien visible au poignet.",
//   "fragranceNote": "Sillage boisé, intensité modérée.",
//   "imageGenerationPrompt": "...",
//   "notification": { "title": "...", "body": "...", "hour": 20, "minute": 0 }
// }
// ─────────────────────────────────────────────────────────────────────────

/// Désérialise une String JSON vers une valeur d'enum, avec un message
/// d'erreur clair si la valeur est inconnue ou absente. Utilisé par tous
/// les enums ci-dessous pour éviter cinq copies du même code.
T enumFromJson<T extends Enum>(List<T> values, Object? value, String enumName) {
  if (value is! String) {
    throw FormatException('$enumName : chaîne attendue, reçu "$value"');
  }
  return values.firstWhere(
    (e) => e.name == value,
    orElse: () => throw FormatException('$enumName : valeur inconnue "$value"'),
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// ─────────────────────────────────────────────────────────────────────────
// Préférences utilisateur — les 4 questions éclair de l'écran de démarrage.
// ─────────────────────────────────────────────────────────────────────────

/// Tissu de base préféré.
enum TextilePreference { bazin, wax, classique }

/// Contexte de la journée — influence surtout le niveau de formalité.
enum DayContext { visitePatients, formationMagistrale, dinerPrive }

/// Accessoire mis en avant.
enum AccessoryPreference { montreAutomatique, poignetDegage, braceletDiscret }

/// Signature olfactive suggérée.
enum FragranceSignature { propreSavonneux, fraicheurNeutre, boiseIntense }

// ─────────────────────────────────────────────────────────────────────────
// Météo
// ─────────────────────────────────────────────────────────────────────────

/// Catégories météo adaptées au climat du Bénin / Afrique de l'Ouest.
/// Volontairement plus fines qu'un simple "ensoleillé / pluvieux" : l'harmattan
/// (vent sec et poussiéreux de saison sèche, environ novembre–mars) et la
/// chaleur humide tropicale changent vraiment le choix des tissus, ce qu'un
/// enum météo générique de type occidental ne capturerait pas.
enum WeatherCondition { ensoleille, nuageux, pluvieux, orageux, harmattan, chaudHumide }

/// Jour ciblé par la recommandation. Ne change pas la logique du moteur,
/// seulement le texte affiché ("Aujourd'hui" vs "Demain") — utile pour la
/// notification du soir qui parle de la météo du lendemain.
enum TargetDay { aujourdHui, demain }

/// Relevé météo pour le jour ciblé. Entièrement fourni par l'appelant : le
/// moteur ne fait aucun appel réseau lui-même.
class WeatherSnapshot {
  final double temperatureCelsius;
  final WeatherCondition condition;

  const WeatherSnapshot({
    required this.temperatureCelsius,
    required this.condition,
  });

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) {
    final temp = json['temperatureCelsius'];
    if (temp is! num) {
      throw FormatException('temperatureCelsius : nombre attendu, reçu "$temp"');
    }
    return WeatherSnapshot(
      temperatureCelsius: temp.toDouble(),
      condition: enumFromJson(WeatherCondition.values, json['condition'], 'WeatherCondition'),
    );
  }

  Map<String, dynamic> toJson() => {
        'temperatureCelsius': temperatureCelsius,
        'condition': condition.name,
      };

  @override
  bool operator ==(Object other) =>
      other is WeatherSnapshot &&
      other.temperatureCelsius == temperatureCelsius &&
      other.condition == condition;

  @override
  int get hashCode => Object.hash(temperatureCelsius, condition);

  @override
  String toString() => 'WeatherSnapshot($temperatureCelsius°C, ${condition.name})';

// ─────────────────────────────────────────────────────────────────────────
// Entrée du moteur
// ─────────────────────────────────────────────────────────────────────────

/// Tout ce dont le moteur a besoin pour produire une recommandation.
/// Aucun champ optionnel : l'appelant (UI ou tâche de fond) résout les
/// valeurs par défaut avant d'appeler le moteur, pour que le moteur reste
/// une fonction pure et totalement prévisible.
class EngineInput {
  final TextilePreference textile;
  final DayContext context;
  final AccessoryPreference accessory;
  final FragranceSignature fragrance;
  final WeatherSnapshot weather;
  final TargetDay targetDay;

  const EngineInput({
    required this.textile,
    required this.context,
    required this.accessory,
    required this.fragrance,
    required this.weather,
    required this.targetDay,
  });

  factory EngineInput.fromJson(Map<String, dynamic> json) {
    final weatherJson = json['weather'];
    if (weatherJson is! Map<String, dynamic>) {
      throw FormatException('weather : objet attendu, reçu "$weatherJson"');
    }
    return EngineInput(
      textile: enumFromJson(TextilePreference.values, json['textile'], 'TextilePreference'),
      context: enumFromJson(DayContext.values, json['context'], 'DayContext'),
      accessory: enumFromJson(AccessoryPreference.values, json['accessory'], 'AccessoryPreference'),
      fragrance: enumFromJson(FragranceSignature.values, json['fragrance'], 'FragranceSignature'),
      weather: WeatherSnapshot.fromJson(weatherJson),
      targetDay: enumFromJson(TargetDay.values, json['targetDay'], 'TargetDay'),
    );
  }

  Map<String, dynamic> toJson() => {
        'textile': textile.name,
        'context': context.name,
        'accessory': accessory.name,
        'fragrance': fragrance.name,
        'weather': weather.toJson(),
        'targetDay': targetDay.name,
      };

  @override
  bool operator ==(Object other) =>
      other is EngineInput &&
      other.textile == textile &&
      other.context == context &&
      other.accessory == accessory &&
      other.fragrance == fragrance &&
      other.weather == weather &&
      other.targetDay == targetDay;

  @override
  int get hashCode => Object.hash(textile, context, accessory, fragrance, weather, targetDay);
}

// ─────────────────────────────────────────────────────────────────────────
// Sortie du moteur
// ─────────────────────────────────────────────────────────────────────────

/// Paramètres de la notification proactive du soir (Réglages : "Alertes de
/// la veille", 20h00 par défaut dans la maquette). L'heure est un champ du
/// contrat — pas une constante cachée dans le moteur — pour rester réglable
/// plus tard depuis l'écran Réglages sans toucher au moteur.
class NotificationPayload {
  final String title;
  final String body;
  final int hour;
  final int minute;

  const NotificationPayload({
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      title: json['title'] as String,
      body: json['body'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'hour': hour,
        'minute': minute,
      };

  @override
  bool operator ==(Object other) =>
      other is NotificationPayload &&
      other.title == title &&
      other.body == body &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(title, body, hour, minute);
}

/// Sortie complète et déterministe du moteur pour un [EngineInput] donné.
/// Pour les mêmes entrées, ces valeurs doivent être strictement identiques
/// à chaque appel — aucun `DateTime.now()`, `Random()`, ni appel réseau ici.
class EngineOutput {
  /// Ligne d'en-tête météo affichée en haut du Lookbook,
  /// ex : "Aujourd'hui : 24°C, Averses"
  final String weatherHeadline;

  /// Description courte de la tenue,
  /// ex : "Veste croisée européenne, touches de Wax, bottines imperméables."
  final String outfitSummary;

  /// Détail pièce par pièce, dans l'ordre d'habillage.
  final List<String> garmentPieces;

  final String accessoryNote;
  final String fragranceNote;

  /// Prompt complet, prêt à envoyer tel quel à l'API Gemini pour générer
  /// l'image hyperréaliste du look.
  final String imageGenerationPrompt;

  final NotificationPayload notification;

  const EngineOutput({
    required this.weatherHeadline,
    required this.outfitSummary,
    required this.garmentPieces,
    required this.accessoryNote,
    required this.fragranceNote,
    required this.imageGenerationPrompt,
    required this.notification,
  });

  factory EngineOutput.fromJson(Map<String, dynamic> json) {
    return EngineOutput(
      weatherHeadline: json['weatherHeadline'] as String,
      outfitSummary: json['outfitSummary'] as String,
      garmentPieces: List<String>.from(json['garmentPieces'] as List),
      accessoryNote: json['accessoryNote'] as String,
      fragranceNote: json['fragranceNote'] as String,
      imageGenerationPrompt: json['imageGenerationPrompt'] as String,
      notification: NotificationPayload.fromJson(json['notification'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'weatherHeadline': weatherHeadline,
        'outfitSummary': outfitSummary,
        'garmentPieces': garmentPieces,
        'accessoryNote': accessoryNote,
        'fragranceNote': fragranceNote,
        'imageGenerationPrompt': imageGenerationPrompt,
        'notification': notification.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      other is EngineOutput &&
      other.weatherHeadline == weatherHeadline &&
      other.outfitSummary == outfitSummary &&
      _listEquals(other.garmentPieces, garmentPieces) &&
      other.accessoryNote == accessoryNote &&
      other.fragranceNote == fragranceNote &&
      other.imageGenerationPrompt == imageGenerationPrompt &&
      other.notification == notification;

  @override
  int get hashCode => Object.hash(
        weatherHeadline,
        outfitSummary,
        Object.hashAll(garmentPieces),
        accessoryNote,
        fragranceNote,
        imageGenerationPrompt,
        notification,
      );

  @override
  String toString() => 'EngineOutput(outfitSummary: $outfitSummary)';
}
