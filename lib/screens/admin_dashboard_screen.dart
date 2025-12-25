import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../providers/report_provider.dart';
import '../providers/auth_provider.dart';
import '../models/report.dart';
import 'package:provider/provider.dart';
import 'report_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<User> _allUsers = [];
  bool _isLoadingUsers = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'Tous';
  String _sortBy = 'date'; // 'date', 'status', 'title'
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    // Différer le chargement des données après le build pour éviter setState() during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadData();
    });
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
      if (reportProvider.hasMoreAll && !reportProvider.isLoadingMore) {
        reportProvider.loadMoreAllReports();
      }
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      // Charger tous les rapports (sans filtrer par utilisateur)
      await reportProvider.fetchAllReports();
      
      // Charger tous les utilisateurs
      final users = await authProvider.getAllUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
      }
    }
  }

  List<Report> get _filteredReports {
    final reportProvider = Provider.of<ReportProvider>(context);
    var reports = List<Report>.from(reportProvider.reports);

    // Filtrer par statut
    if (_statusFilter != 'Tous') {
      reports = reports.where((r) => r.status == _statusFilter).toList();
    }

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      reports = reports.where((r) {
        return r.title.toLowerCase().contains(_searchQuery) ||
               r.description.toLowerCase().contains(_searchQuery) ||
               r.id.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Trier
    reports.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'date':
          try {
            final dateA = DateTime.parse(a.date.replaceAll('/', '-'));
            final dateB = DateTime.parse(b.date.replaceAll('/', '-'));
            comparison = dateA.compareTo(dateB);
          } catch (e) {
            comparison = a.date.compareTo(b.date);
          }
          break;
        case 'status':
          comparison = a.status.compareTo(b.status);
          break;
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return reports;
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final reports = reportProvider.reports;
    final filteredReports = _filteredReports;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord Admin'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistiques globales
            _buildGlobalStats(reports, _allUsers),
            
            // Gestion des utilisateurs
            _buildUserManagement(_allUsers),
            
            // Gestion des signalements
            _buildReportsManagement(filteredReports, reportProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalStats(List<Report> reports, List<User> users) {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final statusCounts = reportProvider.statusCounts;
    final resolutionRate = reportProvider.resolutionRate;
    final totalReports = reports.length;
    final pendingCount = statusCounts['En attente'] ?? 0;
    final inProgressCount = statusCounts['En cours'] ?? 0;
    final resolvedCount = statusCounts['Résolu'] ?? 0;
    
    // Exclure l'admin connecté du comptage des utilisateurs
    final regularUsers = users.where((user) => user.id != authProvider.currentUser?.id).toList();
    final userCount = regularUsers.length;
    
    return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Statistiques globales',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.analytics_outlined, color: AppTheme.primaryColor),
            ],
            ),
          const SizedBox(height: 20),
          
          // Statistiques principales
            Row(
              children: [
                Expanded(
                  child: _buildEnhancedStatCard(
                    'Total signalements',
                    '$totalReports',
                    AppTheme.primaryColor,
                    Icons.assessment,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEnhancedStatCard(
                    'Utilisateurs',
                    '$userCount',
                    AppTheme.secondaryColor,
                    Icons.people,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          
          // Taux de résolution
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.successColor.withValues(alpha: 0.1),
                    AppTheme.successColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.successColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Taux de résolution',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${resolutionRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: AppTheme.successColor,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          
          // Répartition par statut
          const Text(
              'Répartition par statut',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatusBarCard(
                    'En attente',
                    pendingCount,
                    totalReports,
                    Colors.orange,
                    Icons.hourglass_empty,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusBarCard(
                    'En cours',
                    inProgressCount,
                    totalReports,
                    Colors.blue,
                    Icons.work,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusBarCard(
                    'Résolus',
                    resolvedCount,
                    totalReports,
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
          ],
      ),
    );
  }

  Widget _buildEnhancedStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBarCard(String status, int count, int total, Color color, IconData icon) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? count / total : 0,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagement(List<User> users) {
    // Filtrer pour ne garder que les utilisateurs (sans admins)
    final regularUsers = users.where((u) => !u.isAdmin).toList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Gestion des utilisateurs',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${regularUsers.length} utilisateurs',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
            ),
            const SizedBox(height: 16),
          
            if (_isLoadingUsers)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (regularUsers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Aucun utilisateur trouvé'),
              ),
            )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              itemCount: regularUsers.length,
                itemBuilder: (context, index) {
                final user = regularUsers[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(user.email),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey[700]),
                          onSelected: (value) {
                        if (value == 'delete') {
                              _deleteUser(user);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                            ),
                          ],
                        ),
                    ),
                  );
                },
              ),
          ],
      ),
    );
  }

  Widget _buildReportsManagement(List<Report> reports, ReportProvider reportProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestion des signalements',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.assignment, color: AppTheme.primaryColor),
            ],
          ),
          const SizedBox(height: 16),
            
            // Barre de recherche
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par titre, description ou ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Filtres et tri
            Row(
              children: [
                Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                        'Filtrer par statut',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'Tous', label: Text('Tous')),
                            ButtonSegment(value: 'En attente', label: Text('En attente')),
                            ButtonSegment(value: 'En cours', label: Text('En cours')),
                            ButtonSegment(value: 'Résolu', label: Text('Résolu')),
                          ],
                          selected: {_statusFilter},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              _statusFilter = newSelection.first;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Tri
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trier par',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    PopupMenuButton<String>(
                      initialValue: _sortBy,
                      onSelected: (value) {
                        setState(() {
                          if (_sortBy == value) {
                            _sortAscending = !_sortAscending;
                          } else {
                            _sortBy = value;
                            _sortAscending = false;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
            ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _sortBy == 'date' ? 'Date' : 
                              _sortBy == 'status' ? 'Statut' : 'Titre',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'date',
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 18),
                              SizedBox(width: 8),
                              Text('Date'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'status',
                          child: Row(
                            children: [
                              Icon(Icons.label, size: 18),
                              SizedBox(width: 8),
                              Text('Statut'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'title',
                          child: Row(
                            children: [
                              Icon(Icons.title, size: 18),
                              SizedBox(width: 8),
                              Text('Titre'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Compteur de résultats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${reports.length} signalement${reports.length > 1 ? 's' : ''} trouvé${reports.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Liste des signalements
            if (reports.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                child: Text('Aucun signalement trouvé'),
                ),
              )
            else
              Column(
                children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                      return _buildReportManagementItem(report, reportProvider);
                    },
                  ),
                  // Indicateur de chargement en bas
                  if (reportProvider.isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (!reportProvider.hasMoreAll && reports.length >= 10)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Tous les signalements ont été chargés',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),

    );
  }

  Widget _buildReportManagementItem(Report report, ReportProvider reportProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(report.status).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getStatusColor(report.status).withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: _getStatusColor(report.status).withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Icon(
            _getStatusIcon(report.status),
            color: _getStatusColor(report.status),
            size: 24,
          ),
        ),
        title: Text(
          report.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              report.description.length > 60
                  ? '${report.description.substring(0, 60)}...'
                  : report.description,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(report.status).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(report.status),
                        size: 12,
                        color: _getStatusColor(report.status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        report.status,
                        style: TextStyle(
                          fontSize: 11,
                          color: _getStatusColor(report.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      report.date,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[700]),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) async {
            switch (value) {
              case 'view':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportDetailScreen(report: report),
                        ),
                      );
                break;
              case 'status_pending':
                await _updateStatus(report, 'En attente', reportProvider);
                break;
              case 'status_in_progress':
                await _updateStatus(report, 'En cours', reportProvider);
                break;
              case 'status_resolved':
                await _updateStatus(report, 'Résolu', reportProvider);
                break;
              case 'delete':
                _deleteReport(report, reportProvider);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 18),
                  SizedBox(width: 8),
                  Text('Voir détails'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'status_pending',
              child: Row(
                children: [
                  Icon(Icons.hourglass_empty, size: 18, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Marquer: En attente'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'status_in_progress',
              child: Row(
                children: [
                  Icon(Icons.work, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Marquer: En cours'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'status_resolved',
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Marquer: Résolu'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer'),
                ],
              ),
              ),
          ],
        ),
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Résolu':
        return Icons.check_circle;
      case 'En cours':
        return Icons.work;
      default:
        return Icons.hourglass_empty;
    }
  }

  Future<void> _updateStatus(Report report, String newStatus, ReportProvider reportProvider) async {
    try {
      await reportProvider.updateReportStatus(report.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour: $newStatus'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _deleteReport(Report report, ReportProvider reportProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le signalement'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${report.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await reportProvider.deleteReport(report.id);
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Signalement supprimé'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  void _deleteUser(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Supprimer l\'utilisateur'),
          ],
        ),
        content: Text('Êtes-vous sûr de vouloir supprimer ${user.name} ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              try {
                await authProvider.deleteUser(user.id);
                _loadData();
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Utilisateur supprimé'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}