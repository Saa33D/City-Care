import 'package:flutter/material.dart';
import 'dart:io';
import '../config/theme.dart';
import '../models/report.dart';
import '../providers/report_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'add_report_screen.dart';

class ReportDetailScreen extends StatelessWidget {
  final Report report;

  const ReportDetailScreen({super.key, required this.report});

  void _editReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReportScreen(
          report: report,
          isEditing: true,
        ),
      ),
    );
  }

  void _deleteReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le signalement'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce signalement ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Provider.of<ReportProvider>(context, listen: false)
                    .deleteReport(report.id);
                
                if (context.mounted) {
                  Navigator.pop(context); // Retour à la liste
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Signalement supprimé avec succès'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $error'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar avec image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(report.imagePath),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editReport(context);
                      break;
                    case 'delete':
                      _deleteReport(context);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
            ],
          ),
          
          // Contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et statut
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          report.title,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(report.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(report.status),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          report.status,
                          style: TextStyle(
                            color: _getStatusColor(report.status),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.description_outlined),
                              const SizedBox(width: 8),
                              Text(
                                'Description',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            report.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Informations
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.calendar_today_outlined),
                          title: const Text('Date du signalement'),
                          subtitle: Text(report.date),
                        ),
                        const Divider(height: 1),
                        if (report.latitude != null && report.longitude != null) ...[
                          ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: const Text('Localisation'),
                            subtitle: Text(
                              'Lat: ${report.latitude!.toStringAsFixed(6)}, Lng: ${report.longitude!.toStringAsFixed(6)}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.map),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MapViewScreen(
                                      latitude: report.latitude!,
                                      longitude: report.longitude!,
                                      title: report.title,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('ID du signalement'),
                          subtitle: Text(report.id),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              // Copier l'ID
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Carte si localisation disponible
                  if (report.latitude != null && report.longitude != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Localisation',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 200,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(
                                      report.latitude!,
                                      report.longitude!,
                                    ),
                                    zoom: 15,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: MarkerId(report.id),
                                      position: LatLng(
                                        report.latitude!,
                                        report.longitude!,
                                      ),
                                      infoWindow: InfoWindow(
                                        title: report.title,
                                        snippet: report.status,
                                      ),
                                    ),
                                  },
                                  zoomControlsEnabled: false,
                                  scrollGesturesEnabled: false,
                                  mapType: MapType.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Résolu':
        return AppTheme.successColor;
      case 'En cours':
        return AppTheme.infoColor;
      default:
        return AppTheme.warningColor;
    }
  }

  Widget _buildImage(String imagePath) {
    // Image locale (fichier système)
    if (imagePath.isNotEmpty && !imagePath.startsWith('http') && !imagePath.startsWith('assets')) {
      final file = File(imagePath);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppTheme.surfaceColor,
            child: const Icon(
              Icons.image_not_supported,
              size: 50,
              color: AppTheme.textDisabled,
            ),
          );
        },
      );
    }
    
    // Image web (URL HTTP)
    if (imagePath.startsWith('http') && imagePath.isNotEmpty) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppTheme.surfaceColor,
            child: const Icon(
              Icons.image_not_supported,
              size: 50,
              color: AppTheme.textDisabled,
            ),
          );
        },
      );
    }
    
    // Asset placeholder ou défaut
    return Container(
      color: AppTheme.surfaceColor,
      child: const Icon(
        Icons.image_not_supported,
        size: 50,
        color: AppTheme.textDisabled,
      ),
    );
  }
}

// Écran pour afficher la carte en plein écran
class MapViewScreen extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String title;

  const MapViewScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localisation'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 17,
        ),
        markers: {
          Marker(
            markerId: MarkerId(title),
            position: LatLng(latitude, longitude),
            infoWindow: InfoWindow(title: title),
          ),
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        mapToolbarEnabled: true,
      ),
    );
  }
}
