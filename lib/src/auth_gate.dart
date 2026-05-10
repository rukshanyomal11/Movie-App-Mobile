import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'movie_shell.dart';
import 'theme.dart';

enum AuthMode { login, register }

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _displayName;

  void _handleAuthenticated(String displayName) {
    setState(() {
      _displayName = displayName;
    });
  }

  void _handleLogout() {
    setState(() {
      _displayName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_displayName != null) {
      return MovieShell(
        displayName: _displayName!,
        onLogout: _handleLogout,
      );
    }

    return AuthScreen(
      onAuthenticated: _handleAuthenticated,
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onAuthenticated,
  });

  final ValueChanged<String> onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  AuthMode _mode = AuthMode.login;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  String? _authError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_mode) {
      AuthMode.login => 'Welcome Back',
      AuthMode.register => 'Create Your Account',
    };
    final subtitle = switch (_mode) {
      AuthMode.login =>
        'Log in to keep your tickets, favorite picks, and movie nights in sync.',
      AuthMode.register =>
        'Join CineBook to book faster and keep every reservation in one place.',
    };

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF11050A),
              Color(0xFF09090E),
              AppColors.background,
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            const _AuthBackdrop(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const _BrandHeader(),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _AuthModeToggle(
                                  mode: _mode,
                                  onChanged: (mode) {
                                    setState(() {
                                      _mode = mode;
                                      _authError = null;
                                    });
                                  },
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium?.copyWith(
                                        fontSize: 28,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  subtitle,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: const Color(0xFFB8B8CA),
                                      ),
                                ),
                                const SizedBox(height: 22),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      key: ValueKey<AuthMode>(_mode),
                                      children: <Widget>[
                                        if (_mode == AuthMode.register) ...<Widget>[
                                          _AuthInputField(
                                            controller: _nameController,
                                            label: 'Full Name',
                                            hint: 'Enter your full name',
                                            prefixIcon:
                                                Icons.person_outline_rounded,
                                            validator: (value) {
                                              if (_mode != AuthMode.register) {
                                                return null;
                                              }
                                              if (value == null ||
                                                  value.trim().length < 2) {
                                                return 'Enter your name';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 14),
                                        ],
                                        _AuthInputField(
                                          controller: _emailController,
                                          label: 'Email',
                                          hint: 'Enter your email',
                                          prefixIcon: Icons.mail_outline_rounded,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: (value) {
                                            final text = value?.trim() ?? '';
                                            if (!text.contains('@') ||
                                                !text.contains('.')) {
                                              return 'Enter a valid email';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                        _AuthInputField(
                                          controller: _passwordController,
                                          label: 'Password',
                                          hint: 'Enter your password',
                                          prefixIcon: Icons.lock_outline_rounded,
                                          obscureText: _obscurePassword,
                                          suffixIcon: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                            ),
                                          ),
                                          validator: (value) {
                                            if ((value ?? '').length < 6) {
                                              return 'Use at least 6 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                        if (_mode == AuthMode.register) ...<Widget>[
                                          const SizedBox(height: 14),
                                          _AuthInputField(
                                            controller: _confirmController,
                                            label: 'Confirm Password',
                                            hint: 'Re-enter your password',
                                            prefixIcon:
                                                Icons.lock_reset_rounded,
                                            obscureText: _obscureConfirm,
                                            suffixIcon: IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  _obscureConfirm =
                                                      !_obscureConfirm;
                                                });
                                              },
                                              icon: Icon(
                                                _obscureConfirm
                                                    ? Icons
                                                        .visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                              ),
                                            ),
                                            validator: (value) {
                                              if (_mode != AuthMode.register) {
                                                return null;
                                              }
                                              if (value !=
                                                  _passwordController.text) {
                                                return 'Passwords do not match';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          child: FilledButton(
                                            onPressed: _isSubmitting
                                                ? null
                                                : _submit,
                                            child: Text(
                                              _isSubmitting
                                                  ? 'Please wait...'
                                                  : _mode == AuthMode.login
                                                      ? 'Log In'
                                                      : 'Create Account',
                                            ),
                                          ),
                                        ),
                                        if (_authError != null) ...<Widget>[
                                          const SizedBox(height: 14),
                                          _AuthFeedbackCard(message: _authError!),
                                        ],
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton(
                                            onPressed: () {
                                              widget.onAuthenticated('Guest');
                                            },
                                            child: const Text(
                                              'Continue as Guest',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Secure authentication powered by Supabase.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: const Color(0xFF8E8FA5),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _authError = null;
    });

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    try {
      if (_mode == AuthMode.register) {
        // 1. Sign up with Supabase Auth
        // We pass the full_name into the user metadata so a database trigger
        // can safely create the app_users record without causing 401 Unauthorized errors.
        final AuthResponse res = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': name,
          },
        );

        if (res.session == null && res.user != null) {
          // Email confirmation is required
          if (mounted) {
            _passwordController.clear();
            _confirmController.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration successful! Please check your email to confirm your account.')),
            );
            setState(() {
              _mode = AuthMode.login;
            });
          }
          return;
        }
      } else {
        // Sign in
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }

      final displayName = _mode == AuthMode.register
          ? name
          : _displayNameFromEmail(email);

      final message = _mode == AuthMode.login
          ? 'Welcome back, $displayName'
          : 'Account created for $displayName';

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));

        widget.onAuthenticated(displayName);
      }
    } on AuthException catch (error) {
      _setAuthError(
        _friendlyAuthMessage(
          error.message,
          mode: _mode,
        ),
      );
    } catch (_) {
      _setAuthError('Authentication failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }



  String _friendlyAuthMessage(
    String message, {
    required AuthMode mode,
  }) {
    final normalizedMessage = message.toLowerCase();

    if (mode == AuthMode.register) {
      if (normalizedMessage.contains('already registered') ||
          normalizedMessage.contains('already exists') ||
          normalizedMessage.contains('user already')) {
        return 'This email already exists. Try another email.';
      }
      if (normalizedMessage.contains('password')) {
        return 'Password must be at least 6 characters.';
      }
    } else {
      if (normalizedMessage.contains('invalid login credentials') ||
          normalizedMessage.contains('invalid credentials')) {
        return 'Wrong email or password. Try again.';
      }
      if (normalizedMessage.contains('email not confirmed')) {
        return 'Please confirm your email before logging in.';
      }
    }

    return message;
  }

  void _setAuthError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _authError = message;
    });
  }

  String _displayNameFromEmail(String email) {
    final username = email.split('@').first.trim();
    if (username.isEmpty) {
      return 'Movie Fan';
    }

    return username[0].toUpperCase() + username.substring(1);
  }
}

