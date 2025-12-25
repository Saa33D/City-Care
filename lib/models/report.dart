class Report {
  final String id;
  final String title;
  final String description;
  final String date;
  final String status;
  final String imagePath;
  final double? latitude;  // <--- Nouveau
  final double? longitude; // <--- Nouveau

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.status = 'En attente',
    this.imagePath = 'assets/placeholder.png',
    this.latitude,
    this.longitude,
  });
}