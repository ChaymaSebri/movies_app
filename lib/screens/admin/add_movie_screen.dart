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
  @override
  State<AddMovieScreen> createState() => _AddMovieScreenState();
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
    'Action',
    'Adventure',
    'Comedy',
    'Crime',
    'Drama',
    'Fantasy',
    'Horror',
    'Mystery',
    'Romance',
    'Sci-Fi',
    'Thriller',
    'Biography',
    'History'
  ];

  final ImagePicker _picker = ImagePicker();
  late final CloudinaryPublic cloudinary;

  @override
  void initState() {
    super.initState();
    cloudinary = CloudinaryPublic(
      dotenv.env['CLOUDINARY_CLOUD_NAME']!,
      dotenv.env['CLOUDINARY_UPLOAD_PRESET']!,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _yearController.dispose();
    _durationController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _addMovie() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one genre")),
      );
      return;
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a poster image")),
      );
      return;
    }

    setState(() => _isUploading = true);
    final posterUrl = await _uploadImage();
    if (posterUrl == null) {
      setState(() => _isUploading = false);
      return;
    }

    final backdropUrl =
    posterUrl.replaceAll('/upload/', '/upload/w_1280,c_limit/');

    try {
      // Generate unique ID for the movie
      final movieId = DateTime.now().millisecondsSinceEpoch.toString();

      final movie = Movie(
        id: movieId,
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

      // Use .doc(movieId).set() instead of .add()
      // This ensures the document ID matches the movie.id
      await FirebaseFirestore.instance
          .collection('movies')
          .doc(movieId)
          .set(movie.toFirestoreMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Movie added successfully!"),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error adding movie: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add Movie",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                _titleController,
                "Movie Title",
                "e.g., Inception",
              ),
              const SizedBox(height: 20),
              _buildTextField(
                _descriptionController,
                "Description",
                "Movie synopsis...",
                maxLines: 4,
              ),
              const SizedBox(height: 30),

              // POSTER
              Text(
                "Poster",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: _selectedImage == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 60,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Click to upload poster",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "PNG, JPG up to 10MB",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _yearController,
                      "Year",
                      "2024",
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      _durationController,
                      "Duration (min)",
                      "120",
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField(
                _ratingController,
                "Rating (out of 10)",
                "8.5",
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: 30),
              Text(
                "Category",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: _categories.map((cat) {
                  final selected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    selectedColor: colorScheme.primary,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    labelStyle: TextStyle(
                      color: selected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),
              Text(
                "Genres",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _allGenres.map((g) {
                  final selected = _selectedGenres.contains(g);
                  return FilterChip(
                    label: Text(g),
                    selected: selected,
                    selectedColor: colorScheme.primary,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    labelStyle: TextStyle(
                      color: selected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (v) => setState(
                          () => v
                          ? _selectedGenres.add(g)
                          : _selectedGenres.remove(g),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              // ADD BUTTON
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _addMovie,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    disabledBackgroundColor:
                    colorScheme.primary.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                  ),
                  child: _isUploading
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: colorScheme.onPrimary,
                      strokeWidth: 3,
                    ),
                  )
                      : const Text(
                    "Add Movie",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController c,
      String label,
      String hint, {
        int maxLines = 1,
        TextInputType? keyboardType,
      }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: c,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          validator: (v) => v?.trim().isEmpty == true ? "Required" : null,
        ),
      ],
    );
  }
}