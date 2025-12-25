import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/report.dart';

class MapScreen extends StatefulWidget {
  final Report report;

  const MapScreen({super.key, required this.report});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    // Position par défaut (ex: Centre ville générique) si pas de GPS
    final LatLng position = (widget.report.latitude != null && widget.report.longitude != null)
        ? LatLng(widget.report.latitude!, widget.report.longitude!)
        : const LatLng(0, 0);

    // Création du marqueur (Pin rouge)
    final Set<Marker> markers = {
      Marker(
        markerId: MarkerId(widget.report.id),
        position: position,
        infoWindow: InfoWindow(
          title: widget.report.title,
          snippet: widget.report.status,
        ),
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Localisation'),
        backgroundColor: Colors.green[700], // Style un peu différent pour la carte
      ),
      body: widget.report.latitude == null
          ? const Center(child: Text("Aucune localisation GPS pour ce signalement."))
          : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: position,
                zoom: 15.0,
              ),
              markers: markers,
            ),
    );
  }
}