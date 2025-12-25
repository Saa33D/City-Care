import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart'; // <--- Import GPS
import '../config/theme.dart';
import '../models/report.dart';
import '../providers/report_provider.dart';

class AddReportScreen extends StatefulWidget {
  final Report? report;
  final bool isEditing;

  const AddReportScreen({super.key, this.report, this.isEditing = false});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _title;
  String? _description;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  
  // Variables pour le GPS
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.report != null) {
      _title = widget.report!.title;
      _description = widget.report!.description;
      _latitude = widget.report!.latitude;
      _longitude = widget.report!.longitude;
    }
  }
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    bool serviceEnabled;
    LocationPermission permission;

    // 1. Vérifie si le GPS est activé sur le téléphone
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le GPS est désactivé.')));
      }
      setState(() => _isLoadingLocation = false);
      return;
    }

    // 2. Vérifie les permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions GPS refusées.')));
        }
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    // 3. Obtient la position
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _isLoadingLocation = false;
    });
  }

  void _showImageSourceActionSheet(BuildContext context) {
   // (Le code est identique à l'étape précédente, je ne le répète pas pour gagner de la place,
   // garde ton code existant ici pour _showImageSourceActionSheet)
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        if (widget.isEditing && widget.report != null) {
          // Mode édition
          final updatedReport = Report(
            id: widget.report!.id,
            title: _title!,
            description: _description!,
            date: widget.report!.date,
            status: widget.report!.status,
            imagePath: widget.report!.imagePath,
            latitude: _latitude,
            longitude: _longitude,
          );

          await Provider.of<ReportProvider>(context, listen: false)
              .updateReport(updatedReport, _selectedImage);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Modifié avec succès !')),
            );
            Navigator.pop(context);
          }
        } else {
          // Mode création
          final newReport = Report(
            id: '', // L'ID sera généré par Firebase
            title: _title!,
            description: _description!,
            date: DateFormat('dd/MM/yyyy').format(DateTime.now()),
            status: 'En attente',
            imagePath: '', // Sera rempli par le provider
            latitude: _latitude,
            longitude: _longitude,
          );

          // Appel au Provider (await = on attend que l'upload soit fini)
          await Provider.of<ReportProvider>(context, listen: false)
              .addReport(newReport, _selectedImage);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Envoyé avec succès !')),
            );
            Navigator.pop(context);
          }
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Erreur: $error')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Modifier le signalement' : 'Nouveau signalement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // (Code Image identique à l'étape précédente...)
               GestureDetector(
                onTap: () => _showImageSourceActionSheet(context),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 50, color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            Text('Appuyer pour ajouter une photo', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                decoration: const InputDecoration(labelText: 'Titre', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
                validator: (val) => val == null || val.isEmpty ? 'Titre requis' : null,
                onSaved: (val) => _title = val,
                initialValue: widget.isEditing ? widget.report?.title : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description), alignLabelWithHint: true),
                maxLines: 4,
                validator: (val) => val == null || val.isEmpty ? 'Description requise' : null,
                onSaved: (val) => _description = val,
                initialValue: widget.isEditing ? widget.report?.description : null,
              ),
              const SizedBox(height: 16),

              // --- BOUTON GPS ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!)
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: AppTheme.primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _latitude != null 
                          ? "Position acquise : \nLat: ${_latitude!.toStringAsFixed(4)}, Lng: ${_longitude!.toStringAsFixed(4)}"
                          : "Aucune position enregistrée",
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                    ),
                    _isLoadingLocation 
                      ? const CircularProgressIndicator()
                      : TextButton(
                          onPressed: _getCurrentLocation, 
                          child: const Text("LOCALISER")
                        )
                  ],
                ),
              ),
              // ------------------

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(widget.isEditing ? 'METTRE À JOUR' : 'ENVOYER', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}