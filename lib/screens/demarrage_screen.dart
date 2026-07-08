import 'package:flutter/material.dart';
import '../models/atmostyle_contract.dart';
import '../engine/atmostyle_engine.dart';
import '../services/weather_service.dart';
import 'lookbook_screen.dart';

class DemarrageScreen extends StatefulWidget {
  const DemarrageScreen({super.key});

  @override
  State<DemarrageScreen> createState() => _DemarrageScreenState();
}

class _DemarrageScreenState extends State<DemarrageScreen> {
  TextilePreference _textile = TextilePreference.wax;
  DayContext _context = DayContext.formationMagistrale;
  AccessoryPreference _accessory = AccessoryPreference.montreAutomatique;
  FragranceSignature _fragrance = FragranceSignature.fraicheurNeutre;
  bool _isGenerating = false;

  Future<void> _generer() async {
    setState(() => _isGenerating = true);

    final weather = await WeatherService().fetchWeather(targetDay: TargetDay.aujourdHui);

    final input = EngineInput(
      textile: _textile,
      context: _context,
      accessory: _accessory,
      fragrance: _fragrance,
      weather: weather,
      targetDay: TargetDay.aujourdHui,
    );

    final output = AtmoStyleEngine.generate(input);

    if (!mounted) return;
    setState(() => _isGenerating = false);

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LookbookScreen(output: output)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AtmoStyle')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Question<TextilePreference>(
              label: "Quel tissu aujourd'hui ?",
              value: _textile,
              options: const {
                TextilePreference.bazin: 'Bazin',
                TextilePreference.wax: 'Wax',
                TextilePreference.classique: 'Classique',
              },
              onChanged: (v) => setState(() => _textile = v),
            ),
            const SizedBox(height: 24),
            _Question<DayContext>(
              label: 'Le contexte du jour ?',
              value: _context,
              options: const {
                DayContext.visitePatients: 'Visite de patients',
                DayContext.formationMagistrale: 'Formation magistrale',
                DayContext.dinerPrive: 'Dîner privé',
              },
              onChanged: (v) => setState(() => _context = v),
            ),
            const SizedBox(height: 24),
            _Question<AccessoryPreference>(
              label: 'Un accessoire clé ?',
              value: _accessory,
              options: const {
                AccessoryPreference.montreAutomatique: 'Montre automatique',
                AccessoryPreference.poignetDegage: 'Poignet dégagé',
                AccessoryPreference.braceletDiscret: 'Bracelet discret',
              },
              onChanged: (v) => setState(() => _accessory = v),
            ),
            const SizedBox(height: 24),
            _Question<FragranceSignature>(
              label: 'Une signature olfactive ?',
              value: _fragrance,
              options: const {
                FragranceSignature.propreSavonneux: 'Propre / savonneux',
                FragranceSignature.fraicheurNeutre: 'Fraîcheur neutre',
                FragranceSignature.boiseIntense: 'Boisé intense',
              },
              onChanged: (v) => setState(() => _fragrance = v),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isGenerating ? null : _generer,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Générer ma tenue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Question<T> extends StatelessWidget {
  const _Question({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((entry) {
            final selected = entry.key == value;
            return ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) => onChanged(entry.key),
            );
          }).toList(),
        ),
      ],
    );
  }
}
