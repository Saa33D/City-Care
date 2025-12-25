import 'package:flutter/material.dart';
import 'dart:io';
import '../models/report.dart';
import '../screens/map_screen.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Résolu':
        return Colors.green;
      case 'En cours':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  Widget _buildImage(String imagePath) {
    // Image locale (fichier système)
    if (imagePath.isNotEmpty && !imagePath.startsWith('http') && !imagePath.startsWith('assets')) {
      final file = File(imagePath);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.image, color: Colors.grey[400]),
        ),
      );
    }
    
    // Image web (URL HTTP)
    if (imagePath.startsWith('http') && imagePath.isNotEmpty) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.error, color: Colors.grey[400]),
        ),
      );
    }
    
    // Asset placeholder
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.image, color: Colors.grey[400]),
        ),
      );
    }
    
    // Image par défaut
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image, color: Colors.grey[400]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImage(report.imagePath),
          ),
        ),
        title: Text(
          report.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              report.date,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indicateur de statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(report.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor(report.status), width: 1),
              ),
              child: Text(
                report.status,
                style: TextStyle(
                  color: _getStatusColor(report.status),
                  fontSize: 10, // Plus petit
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Si le rapport a une position GPS, on affiche une icône carte
            if (report.latitude != null) 
              GestureDetector(
                onTap: () {
                   // Navigation vers la carte
                   // Astuce: On utilise Navigator.push ici, 
                   // mais idéalement le onTap devrait être géré par le parent.
                   // Pour simplifier ce tuto, on le fait ici.
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => MapScreen(report: report)), // Il faut importer map_screen.dart en haut
                   );
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Icon(Icons.map, color: Colors.blue[700]),
                ),
              )
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}