import 'package:flutter_test/flutter_test.dart';
import 'package:atmostyle/models/atmostyle_contract.dart';
import 'package:atmostyle/engine/atmostyle_engine.dart';

EngineInput _input({
  TextilePreference textile = TextilePreference.classique,
  DayContext context = DayContext.formationMagistrale,
  AccessoryPreference accessory = AccessoryPreference.montreAutomatique,
  FragranceSignature fragrance = FragranceSignature.fraicheurNeutre,
  double temperatureCelsius = 24,
  WeatherCondition condition = WeatherCondition.ensoleille,
  TargetDay targetDay = TargetDay.aujourdHui,
}) {
  return EngineInput(
    textile: textile,
    context: context,
    accessory: accessory,
    fragrance: fragrance,
    weather: WeatherSnapshot(
      temperatureCelsius: temperatureCelsius,
      condition: condition,
    ),
    targetDay: targetDay,
  );
}

void main() {
  group('Déterminisme', () {
    test('même entrée -> même sortie', () {
      final input = _input(textile: TextilePreference.wax, context: DayContext.dinerPrive);
      final out1 = AtmoStyleEngine.generate(input);
      final out2 = AtmoStyleEngine.generate(input);
      expect(out1, equals(out2));
    });
  });

  group('Tissu -> haut et bas', () {
    test('Bazin', () {
      final output = AtmoStyleEngine.generate(_input(textile: TextilePreference.bazin));
      expect(output.garmentPieces, contains('Chemise Bazin brodée'));
      expect(output.garmentPieces, contains('Pantalon Bazin'));
    });

    test('Wax', () {
      final output = AtmoStyleEngine.generate(_input(textile: TextilePreference.wax));
      expect(output.garmentPieces, contains('Chemise en Wax'));
      expect(output.garmentPieces, contains('Pantalon assorti Wax'));
    });

    test('Classique', () {
      final output = AtmoStyleEngine.generate(_input(textile: TextilePreference.classique));
      expect(output.garmentPieces, contains('Chemise oxford classique'));
      expect(output.garmentPieces, contains('Pantalon classique'));
    });
  });

  group('Contexte -> veste', () {
    test('dîner privé porte une veste croisée', () {
      final output = AtmoStyleEngine.generate(_input(context: DayContext.dinerPrive));
      expect(output.garmentPieces, contains('Veste croisée européenne'));
    });

    test('formation magistrale porte un blazer', () {
      final output = AtmoStyleEngine.generate(_input(context: DayContext.formationMagistrale));
      expect(output.garmentPieces, contains('Blazer structuré'));
    });

    test('visite de patients par temps neutre : pas de veste', () {
      final output = AtmoStyleEngine.generate(_input(
        context: DayContext.visitePatients,
        condition: WeatherCondition.ensoleille,
        temperatureCelsius: 24,
      ));
      expect(output.garmentPieces.length, 3);
    });
  });

  group('Météo -> chaussures', () {
    test('pluvieux -> bottines imperméables', () {
      final output = AtmoStyleEngine.generate(_input(condition: WeatherCondition.pluvieux));
      expect(output.garmentPieces, contains('Bottines imperméables'));
    });

    test('orageux -> bottines imperméables', () {
      final output = AtmoStyleEngine.generate(_input(condition: WeatherCondition.orageux));
      expect(output.garmentPieces, contains('Bottines imperméables'));
    });

    test('harmattan -> mocassins fermés anti-poussière', () {
      final output = AtmoStyleEngine.generate(_input(condition: WeatherCondition.harmattan));
      expect(output.garmentPieces, contains('Mocassins fermés, protection anti-poussière'));
    });

    test('chaud et humide -> mocassins perforés respirants', () {
      final output = AtmoStyleEngine.generate(_input(condition: WeatherCondition.chaudHumide));
      expect(output.garmentPieces, contains('Mocassins en cuir perforé, respirants'));
    });

    test('ensoleillé en dîner privé -> derbies', () {
      final output = AtmoStyleEngine.generate(_input(
        condition: WeatherCondition.ensoleille,
        context: DayContext.dinerPrive,
      ));
      expect(output.garmentPieces, contains('Derbies en cuir'));
    });

    test('ensoleillé hors dîner privé -> mocassins', () {
      final output = AtmoStyleEngine.generate(_input(
        condition: WeatherCondition.ensoleille,
        context: DayContext.formationMagistrale,
      ));
      expect(output.garmentPieces, contains('Mocassins en cuir'));
    });
  });

  group('Pluie -> veste imperméabilisée', () {
    test('dîner privé', () {
      final output = AtmoStyleEngine.generate(_input(
        context: DayContext.dinerPrive,
        condition: WeatherCondition.pluvieux,
      ));
      expect(output.garmentPieces, contains('Veste croisée européenne imperméabilisée'));
    });

    test('formation magistrale', () {
      final output = AtmoStyleEngine.generate(_input(
        context: DayContext.formationMagistrale,
        condition: WeatherCondition.orageux,
      ));
      expect(output.garmentPieces, contains('Blazer structuré à traitement déperlant'));
    });

    test('visite de patients par temps pluvieux et non chaud', () {
      final output = AtmoStyleEngine.generate(_input(
        context: DayContext.visitePatients,
        condition: WeatherCondition.pluvieux,
        temperatureCelsius: 22,
      ));
      expect(output.garmentPieces, contains('Blouson léger imperméable'));
    });
  });

  group('Harmattan -> col fermé contre la poussière', () {
    test('dîner privé', () {
      final output = AtmoStyleEngine.generate(_input(
        context: DayContext.dinerPrive,
        condition: WeatherCondition.harmattan,
        temperatureCelsius: 22,
      ));
      expect(output.garmentPieces, contains('Veste croisée européenne, col fermé contre la poussière'));
    });

    test('formation magistrale', () {
      final output = AtmoStyleEngine.generate(_input(
        context: DayContext.formationMagistrale,
        condition: WeatherCondition.harmattan,
        temperatureCelsius: 22,
      ));
      expect(output.garmentPieces, contains('Blazer structuré, col fermé contre la poussière'));
    });

    test('visite de patients', () {
      final output = AtmoStyleEngine.generate(_input(
        context: DayContext.visitePatients,
        condition: WeatherCondition.harmattan,
        temperatureCelsius: 22,
      ));
      expect(output.garmentPieces, contains('Blouson léger, col fermé contre la poussière'));
    });
  });

  group('Forte chaleur en visite de patients : pas de veste', () {
    test('même par temps de pluie, la chaleur prime', () {
      final output = AtmoStyleEngine.generate(_input(
        context: DayContext.visitePatients,
        condition: WeatherCondition.pluvieux,
        temperatureCelsius: 32,
      ));
      expect(output.garmentPieces.length, 3);
    });

    test('même par harmattan, la chaleur prime', () {
      final output = AtmoStyleEngine.generate(_input(
        context: DayContext.visitePatients,
        condition: WeatherCondition.harmattan,
        temperatureCelsius: 32,
      ));
      expect(output.garmentPieces.length, 3);
    });
  });

  group('Seuil de chaleur (30°C)', () {
    test('30.0°C exactement déclenche le mode chaud', () {
      final output = AtmoStyleEngine.generate(_input(
        textile: TextilePreference.classique,
        temperatureCelsius: 30.0,
        condition: WeatherCondition.ensoleille,
      ));
      expect(output.garmentPieces, contains('Pantalon chino léger'));
    });

    test('29.9°C reste en mode normal', () {
      final output = AtmoStyleEngine.generate(_input(
        textile: TextilePreference.classique,
        temperatureCelsius: 29.9,
        condition: WeatherCondition.ensoleille,
      ));
      expect(output.garmentPieces, contains('Pantalon classique'));
    });
  });

  group('Chaleur -> bas allégé', () {
    test('Bazin', () {
      final output = AtmoStyleEngine.generate(_input(textile: TextilePreference.bazin, temperatureCelsius: 33));
      expect(output.garmentPieces, contains('Pantalon Bazin léger'));
    });

    test('Wax', () {
      final output = AtmoStyleEngine.generate(_input(textile: TextilePreference.wax, temperatureCelsius: 33));
      expect(output.garmentPieces, contains('Pantalon en lin à motifs Wax'));
    });

    test('Classique', () {
      final output = AtmoStyleEngine.generate(_input(textile: TextilePreference.classique, temperatureCelsius: 33));
      expect(output.garmentPieces, contains('Pantalon chino léger'));
    });
  });

  group('Accessoire -> note', () {
    test('montre automatique', () {
      final output = AtmoStyleEngine.generate(_input(accessory: AccessoryPreference.montreAutomatique));
      expect(output.accessoryNote, 'Montre à mouvement automatique bien visible au poignet.');
    });

    test('poignet dégagé', () {
      final output = AtmoStyleEngine.generate(_input(accessory: AccessoryPreference.poignetDegage));
      expect(output.accessoryNote, 'Poignet dégagé, sans montre : manches légèrement remontées.');
    });

    test('bracelet discret', () {
      final output = AtmoStyleEngine.generate(_input(accessory: AccessoryPreference.braceletDiscret));
      expect(output.accessoryNote, 'Bracelet discret en complément, sans surcharger le poignet.');
    });
  });

  group('Parfum -> note, ajustée si forte chaleur', () {
    test('propre/savonneux, temps normal', () {
      final output = AtmoStyleEngine.generate(
        _input(fragrance: FragranceSignature.propreSavonneux, temperatureCelsius: 24),
      );
      expect(output.fragranceNote, 'Notes propres et savonneuses.');
    });

    test('propre/savonneux, forte chaleur', () {
      final output = AtmoStyleEngine.generate(
        _input(fragrance: FragranceSignature.propreSavonneux, temperatureCelsius: 33),
      );
      expect(output.fragranceNote, 'Notes propres et savonneuses, application légère vu la chaleur.');
    });

    test('fraîcheur neutre, temps normal', () {
      final output = AtmoStyleEngine.generate(
        _input(fragrance: FragranceSignature.fraicheurNeutre, temperatureCelsius: 24),
      );
      expect(output.fragranceNote, 'Fraîcheur neutre, sillage discret.');
    });

    test('fraîcheur neutre, forte chaleur', () {
      final output = AtmoStyleEngine.generate(
        _input(fragrance: FragranceSignature.fraicheurNeutre, temperatureCelsius: 33),
      );
      expect(output.fragranceNote, 'Fraîcheur neutre, idéale pour tenir sous la chaleur humide.');
    });

    test('boisé intense, temps normal', () {
      final output = AtmoStyleEngine.generate(
        _input(fragrance: FragranceSignature.boiseIntense, temperatureCelsius: 24),
      );
      expect(output.fragranceNote, 'Sillage boisé, intensité modérée.');
    });

    test('boisé intense, forte chaleur', () {
      final output = AtmoStyleEngine.generate(
        _input(fragrance: FragranceSignature.boiseIntense, temperatureCelsius: 33),
      );
      expect(output.fragranceNote, 'Boisé intense, à appliquer avec parcimonie par cette chaleur.');
    });
  });

  group('En-tête météo', () {
    test("aujourd'hui", () {
      final output = AtmoStyleEngine.generate(
        _input(targetDay: TargetDay.aujourdHui, temperatureCelsius: 24, condition: WeatherCondition.pluvieux),
      );
      expect(output.weatherHeadline, "Aujourd'hui : 24°C, Averses");
    });

    test('demain', () {
      final output = AtmoStyleEngine.generate(
        _input(targetDay: TargetDay.demain, temperatureCelsius: 24, condition: WeatherCondition.pluvieux),
      );
      expect(output.weatherHeadline, 'Demain : 24°C, Averses');
    });

    test('la température est arrondie', () {
      final output = AtmoStyleEngine.generate(
        _input(temperatureCelsius: 24.6, condition: WeatherCondition.ensoleille),
      );
      expect(output.weatherHeadline, contains('25°C'));
    });
  });

  group('Notification', () {
    test("titre pour aujourd'hui", () {
      final output = AtmoStyleEngine.generate(_input(targetDay: TargetDay.aujourdHui));
      expect(output.notification.title, "Ta tenue d'aujourd'hui");
    });

    test('titre pour demain', () {
      final output = AtmoStyleEngine.generate(_input(targetDay: TargetDay.demain));
      expect(output.notification.title, 'Ta tenue de demain');
    });

    test('heure par défaut : 20h00', () {
      final output = AtmoStyleEngine.generate(_input());
      expect(output.notification.hour, 20);
      expect(output.notification.minute, 0);
    });

    test('le corps reprend le résumé de la tenue', () {
      final output = AtmoStyleEngine.generate(_input());
      expect(output.notification.body, output.outfitSummary);
    });
  });

  group('Résumé de la tenue', () {
    test('avec veste : "veste, touches de tissu, chaussures."', () {
      final output = AtmoStyleEngine.generate(_input(
        textile: TextilePreference.wax,
        context: DayContext.dinerPrive,
        condition: WeatherCondition.pluvieux,
        temperatureCelsius: 24,
      ));
      expect(
        output.outfitSummary,
        'Veste croisée européenne imperméabilisée, touches de Wax, bottines imperméables.',
      );
    });

    test('sans veste : "haut, chaussures."', () {
      final output = AtmoStyleEngine.generate(_input(
        textile: TextilePreference.classique,
        context: DayContext.visitePatients,
        condition: WeatherCondition.ensoleille,
        temperatureCelsius: 24,
      ));
      expect(output.outfitSummary, 'Chemise oxford classique, mocassins en cuir.');
    });
  });

  group('Liste des pièces', () {
    test('4 pièces quand il y a une veste', () {
      final output = AtmoStyleEngine.generate(_input(context: DayContext.dinerPrive));
      expect(output.garmentPieces.length, 4);
    });

    test('3 pièces sans veste', () {
      final output = AtmoStyleEngine.generate(_input(
        context: DayContext.visitePatients,
        condition: WeatherCondition.ensoleille,
        temperatureCelsius: 24,
      ));
      expect(output.garmentPieces.length, 3);
    });

    test('chaque pièce commence par une majuscule', () {
      final output = AtmoStyleEngine.generate(_input(context: DayContext.dinerPrive));
      for (final piece in output.garmentPieces) {
        expect(piece[0], piece[0].toUpperCase());
      }
    });
  });

  group('Prompt image', () {
    test('mentionne les pièces, le contexte et la météo', () {
      final output = AtmoStyleEngine.generate(_input(
        context: DayContext.dinerPrive,
        condition: WeatherCondition.pluvieux,
        temperatureCelsius: 24,
      ));
      expect(output.imageGenerationPrompt, contains('hyperréaliste'));
      expect(output.imageGenerationPrompt, contains('Veste croisée européenne imperméabilisée'));
      expect(output.imageGenerationPrompt, contains('dîner privé'));
      expect(output.imageGenerationPrompt, contains('24°C'));
    });
  });

  group('Contrat JSON : sérialisation', () {
    test('WeatherSnapshot aller-retour', () {
      const snapshot = WeatherSnapshot(temperatureCelsius: 27.5, condition: WeatherCondition.harmattan);
      final restored = WeatherSnapshot.fromJson(snapshot.toJson());
      expect(restored, snapshot);
    });

    test('EngineInput aller-retour', () {
      final input = _input(textile: TextilePreference.bazin, context: DayContext.dinerPrive);
      final restored = EngineInput.fromJson(input.toJson());
      expect(restored, input);
    });

    test('NotificationPayload aller-retour', () {
      const payload = NotificationPayload(title: 'Titre', body: 'Corps', hour: 20, minute: 0);
      final restored = NotificationPayload.fromJson(payload.toJson());
      expect(restored, payload);
    });

    test('EngineOutput aller-retour', () {
      final output = AtmoStyleEngine.generate(_input(context: DayContext.dinerPrive));
      final restored = EngineOutput.fromJson(output.toJson());
      expect(restored, output);
    });

    test("valeur d'enum inconnue lève une FormatException", () {
      expect(
        () => enumFromJson(TextilePreference.values, 'inconnu', 'TextilePreference'),
        throwsFormatException,
      );
    });

    test('type invalide pour temperatureCelsius lève une FormatException', () {
      expect(
        () => WeatherSnapshot.fromJson({'temperatureCelsius': 'chaud', 'condition': 'ensoleille'}),
        throwsFormatException,
      );
    });
  });
}
