import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/library/library_bloc.dart';
import '../../blocs/library/library_event.dart';
import '../../blocs/library/library_state.dart';
import '../../utils/constants.dart';

class CreatePlaylistScreen extends StatefulWidget {
  const CreatePlaylistScreen({super.key});

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleCreate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a playlist name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    context.read<LibraryBloc>().add(
      LibraryCreatePlaylist(
        name: name,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isPublic: _isPublic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<LibraryBloc, LibraryState>(
      listener: (context, state) {
        if (state is LibraryOperationSuccess &&
            state.message.contains('Playlist created')) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          Navigator.pop(context);
        } else if (state is LibraryError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Playlist'), elevation: 0),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Placeholder
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryBrown.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_a_photo_outlined,
                    size: 48,
                    color: AppColors.primaryBrown,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingXl),

              Text(
                'Give your playlist a name',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.paddingSm),
              TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'e.g. Morning Worship',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryBrown,
                      width: 2,
                    ),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppSizes.paddingLg),

              Text(
                'Description (Optional)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.paddingSm),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'What\'s this playlist about?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingLg),

              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text('Public Playlist'),
                  subtitle: const Text('Visible to everyone on FaithStream'),
                  value: _isPublic,
                  onChanged: (val) => setState(() => _isPublic = val),
                  activeColor: AppColors.primaryBrown,
                ),
              ),
              const SizedBox(height: AppSizes.paddingXl),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBrown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Playlist',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
