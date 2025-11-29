import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:movies_app/services/admin_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMovieDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: _adminService.getDashboardStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Erreur: ${snapshot.error}');
                }
                final stats = snapshot.data ?? {};
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Users', stats['totalUsers'] ?? 0),
                        _buildStat('Active', stats['activeUsers'] ?? 0),
                        _buildStat('Movies', stats['totalMovies'] ?? 0),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _adminService.getUsersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Erreur: ${snapshot.error}');
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Aucun utilisateur trouvé'),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final isActive = data['isActive'] == true;
                      final name =
                          '${data['firstName'] ?? data['prenom'] ?? ''} ${data['lastName'] ?? data['nom'] ?? ''}'
                              .trim();

                      return ListTile(
                        title: Text(
                          name.isEmpty ? (data['email'] ?? doc.id) : name,
                        ),
                        subtitle: Text(data['email'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Promote button (quick demo)
                            if (data['role'] != 'admin' &&
                                data['isAdmin'] != true)
                              IconButton(
                                icon: const Icon(
                                  Icons.admin_panel_settings_outlined,
                                ),
                                tooltip: 'Promouvoir en admin',
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  try {
                                    await _adminService.promoteToAdmin(doc.id);
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Utilisateur promu admin',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    messenger.showSnackBar(
                                      SnackBar(content: Text('Erreur: $e')),
                                    );
                                  }
                                },
                              ),
                            Text(isActive ? 'Actif' : 'Désactivé'),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                isActive ? Icons.toggle_on : Icons.toggle_off,
                                color: isActive ? Colors.green : Colors.grey,
                              ),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  await _adminService.toggleUserStatus(
                                    doc.id,
                                    isActive,
                                  );
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Statut mis à jour'),
                                    ),
                                  );
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Erreur: $e')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Floating button area - add movie
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddMovieDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final posterCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un film'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Titre'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: posterCtrl,
                decoration: const InputDecoration(
                  labelText: 'Poster URL (optionnel)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final desc = descCtrl.text.trim();
              final poster = posterCtrl.text.trim();
              if (title.isEmpty) return;
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _adminService.addMovie({
                  'title': title,
                  'description': desc,
                  'posterUrl': poster,
                });
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Film ajouté')),
                );
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, Object value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}
