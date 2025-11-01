import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'home_page.dart';
import '../services/localization_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;
  String _currentLanguage = LocalizationService.instance.currentLanguage;

  String _normalizeUsername(String username) {
    String normalized = username.trim();
    if (normalized.startsWith('@')) {
      normalized = normalized.substring(1).trim();
    }
    return normalized;
  }

  String _friendlyAuthMessage(Object error) {
    final isAm = LocalizationService.instance.currentLanguage == 'am';
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
          return isAm ? 'የመግቢያ ማስረጃ ትክክል አይደለም' : 'Invalid credentials';
        case 'user-not-found':
          return isAm ? 'መለያ አልተገኘም' : 'Account not found';
        case 'wrong-password':
          return isAm ? 'የሚስጥር ቁጥር ትክክል አይደለም' : 'Incorrect password';
        case 'invalid-email':
          return isAm ? 'ልክ ያልሆነ ኢሜይል' : 'Invalid email';
        case 'email-already-in-use':
          return isAm ? 'መለያ አለ' : 'Email already in use';
        case 'weak-password':
          return isAm ? 'የሚስጥር ቁጥር ደካማ ነው' : 'Weak password';
        case 'too-many-requests':
          return isAm ? 'ብዙ ሙከራዎች፣ እባክዎ ከጥቂት ጊዜ በኋላ ይሞክሩ' : 'Too many attempts, try again later';
        case 'network-request-failed':
          return isAm ? 'አውታረመረብ ችግኝ' : 'Network error';
        case 'operation-not-allowed':
          return isAm ? 'አገልግሎቱ አልተከበረም' : 'Operation not allowed';
        case 'user-disabled':
          return isAm ? 'መለያ ተሰናክሏል' : 'Account disabled';
      }
      return isAm ? 'የማልታወቅ የመግቢያ ስህተት' : 'Authentication error';
    }
    final msg = error.toString().replaceFirst('Exception: ', '');
    return msg.length > 120 ? (isAm ? 'ስህተት ተፈጥሯል' : 'Something went wrong') : msg;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserModel? user;
      
      final normalizedUsername = _normalizeUsername(_usernameController.text);
      
      if (_isLogin) {
        user = await _authService.signIn(
          username: normalizedUsername,
          password: _passwordController.text,
        );
      } else {
        // Check if username is available
        final isAvailable = await _authService.isUsernameAvailable(
          normalizedUsername,
        );
        
        if (!isAvailable) {
          setState(() {
            _errorMessage = 'Username is already taken';
            _isLoading = false;
          });
          return;
        }

        user = await _authService.signUp(
          username: normalizedUsername,
          password: _passwordController.text,
        );
      }

      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(user: user!),
          ),
        );
      } else {
        setState(() {
          _errorMessage = _isLogin 
              ? 'Invalid username or password' 
              : 'Failed to create account';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _friendlyAuthMessage(e);
      });
    } catch (e) {
      setState(() {
        _errorMessage = _friendlyAuthMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == LocalizationService.english
          ? LocalizationService.amharic
          : LocalizationService.english;
    });
    LocalizationService.instance.setLanguage(_currentLanguage);
    LocalizationService.instance.setCalendar(
      _currentLanguage == LocalizationService.amharic
          ? LocalizationService.ethiopian
          : LocalizationService.gregorian,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black87 : null,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              right: 8,
              top: 4,
              child: IconButton(
                tooltip: _currentLanguage == 'en' ? 'Switch to Amharic' : 'Switch to English',
                onPressed: _toggleLanguage,
                icon: Icon(
                  _currentLanguage == 'en' ? Icons.language : Icons.translate,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.deepPurple,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.black87 : Colors.white70.withOpacity(0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App Icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: const Icon(
                              Icons.menu_book,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Title
                          Text(
                            _isLogin
                                ? LocalizationService.instance.translate('login_welcome_back')
                                : LocalizationService.instance.translate('login_create_account'),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          Text(
                            _isLogin
                                ? LocalizationService.instance.translate('login_subtitle_signin')
                                : LocalizationService.instance.translate('login_subtitle_signup'),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Error Message
                          if (_errorMessage != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // Username Field
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: LocalizationService.instance.translate('username'),
                              helperText: LocalizationService.instance.translate('username_no_spaces'),
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.deepPurple),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return LocalizationService.instance.translate('username_required');
                              }
                              final normalized = _normalizeUsername(value);
                              if (normalized.isEmpty) {
                                return LocalizationService.instance.translate('username_required');
                              }
                              if (normalized.length < 3) {
                                return LocalizationService.instance.translate('username_min3');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: LocalizationService.instance.translate('password'),
                              prefixIcon: const Icon(Icons.lock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.deepPurple),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return LocalizationService.instance.translate('password_required');
                              }
                              if (value.length < 6) {
                                return LocalizationService.instance.translate('password_min6');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password (Sign up only)
                          if (!_isLogin)
                            Column(
                              children: [
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: LocalizationService.instance.translate('confirm_password'),
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.deepPurple),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (_isLogin) return null;
                                    if (value == null || value.isEmpty) {
                                      return LocalizationService.instance.translate('confirm_password_required');
                                    }
                                    if (value != _passwordController.text) {
                                      return LocalizationService.instance.translate('passwords_do_not_match');
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                            )
                          else
                            const SizedBox(height: 24),

                          // Auth Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _isLogin
                                          ? LocalizationService.instance.translate('sign_in')
                                          : LocalizationService.instance.translate('sign_up'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Toggle Auth Mode
                          TextButton(
                            onPressed: _isLoading ? null : () {
                              setState(() {
                                _isLogin = !_isLogin;
                                _errorMessage = null;
                              });
                            },
                            child: Text(
                              _isLogin
                                  ? LocalizationService.instance.translate('toggle_to_signup')
                                  : LocalizationService.instance.translate('toggle_to_signin'),
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : Colors.deepPurple,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
