// AtmoStyle — Moteur déterministe.
//
// Un seul point d'entrée : AtmoStyleEngine.generate(EngineInput) -> EngineOutput.
// Fonction pure : mêmes entrées => toujours la même sortie, aucun appel
// réseau, aucune horloge, aucun aléatoire. C'est ce qui rend le moteur
// testable à 100 % (prochaine étape) et donc sans surprise en production.
//
// Le moteur ne connaît ni Flutter ni Gemini ni les notifications système :
// il transforme des données en d'autres données, selon le contrat défini
// dans atmostyle_contract.dart. L'appel météo réel, l'appel Gemini réel et
// la programmation réelle de la notification sont la responsabilité de
// couches au-dessus, à construire dans une étape ultérieure.

import '../models/atmostyle_contract.dart';

class AtmoStyleEngine {
  AtmoStyleEngine._(); // classe utilitaire : aucune instance nécessaire

  static const double _seuilChaudCelsius = 30.0;
  static const int _heureNotificationParDefaut = 20;
  static const int _minuteNotificationParDefaut = 0;

  /// Point d'entrée unique du moteur.
  static EngineOutput generate(EngineInput input) {
    final jacket = _buildJacket(input);
    final top = _buildTop(input);
    final bottom = _buildBottom(input);
    final footwear = _buildFootwear(input);

    final garmentPieces = _buildGarmentPieces(
      jacket: jacket,
      top: top,
      bottom: bottom,
      footwear: footwear,
    );

    final outfitSummary = _buildOutfitSummary(
      jacket: jacket,
      top: top,
      footwear: footwear,
      textile: input.textile,
    );

    final accessoryNote = _buildAccessoryNote(input);
    final fragranceNote = _buildFragranceNote(input);
    final weatherHeadline = _buildWeatherHeadline(input);

    final imagePrompt = _buildImagePrompt(
      input: input,
      garments: garmentPieces,
      accessoryNote: accessoryNote,
    );

    final notification = _buildNotification(
      input: input,
      outfitSummary: outfitSummary,
    );

    return EngineOutput(
      weatherHeadline: weatherHeadline,
      outfitSummary: outfitSummary,
      garmentPieces: garmentPieces,
      accessoryNote: accessoryNote,
      fragranceNote: fragranceNote,
      imageGenerationPrompt: imagePrompt,
      notification: notification,
    );
  }

  static bool _isHot(WeatherSnapshot weather) {
    return weather.condition == WeatherCondition.chaudHumide ||
        weather.temperatureCelsius >= _seuilChaudCelsius;
  }

  static bool _isRainy(WeatherSnapshot weather) {
    return weather.condition == WeatherCondition.pluvieux ||
        weather.condition == WeatherCondition.orageux;
  }

  static bool _isHarmattan(WeatherSnapshot weather) {
    return weather.condition == WeatherCondition.harmattan;
  }

  static String? _buildJacket(EngineInput input) {
    final rainy = _isRainy(input.weather);
    final harmattan = _isHarmattan(input.weather);

    switch (input.context) {
      case DayContext.dinerPrive:
        if (rainy) return 'veste croisée européenne imperméabilisée';
        if (harmattan) return 'veste croisée européenne, col fermé contre la poussière';
        return 'veste croisée européenne';

      case DayContext.formationMagistrale:
        if (rainy) return 'blazer structuré à traitement déperlant';
        if (harmattan) return 'blazer structuré, col fermé contre la poussière';
        return 'blazer structuré';

      case DayContext.visitePatients:
        if (_isHot(input.weather)) return null;
        if (rainy) return 'blouson léger imperméable';
        if (harmattan) return 'blouson léger, col fermé contre la poussière';
        return null;
    }
  }

  static String _buildTop(EngineInput input) {
    switch (input.textile) {
      case TextilePreference.bazin:
        return 'chemise Bazin brodée';
      case TextilePreference.wax:
        return 'chemise en Wax';
      case TextilePreference.classique:
        return 'chemise oxford classique';
    }
  }

  static String _buildBottom(EngineInput input) {
    final hot = _isHot(input.weather);
    switch (input.textile) {
      case TextilePreference.bazin:
        return hot ? 'pantalon Bazin léger' : 'pantalon Bazin';
      case TextilePreference.wax:
        return hot ? 'pantalon en lin à motifs Wax' : 'pantalon assorti Wax';
      case TextilePreference.classique:
        return hot ? 'pantalon chino léger' : 'pantalon classique';
    }
  }

  static String _buildFootwear(EngineInput input) {
    switch (input.weather.condition) {
      case WeatherCondition.pluvieux:
      case WeatherCondition.orageux:
        return 'bottines imperméables';
      case WeatherCondition.harmattan:
        return 'mocassins fermés, protection anti-poussière';
      case WeatherCondition.chaudHumide:
        return 'mocassins en cuir perforé, respirants';
      case WeatherCondition.ensoleille:
      case WeatherCondition.nuageux:
        return input.context == DayContext.dinerPrive
            ? 'derbies en cuir'
            : 'mocassins en cuir';
    }
  }

