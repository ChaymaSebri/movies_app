// lib/screens/admin/add_movie_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/movie_model.dart';

class AddMovieScreen extends StatefulWidget {
  const AddMovieScreen({Key? key}) : super(key: key);
  @override State<AddMovieScreen> createState() => _AddMovieScreenState();
}

class _AddMovieScreenState extends State<AddMovieScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _yearController = TextEditingController();
  final _durationController = TextEditingController();
  final _ratingController = TextEditingController();

  File? _selectedImage;
  bool _isUploading = false;

  String _selectedCategory = 'Popular';
  final List<String> _selectedGenres = [];

  final List<String> _categories = ['Popular', 'Top Rated', 'Upcoming'];
  final List<String> _allGenres = [
    'Action', 'Adventure', 'Comedy', 'Crime', 'Drama', 'Fantasy',
    'Horror', 'Mystery', 'Romance', 'Sci-Fi', 'Thriller', 'Biography', 'History'
  ];

  final ImagePicker _picker = ImagePicker();
  final cloudinary = CloudinaryPublic(
    dotenv.env['CLOUDINARY_CLOUD_NAME']!,
    dotenv.env['CLOUDINARY_UPLOAD_PRESET']!,
  );

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      imageQuality: 90,
    );
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;
    setState(() => _isUploading = true);
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _selectedImage!.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'movie_posters',
        ),
      );
      return response.secureUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur upload: $e"), backgroundColor: Colors.red),
      );
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _addMovie() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Choisis un genre")));
      return;
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ajoute une affiche !")));
      return;
    }

    setState(() => _isUploading = true);
    final posterUrl = await _uploadImage();
    if (posterUrl == null) return;

    final backdropUrl = posterUrl.replaceAll('/upload/', '/upload/w_1280,c_limit/');

    final movie = Movie(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      releaseDate: DateTime(int.parse(_yearController.text.trim())),
      runtime: int.tryParse(_durationController.text.trim()),
      rating: double.tryParse(_ratingController.text.replaceAll(',', '.')),
      genres: _selectedGenres,
      source: 'manual',
      addedBy: 'admin',
      category: _selectedCategory,
    );

    await FirebaseFirestore.instance.collection('movies').add(movie.toFirestoreMap());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Film ajouté !"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Ajouter un film", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_titleController, "Titre du film", "Ex: Inception"),
              const SizedBox(height: 20),
              _buildTextField(_descriptionController, "Description", "Synopsis du film...", maxLines: 4),
              const SizedBox(height: 30),

              // POSTER
              const Text("Poster", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purple.shade400, width: 2),
                  ),
                  child: _selectedImage == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_a_photo, size: 60, color: Colors.purple),
                      SizedBox(height: 16),
                      Text("Click to upload poster", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      Text("PNG, JPG up to 10MB", style: TextStyle(color: Colors.white38, fontSize: 14)),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              Row(children: [
                Expanded(child: _buildTextField(_yearController, "Année", "2024", keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_durationController, "Durée (min)", "120", keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 20),
              _buildTextField(_ratingController, "Note (sur 10)", "8.5", keyboardType: TextInputType.numberWithOptions(decimal: true)),

              const SizedBox(height: 30),
              const Text("Catégorie", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: _categories.map((cat) {
                  final selected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    selectedColor: Colors.purple,
                    backgroundColor: Colors.grey[800],
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),
              const Text("Genres", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _allGenres.map((g) {
                  final selected = _selectedGenres.contains(g);
                  return FilterChip(
                    label: Text(g),
                    selected: selected,
                    selectedColor: Colors.purple,
                    backgroundColor: Colors.grey[800],
                    labelStyle: const TextStyle(color: Colors.white),
                    onSelected: (v) => setState(() => v ? _selectedGenres.add(g) : _selectedGenres.remove(g)),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              // BOUTON FIXE EN BAS DU FORMULAIRE
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _addMovie,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 8,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  )
                      : const Text(
                    "Ajouter le film",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 40), // Pour le clavier
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController c, String label, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: c,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF1E1E2E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          validator: (v) => v?.trim().isEmpty == true ? "Requis" : null,
        ),
      ],
    );
  }
}