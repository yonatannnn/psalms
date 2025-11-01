import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  bool _isSaving = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _prefillUsername();
  }

  String _normalizeUsername(String username) {
    String normalized = username.trim();
    if (normalized.startsWith('@')) {
      normalized = normalized.substring(1).trim();
    }
    return normalized;
  }

  Future<void> _prefillUsername() async {
    try {
      final user = await AuthService().getCurrentUserData();
      if (user != null) {
        setState(() {
          _usernameController.text = user.username;
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await AuthService().updateCredentials(
        newUsername: _normalizeUsername(_usernameController.text),
        newPassword: _newPasswordController.text.trim().isEmpty ? null : _newPasswordController.text.trim(),
        currentPassword: _currentPasswordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService.instance.currentLanguage == 'am' ? 'ተቀርቧል' : 'Updated')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAm = LocalizationService.instance.currentLanguage == 'am';
    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : null,
      appBar: AppBar(
        title: Text(isAm ? 'መገለጫ' : 'Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
                Card(
                  color: isDark ? Colors.grey.shade900 : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            (_usernameController.text.isNotEmpty ? _usernameController.text[0] : 'U').toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isAm ? 'መገለጫ መቀየር' : 'Edit Profile',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                              const SizedBox(height: 4),
                              Text(isAm ? 'የተጠቃሚ ስምን እና የሚስጥር ቁጥር ያዘምኑ' : 'Update username and password',
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Username
                Card(
                  color: isDark ? Colors.grey.shade900 : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: isAm ? 'የተጠቃሚ ስም' : 'Username',
                        helperText: LocalizationService.instance.translate('username_no_spaces'),
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return isAm ? 'የተጠቃሚ ስም ያስገቡ' : 'Please enter a username';
                        }
                        final normalized = _normalizeUsername(v);
                        if (normalized.isEmpty) {
                          return isAm ? 'የተጠቃሚ ስም ያስገቡ' : 'Please enter a username';
                        }
                        if (normalized.length < 3) {
                          return isAm ? 'ቢያንስ 3 ፊደል' : 'At least 3 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                ),

                // Passwords block
                Card(
                  color: isDark ? Colors.grey.shade900 : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: !_showCurrent,
                          decoration: InputDecoration(
                            labelText: isAm ? 'የአሁኑ የሚስጥር ቁጥር' : 'Current password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _showCurrent = !_showCurrent),
                              icon: Icon(_showCurrent ? Icons.visibility_off : Icons.visibility),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return isAm ? 'አሁን የሚስጥር ቁጥር ያስገቡ' : 'Enter your current password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: !_showNew,
                          decoration: InputDecoration(
                            labelText: isAm ? 'አዲስ የሚስጥር ቁጥር (አማራጭ)' : 'New password (optional)',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _showNew = !_showNew),
                              icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) {
                            if (v != null && v.isNotEmpty && v.length < 6) {
                              return isAm ? 'ቢያንስ 6 ፊደል' : 'At least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmNewPasswordController,
                          obscureText: !_showConfirm,
                          decoration: InputDecoration(
                            labelText: isAm ? 'አዲሱን የሚስጥር ቁጥር አረጋግጥ (አማራጭ)' : 'Confirm new password (optional)',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _showConfirm = !_showConfirm),
                              icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) {
                            final np = _newPasswordController.text;
                            if (np.isEmpty && (v == null || v.isEmpty)) return null;
                            if (np.isNotEmpty && (v == null || v.isEmpty)) {
                              return isAm ? 'አዲሱን የሚስጥር ቁጥር ያረጋግጡ' : 'Please confirm the new password';
                            }
                            if (v != np) {
                              return isAm ? 'የአዲሱ ቁጥሮች አይመሳሰሉም' : 'New passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(isAm ? 'አስቀምጥ' : 'Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
}