  static List<String> _buildGarmentPieces({
    required String? jacket,
    required String top,
    required String bottom,
    required String footwear,
  }) {
    final raw = <String>[
      if (jacket != null) jacket,
      top,
      bottom,
      footwear,
    ];
    return raw.map(_capitalize).toList();
  }

  static String _buildOutfitSummary({
    required String? jacket,
    required String top,
    required String footwear,
    required TextilePreference textile,
  }) {
    final textileLabel = _textileDisplayLabel(textile);
    final summary = jacket != null
        ? '$jacket, touches de $textileLabel, $footwear.'
        : '$top, $footwear.';
    return _capitalize(summary);
  }

  static String _textileDisplayLabel(TextilePreference textile) {
    switch (textile) {
      case TextilePreference.bazin:
        return 'Bazin';
      case TextilePreference.wax:
        return 'Wax';
      case TextilePreference.classique:
        return 'coupe classique';
    }
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static String _buildAccessoryNote(EngineInput input) {
    switch (input.accessory) {
      case AccessoryPreference.montreAutomatique:
        return 'Montre à mouvement automatique bien visible au poignet.';
      case AccessoryPreference.poignetDegage:
        return 'Poignet dégagé, sans montre : manches légèrement remontées.';
      case AccessoryPreference.braceletDiscret:
        return 'Bracelet discret en complément, sans surcharger le poignet.';
    }
  }

  static String _buildFragranceNote(EngineInput input) {
    final hot = _isHot(input.weather);
    switch (input.fragrance) {
      case FragranceSignature.propreSavonneux:
        return hot
            ? 'Notes propres et savonneuses, application légère vu la chaleur.'
            : 'Notes propres et savonneuses.';
      case FragranceSignature.fraicheurNeutre:
        return hot
            ? 'Fraîcheur neutre, idéale pour tenir sous la chaleur humide.'
            : 'Fraîcheur neutre, sillage discret.';
      case FragranceSignature.boiseIntense:
        return hot
            ? 'Boisé intense, à appliquer avec parcimonie par cette chaleur.'
            : 'Sillage boisé, intensité modérée.';
    }
  }

  static String _buildWeatherHeadline(EngineInput input) {
    final dayLabel = input.targetDay == TargetDay.aujourdHui ? "Aujourd'hui" : 'Demain';
    final tempLabel = '${input.weather.temperatureCelsius.round()}°C';
    final conditionLabel = _weatherConditionLabel(input.weather.condition);
    return '$dayLabel : $tempLabel, $conditionLabel';
  }

  static String _weatherConditionLabel(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.ensoleille:
        return 'Ensoleillé';
      case WeatherCondition.nuageux:
        return 'Nuageux';
      case WeatherCondition.pluvieux:
        return 'Averses';
      case WeatherCondition.orageux:
        return 'Orages';
      case WeatherCondition.harmattan:
        return 'Harmattan';
      case WeatherCondition.chaudHumide:
        return 'Chaleur humide';
    }
  }

  static String _buildImagePrompt({
    required EngineInput input,
    required List<String> garments,
    required String accessoryNote,
  }) {
    final garmentsText = garments.join(', ');
    final conditionText = _weatherConditionLabel(input.weather.condition).toLowerCase();
    final contextText = _contextDisplayLabel(input.context);

    return 'Photo hyperréaliste, style éditorial mode, plein cadre, lumière naturelle. '
        'Un homme élégant porte : $garmentsText. $accessoryNote '
        'Ambiance : $contextText, météo ${input.weather.temperatureCelsius.round()}°C, $conditionText. '
        'Fusion vestimentaire entre élégance européenne et tissus ouest-africains, '
        'coupe soignée, tissu net et texturé, rendu photographique net et contrasté, '
        'sans texte ni logo visible.';
  }

  static String _contextDisplayLabel(DayContext context) {
    switch (context) {
      case DayContext.visitePatients:
        return 'visite de patients en clinique';
      case DayContext.formationMagistrale:
        return 'formation magistrale devant un auditoire';
      case DayContext.dinerPrive:
        return 'dîner privé en soirée';
    }
  }

  static NotificationPayload _buildNotification({
    required EngineInput input,
    required String outfitSummary,
  }) {
    final dayLabel = input.targetDay == TargetDay.aujourdHui ? "d'aujourd'hui" : 'de demain';
    return NotificationPayload(
      title: 'Ta tenue $dayLabel',
      body: outfitSummary,
      hour: _heureNotificationParDefaut,
      minute: _minuteNotificationParDefaut,
    );
  }
}
