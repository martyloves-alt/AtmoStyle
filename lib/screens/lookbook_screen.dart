import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/atmostyle_contract.dart';
import '../services/gemini_image_service.dart';
import '../services/photo_service.dart';
import 'reglages_screen.dart';
import 'validation_screen.dart';

class LookbookScreen extends StatefulWidget {
  const LookbookScreen({super.key, required this.output});

  final EngineOutput output;

  @override
  State<LookbookScreen> createState() => _LookbookScreenState();
}

class _LookbookScreenState extends State<LookbookScreen> {
  final PhotoService _photoService = PhotoService();
  final GeminiImageService _geminiService = GeminiImageService();

  File? _referencePhoto;
  Uint8List? _generatedImage;
  bool _isBusy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReferencePhoto();
  }

  Future<void> _loadReferencePhoto() async {
    final photo = await _photoService.getReferencePhoto();
    if (!mounted) return;
    setState(() => _referencePhoto = photo);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    final saved = await _photoService.pickAndSaveReferencePhoto(source: source);
    if (!mounted) return;
    setState(() {
      if (saved != null) _referencePhoto = saved;
      _isBusy = false;
    });
  }

  Future<void> _generateImage() async {
    final photo = _referencePhoto;
    if (photo == null) return;

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final bytes = await photo.readAsBytes();
      final generated = await _geminiService.generateImage(
        prompt: widget.output.imageGenerationPrompt,
        referencePhotoBytes: bytes,
      );
      if (!mounted) return;
      setState(() {
        _generatedImage = generated;
        _isBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Génération impossible : $e';
        _isBusy = false;
      });
    }
  }

  Future<void> _choosePhotoSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) {
      await _pickPhoto(source);
    }
  }

  @override
  Widget build(BuildContext context) {
    final output = widget.output;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ton look du jour'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReglagesScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(output.weatherHeadline, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildImageArea(context),
            const SizedBox(height: 12),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            _buildPhotoAction(context),
            const SizedBox(height: 20),
            Text(output.outfitSummary, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            ...output.garmentPieces.map(
              (piece) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6),
                    const SizedBox(width: 8),
                    Expanded(child: Text(piece)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(output.accessoryNote, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(output.fragranceNote, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ValidationScreen(output: output)),
              ),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Commander la confection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: _isBusy
            ? const Center(child: CircularProgressIndicator())
            : _generatedImage != null
                ? Image.memory(_generatedImage!, fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _referencePhoto == null
                              ? 'Ajoute une photo pour générer ton image'
                              : "Prêt à générer l'image",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildPhotoAction(BuildContext context) {
    if (_referencePhoto == null) {
      return OutlinedButton.icon(
        onPressed: _isBusy ? null : _choosePhotoSource,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Ajouter ma photo'),
      );
    }
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _isBusy ? null : _generateImage,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text("Générer l'image"),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _isBusy ? null : _choosePhotoSource,
          icon: const Icon(Icons.refresh),
          tooltip: 'Changer de photo',
        ),
      ],
    );
  }
}
