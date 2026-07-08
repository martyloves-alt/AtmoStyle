// Service météo — pour l'instant, une valeur fixe.
//
// L'appel réel à une API météo (et la gestion des permissions de
// localisation) sera ajouté dans une étape ultérieure. Le reste de l'app
// ne dépend que de la méthode fetchWeather ci-dessous : le remplacement
// par un vrai appel réseau restera isolé dans ce seul fichier.

import '../models/atmostyle_contract.dart';

class WeatherService {
  Future<WeatherSnapshot> fetchWeather({required TargetDay targetDay}) async {
    // TODO(étape ultérieure) : remplacer par un vrai appel API météo.
    return const WeatherSnapshot(
      temperatureCelsius: 26,
      condition: WeatherCondition.ensoleille,
    );
  }
}
