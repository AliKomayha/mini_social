import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mini_social/config.dart';
import 'package:mini_social/data/models/profile_model.dart';
import 'package:mini_social/data/services/profile_service.dart';

class EditProfile extends StatefulWidget {
  final Profile profile;
  final String token;
  final String baseUrl;
  final VoidCallback? onProfileUpdated;

  const EditProfile({
    super.key,
    required this.profile,
    required this.token,
    required this.baseUrl,
    this.onProfileUpdated,
  });

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _newAvatar;
  DateTime? _birthDate;
  bool _isPrivate = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _displayNameController.text = widget.profile.displayName;
    _bioController.text = widget.profile.bio ?? '';
    _isPrivate = widget.profile.isPrivate;
    // Note: BirthDate is not in the Profile model, so we'll leave it null initially
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    String cleanPath = path.replaceFirst(RegExp(r'^file://'), '');
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return cleanPath;
    }
    return '${widget.baseUrl}$cleanPath';
  }

  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _newAvatar = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _removeAvatar() {
    setState(() {
      _newAvatar = null;
    });
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name is required')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ProfileService(
        baseUrl: widget.baseUrl,
        token: widget.token,
      );

      final result = await service.editProfile(
        displayName: displayName,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        birthDate: _birthDate,
        isPrivate: _isPrivate,
        avatarFile: _newAvatar,
      );

      if (result['success'] == true) {
        widget.onProfileUpdated?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Profile updated successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to update profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // Avatar Section
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _newAvatar != null
                      ? FileImage(_newAvatar!)
                      : (widget.profile.avatar.isNotEmpty
                          ? NetworkImage(_getImageUrl(widget.profile.avatar))
                          : null) as ImageProvider?,
                  child: _newAvatar == null && widget.profile.avatar.isEmpty
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      onPressed: _pickAvatar,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),
            
            if (_newAvatar != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _removeAvatar,
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Remove Photo'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Display Name Field
            TextField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                hintText: 'Enter your display name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              style: const TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 20),
            
            // Bio Field
            TextField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell us about yourself',
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 4,
              style: const TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 20),
            
            // Birth Date Field
            InkWell(
              onTap: _selectBirthDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: Colors.grey),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _birthDate != null
                            ? DateFormat('yyyy-MM-dd').format(_birthDate!)
                            : 'Select Birth Date (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          color: _birthDate != null ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                    ),
                    if (_birthDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _birthDate = null;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Privacy Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: Colors.grey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Private Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Only approved followers can see your posts',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isPrivate,
                    onChanged: (value) {
                      setState(() {
                        _isPrivate = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            // Error Message
            if (_error != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
