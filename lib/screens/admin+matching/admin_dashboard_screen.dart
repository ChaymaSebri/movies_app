import 'package:flutter/material.dart';
import 'package:movies_app/services/admin_service.dart';
import 'package:movies_app/services/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  
  String _searchQuery = '';
  bool _isLoadingStats = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoadStats();
  }

  Future<void> _checkAdminAndLoadStats() async {
    final isAdmin = await _adminService.isCurrentUserAdmin();
    
    if (!isAdmin) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accès refusé: Vous n\'êtes pas administrateur'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _adminService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.purple,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingStats
          ? const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistiques
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  
                  // Barre de recherche
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un utilisateur...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Liste des utilisateurs
                  const Text(
                    'Gestion des utilisateurs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildUsersList(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsSection() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Utilisateurs totaux',
          _stats['totalUsers']?.toString() ?? '0',
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Utilisateurs actifs',
          _stats['activeUsers']?.toString() ?? '0',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Films disponibles',
          _stats['totalMovies']?.toString() ?? '0',
          Icons.movie,
          Colors.purple,
        ),
        _buildStatCard(
          'Matches créés',
          _stats['totalMatches']?.toString() ?? '0',
          Icons.favorite,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: Colors.purple),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Erreur: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Aucun utilisateur trouvé',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        var users = snapshot.data!;

        // Filtrer selon la recherche
        if (_searchQuery.isNotEmpty) {
          users = users.where((user) {
            final firstName = (user['firstName'] ?? user['prenom'] ?? '')
                .toString()
                .toLowerCase();
            final lastName = (user['lastName'] ?? user['nom'] ?? '')
                .toString()
                .toLowerCase();
            final email = (user['email'] ?? '').toString().toLowerCase();
            
            return firstName.contains(_searchQuery) ||
                   lastName.contains(_searchQuery) ||
                   email.contains(_searchQuery);
          }).toList();
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserCard(user);
          },
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final userId = user['id'] as String;
    final firstName = user['firstName'] ?? user['prenom'] ?? 'N/A';
    final lastName = user['lastName'] ?? user['nom'] ?? '';
    final email = user['email'] ?? 'N/A';
    final isActive = user['isActive'] ?? true;
    final isAdmin = user['role'] == 'admin' || user['isAdmin'] == true;
    final photoUrl = user['photoUrl'] as String?;

    // Ne pas permettre de modifier son propre compte
    final currentUserId = _authService.currentUser?.uid;
    final isSelf = userId == currentUserId;

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.purple.withValues(alpha: 0.2),
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? const Icon(Icons.person, color: Colors.white, size: 28)
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Infos utilisateur
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$firstName $lastName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive ? 'Actif' : 'Désactivé',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Actions
            if (!isSelf)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: const Color(0xFF2A2A2A),
                onSelected: (value) => _handleUserAction(value, userId, isActive),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          isActive ? Icons.block : Icons.check_circle,
                          color: isActive ? Colors.red : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isActive ? 'Désactiver' : 'Activer',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  if (!isAdmin)
                    const PopupMenuItem(
                      value: 'promote',
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings,
                              color: Colors.purple, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Promouvoir admin',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUserAction(String action, String userId, bool isActive) async {
    try {
      if (action == 'toggle') {
        await _adminService.toggleUserStatus(userId, isActive);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isActive ? 'Utilisateur désactivé' : 'Utilisateur activé',
              ),
              backgroundColor: Colors.purple,
            ),
          );
        }
        await _loadStats(); // Recharger les stats
      } else if (action == 'promote') {
        await _adminService.promoteToAdmin(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Utilisateur promu administrateur'),
              backgroundColor: Colors.purple,
            ),
          );
        }
        await _loadStats(); // Recharger les stats
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}