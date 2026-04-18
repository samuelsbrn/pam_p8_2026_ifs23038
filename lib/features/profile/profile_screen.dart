// lib/features/profile/profile_screen.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart'; // Import ini ditambahkan
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/top_app_bar_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _userCtrl;
  bool _profileLoading = false;

  final _passFormKey = GlobalKey<FormState>();
  final _currPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confPassCtrl = TextEditingController();
  bool _passLoading = false;
  bool _showCurrPass = false;
  bool _showNewPass = false;
  bool _showConfPass = false;

  Uint8List? _photoPreviewBytes;
  String _lastSyncedUserFingerprint = '';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _userCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _currPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confPassCtrl.dispose();
    super.dispose();
  }

  void _syncProfileFields(AuthProvider provider) {
    final user = provider.user;
    if (user == null) return;

    final fingerprint = '${user.id}|${user.name}|${user.username}';
    if (fingerprint == _lastSyncedUserFingerprint) return;

    _lastSyncedUserFingerprint = fingerprint;
    _nameCtrl.text = user.name;
    _userCtrl.text = user.username;
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();

    Future<void> pickFrom(ImageSource source) async {
      final authProvider = context.read<AuthProvider>();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 512,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _photoPreviewBytes = bytes;
      });

      final success = await authProvider.updatePhoto(
        imageBytes: bytes,
        imageFilename: picked.name,
      );

      if (!mounted) return;
      if (!success) {
        setState(() {
          _photoPreviewBytes = null;
        });
      }

      showAppSnackBar(
        context,
        message: success
            ? 'Foto profil diperbarui.'
            : authProvider.errorMessage,
        type: success ? SnackBarType.success : SnackBarType.error,
      );
    }

    if (kIsWeb) {
      await pickFrom(ImageSource.gallery);
      return;
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                pickFrom(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(ctx);
                pickFrom(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _profileLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile(
      name: _nameCtrl.text.trim(),
      username: _userCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _profileLoading = false);

    showAppSnackBar(
      context,
      message: success
          ? 'Profil berhasil diperbarui.'
          : authProvider.errorMessage,
      type: success ? SnackBarType.success : SnackBarType.error,
    );
  }

  Future<void> _submitPassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    setState(() => _passLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updatePassword(
      currentPassword: _currPassCtrl.text.trim(),
      newPassword: _newPassCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _passLoading = false);

    showAppSnackBar(
      context,
      message: success
          ? 'Kata sandi berhasil diubah.'
          : authProvider.errorMessage,
      type: success ? SnackBarType.success : SnackBarType.error,
    );

    if (success) {
      _currPassCtrl.clear();
      _newPassCtrl.clear();
      _confPassCtrl.clear();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    context.go(RouteConstants.login);
  }

  Widget _buildAvatar({
    required BuildContext context,
    required AuthProvider provider,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = provider.user;

    if (_photoPreviewBytes != null) {
      return ClipOval(
        child: Image.memory(
          _photoPreviewBytes!,
          width: 108,
          height: 108,
          fit: BoxFit.cover,
        ),
      );
    }

    if (user?.urlPhoto != null && user!.urlPhoto!.isNotEmpty) {
      // Gabungkan Base URL agar gambar bisa terunduh dengan benar
      final imageUrl = user.urlPhoto!.startsWith('http')
          ? user.urlPhoto!
          : '${ApiConstants.baseUrl}${user.urlPhoto!.startsWith('/') ? '' : '/'}${user.urlPhoto!}';

      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 108,
          height: 108,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 36,
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Text(
        (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 36,
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();
    final user = provider.user;
    final colorScheme = Theme.of(context).colorScheme;

    _syncProfileFields(provider);

    if (provider.status == AuthStatus.loading && user == null) {
      return const Scaffold(body: LoadingWidget());
    }

    return Scaffold(
      appBar: TopAppBarWidget(
        title: 'Profil Saya',
        showBackButton: true,
        menuItems: [
          TopAppBarMenuItem(
            text: 'Keluar',
            icon: Icons.logout,
            isDestructive: true,
            onTap: _logout,
          ),
        ],
      ),
      body: AppBackground(
        showTopGlow: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: colorScheme.primaryContainer,
                          child: _buildAvatar(
                            context: context,
                            provider: provider,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@${user?.username ?? ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            _SectionCard(
              title: 'Edit Profil',
              icon: Icons.person_outline,
              child: Form(
                key: _profileFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama tidak boleh kosong.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username tidak boleh kosong.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _profileLoading ? null : _submitProfile,
                        icon: _profileLoading
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _profileLoading ? 'Menyimpan...' : 'Simpan Profil',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Ganti Kata Sandi',
              icon: Icons.lock_outline,
              child: Form(
                key: _passFormKey,
                child: Column(
                  children: [
                    _PasswordField(
                      controller: _currPassCtrl,
                      label: 'Kata Sandi Saat Ini',
                      show: _showCurrPass,
                      onToggle: () =>
                          setState(() => _showCurrPass = !_showCurrPass),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kata sandi saat ini diperlukan.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _PasswordField(
                      controller: _newPassCtrl,
                      label: 'Kata Sandi Baru',
                      show: _showNewPass,
                      onToggle: () =>
                          setState(() => _showNewPass = !_showNewPass),
                      validator: (value) {
                        if (value == null || value.trim().length < 6) {
                          return 'Minimal 6 karakter.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _PasswordField(
                      controller: _confPassCtrl,
                      label: 'Konfirmasi Kata Sandi Baru',
                      show: _showConfPass,
                      onToggle: () =>
                          setState(() => _showConfPass = !_showConfPass),
                      validator: (value) {
                        if (value != _newPassCtrl.text) {
                          return 'Kata sandi tidak cocok.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _passLoading ? null : _submitPassword,
                        icon: _passLoading
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.key),
                        label: Text(
                          _passLoading ? 'Mengubah...' : 'Ganti Kata Sandi',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.show,
    required this.onToggle,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool show;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}