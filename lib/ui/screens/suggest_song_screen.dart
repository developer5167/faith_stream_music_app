import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/song_suggestion_service.dart';
import '../../utils/constants.dart';
import '../../config/app_theme.dart';
import '../widgets/gradient_background.dart';

class SuggestSongScreen extends StatefulWidget {
  final String? initialSongName;

  const SuggestSongScreen({super.key, this.initialSongName});

  @override
  State<SuggestSongScreen> createState() => _SuggestSongScreenState();
}

class _SuggestSongScreenState extends State<SuggestSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final _songNameController = TextEditingController();
  final _ministryNameController = TextEditingController();
  final _singerNameController = TextEditingController();
  final _albumNameController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSongName != null) {
      _songNameController.text = widget.initialSongName!;
    }
  }

  @override
  void dispose() {
    _songNameController.dispose();
    _ministryNameController.dispose();
    _singerNameController.dispose();
    _albumNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<SongSuggestionService>().suggestSong(
        songName: _songNameController.text.trim(),
        ministryName: _ministryNameController.text.trim(),
        singerName: _singerNameController.text.trim().isEmpty
            ? null
            : _singerNameController.text.trim(),
        albumName: _albumNameController.text.trim().isEmpty
            ? null
            : _albumNameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your suggestion has been submitted.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit suggestion: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Suggest a Song'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Can\'t find what you\'re looking for? Suggest it to us and we\'ll do our best to add it!',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 32),
                _buildTextField(
                  controller: _songNameController,
                  label: 'Song Name*',
                  hint: 'Enter song title',
                  validator: (value) => value?.trim().isEmpty ?? true
                      ? 'Song name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _ministryNameController,
                  label: 'Ministry / From / By Whom*',
                  hint: 'Enter ministry or artist name',
                  validator: (value) => value?.trim().isEmpty ?? true
                      ? 'Ministry name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _singerNameController,
                  label: 'Singer Name (Optional)',
                  hint: 'Enter singer name',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _albumNameController,
                  label: 'Album Name (Optional)',
                  hint: 'Enter album name',
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: AppTheme.darkPrimary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Submit Suggestion',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.darkPrimary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