class _AuthFeedbackCard extends StatelessWidget {
  const _AuthFeedbackCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.danger),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.danger,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'CineBook',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Your next movie night starts here.',
          style: TextStyle(
            color: Color(0xFFB0B0C1),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}


class _AuthModeToggle extends StatelessWidget {
  const _AuthModeToggle({
    required this.mode,
    required this.onChanged,
  });

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _AuthTogglePill(
              label: 'Log In',
              selected: mode == AuthMode.login,
              onTap: () => onChanged(AuthMode.login),
            ),
          ),
          Expanded(
            child: _AuthTogglePill(
              label: 'Register',
              selected: mode == AuthMode.register,
              onTap: () => onChanged(AuthMode.register),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTogglePill extends StatelessWidget {
  const _AuthTogglePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.textPrimary : AppColors.textMuted,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AuthInputField extends StatelessWidget {
  const _AuthInputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: AppColors.textMuted,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF6F7086),
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: AppColors.textMuted,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF12131A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -40,
            right: -20,
            child: _GlowOrb(
              size: 170,
              color: const Color(0x66F51C5B),
            ),
          ),
          Positioned(
            top: 240,
            left: -60,
            child: _GlowOrb(
              size: 210,
              color: const Color(0x33FFAD66),
            ),
          ),
          Positioned(
            bottom: 90,
            right: -30,
            child: _GlowOrb(
              size: 180,
              color: const Color(0x222882FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}
