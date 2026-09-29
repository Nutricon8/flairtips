import 'package:flairtips/utils/api_service.dart';
import 'package:flairtips/widgets/filled_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _errorMessage;
  String? _successMessage;
  
  // Focus nodes
  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
    });
    
    // Set up focus node listeners for validation
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    _fullNameFocus.addListener(() {
      if (!_fullNameFocus.hasFocus && fullNameController.text.isNotEmpty) {
        _formKey.currentState?.validate();
      }
    });
    
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus && emailController.text.isNotEmpty) {
        _formKey.currentState?.validate();
      }
    });
    
    _passwordFocus.addListener(() {
      if (!_passwordFocus.hasFocus && passwordController.text.isNotEmpty) {
        _formKey.currentState?.validate();
      }
    });
    
    _confirmPasswordFocus.addListener(() {
      if (!_confirmPasswordFocus.hasFocus && confirmPasswordController.text.isNotEmpty) {
        _formKey.currentState?.validate();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> handleRegister() async {
    if (_formKey.currentState!.validate()) {
      // Check password match
      if (passwordController.text != confirmPasswordController.text) {
        _showError('Passwords do not match');
        return;
      }

      // Dismiss keyboard
      FocusScope.of(context).unfocus();
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _successMessage = null;
      });

      try {
        final result = await registerUser(
          fullName: fullNameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        if (result['status'] == 1) {
          // Show success message
          _showSuccess(result['message'] ?? 'Registration successful!');
          
          // Navigate to login after delay
          await Future.delayed(const Duration(milliseconds: 1500));
          
          if (mounted) {
            Navigator.pushReplacementNamed(context, "/login");
          }
        } else {
          _showError(result['message'] ?? 'Registration failed');
        }
      } catch (e) {
        final errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _showError(errorMessage);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _successMessage = null;
    });
    
    // Auto-hide error after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  void _showSuccess(String message) {
    setState(() {
      _successMessage = message;
      _errorMessage = null;
    });
  }

  void _clearMessages() {
    if (_errorMessage != null || _successMessage != null) {
      setState(() {
        _errorMessage = null;
        _successMessage = null;
      });
    }
  }

  Widget _buildMessageDisplay() {
    if (_successMessage != null) {
      return _buildSuccessMessage();
    } else if (_errorMessage != null) {
      return _buildErrorMessage();
    }
    return const SizedBox.shrink();
  }

  Widget _buildErrorMessage() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade600, size: 16),
            onPressed: _clearMessages,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _successMessage!,
              style: TextStyle(
                color: Colors.green.shade800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                child: Text(
                  'Create Account 👋',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            );
          },
        ),
        automaticallyImplyLeading: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  
                  // Message display
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildMessageDisplay(),
                  ),
                  
                  if (_errorMessage != null || _successMessage != null)
                    const SizedBox(height: 16),
                  
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isLoading ? _buildLoadingOverlay() : _buildFormFields(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Creating your account...',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: fullNameController,
          focusNode: _fullNameFocus,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: "Full Name",
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.person_outline),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          validator: (value) => value == null || value.isEmpty
              ? "Please enter your full name"
              : null,
          onChanged: (_) => _clearMessages(),
          onEditingComplete: () {
            FocusScope.of(context).requestFocus(_emailFocus);
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: emailController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: "Email Address",
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.email_outlined),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(
              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
            ).hasMatch(value)) {
              return 'Enter a valid email address';
            }
            return null;
          },
          onChanged: (_) => _clearMessages(),
          onEditingComplete: () {
            FocusScope.of(context).requestFocus(_passwordFocus);
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: passwordController,
          focusNode: _passwordFocus,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          onChanged: (_) => _clearMessages(),
          onEditingComplete: () {
            FocusScope.of(context).requestFocus(_confirmPasswordFocus);
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          obscureText: !_isConfirmPasswordVisible,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          validator: (value) => value == null || value.isEmpty
              ? "Please confirm your password"
              : null,
          onChanged: (_) => _clearMessages(),
          onEditingComplete: handleRegister,
        ),
        const SizedBox(height: 20),
        AppFilledButton(
          text: 'Sign Up',
          onPressed: _isLoading ? null : handleRegister,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 20),
        Center(
          child: RichText(
            text: TextSpan(
              text: "Already have an account?",
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: ' Sign in',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = _isLoading
                        ? null
                        : () {
                            Navigator.pushNamed(context, "/login");
                          },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}