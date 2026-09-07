import 'package:flutter/material.dart';
import '../../services/firebase_auth_service.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/animated_pressable.dart';

class AuthDialog extends StatefulWidget {
  final FirebaseAuthService authService;

  const AuthDialog({Key? key, required this.authService}) : super(key: key);

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  bool _isSignUp = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await widget.authService.signUpWithEmail(email, password);
      } else {
        await widget.authService.signInWithEmail(email, password);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _signInAsGuest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.signInAnonymously();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF09090B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  gradient: AppColors.primeBlueGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_sync, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 14),
              const Text(
                'Prime Cloud Sync',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Sync your bookmarks and tabs across all devices',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),

              // Mode Switcher (Sign In vs Register)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isSignUp = false;
                          _errorMessage = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isSignUp
                                ? (isDark ? const Color(0xFF27272A) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !_isSignUp
                                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: !_isSignUp ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isSignUp = true;
                          _errorMessage = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isSignUp
                                ? (isDark ? const Color(0xFF27272A) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isSignUp
                                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _isSignUp ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Error Banner
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18181B) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 16, color: isDark ? Colors.white70 : Colors.black87),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),

              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 18),

              // Primary Action Button
              AnimatedPressable(
                onTap: _isLoading ? null : _submit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primeBlueGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isSignUp ? 'Create Account' : 'Sign In',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Quick 1-Tap Guest Sign In
              TextButton.icon(
                onPressed: _isLoading ? null : _signInAsGuest,
                icon: const Icon(Icons.person_outline, size: 18),
                label: const Text('1-Tap Guest Sign-in (Test Mode)', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
