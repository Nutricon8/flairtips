// reset_code_screen.dart
import 'package:flairtips/screens/new_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flairtips/widgets/filled_button.dart';
import 'package:flairtips/utils/api_service.dart';

class ResetCodeScreen extends StatefulWidget {
  final String email;
  
  const ResetCodeScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetCodeScreen> createState() => _ResetCodeScreenState();
}

class _ResetCodeScreenState extends State<ResetCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  bool _isLoading = false;
  bool _resending = false;
  String? _errorMessage;
  String? _successMessage;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendCountdown = 60; // 60 seconds countdown
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
        return true;
      }
      return false;
    });
  }

  String _extractCodeFromInput(String input) {
    // If input contains a URL, extract the code from query parameter
    if (input.contains('reset_password?code=')) {
      final uri = Uri.tryParse(input);
      if (uri != null) {
        return uri.queryParameters['code'] ?? input.trim();
      }
    }
    // If input contains just code= parameter
    else if (input.contains('code=')) {
      final parts = input.split('code=');
      if (parts.length > 1) {
        return parts[1].trim();
      }
    }
    // Otherwise return the trimmed input
    return input.trim();
  }

  Future<void> _verifyCode() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _successMessage = null;
      });

      try {
        // Extract code from input (could be URL or just code)
        final input = codeController.text;
        final extractedCode = _extractCodeFromInput(input);
        
        if (extractedCode.isEmpty) {
          setState(() {
            _errorMessage = 'Please enter a valid code or URL';
          });
          return;
        }

        final result = await verifyResetCode(
          widget.email,
          extractedCode,
        );
        
        if (result['status'] == 1) {
          // Navigate to new password screen with extracted code
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewPasswordScreen(
                resetCode: extractedCode,
                email: widget.email,
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
        }
        
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;
    
    setState(() {
      _resending = true;
      _errorMessage = null;
    });

    try {
      final result = await forgotPassword(widget.email);
      
      if (result['status'] == 1) {
        setState(() {
          _successMessage = 'New code sent to your email';
        });
        _startResendTimer();
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      setState(() {
        _resending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verify Code',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                const Text(
                  'Enter Verification Code',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  'We sent a reset link to ${widget.email}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'You can enter the code or paste the entire reset link',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 40),
                
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Reset Code or URL',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                    hintText: 'Paste code or reset link here',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the reset code or URL';
                    }
                    // Extract code to check minimum length
                    final extractedCode = _extractCodeFromInput(value);
                    if (extractedCode.length < 6) {
                      return 'Code must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Example format
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, 
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Accepted formats:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Code only: lOd8q6ZgMVEoODUD7Ow6VCZrXnnlv9UImLm22y1R',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        '• Full URL: https://flairtips.com/reset_password?code=lOd8q6ZgMVEoODUD7Ow6VCZrXnnlv9UImLm22y1R',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
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
                      ],
                    ),
                  ),
                ],
                
                if (_successMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
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
                  ),
                ],
                
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the link? ",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    if (_resendCountdown > 0)
                      Text(
                        'Resend in ${_resendCountdown}s',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _resending ? null : _resendCode,
                        child: _resending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Resend Link'),
                      ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : AppFilledButton(
                        text: 'Verify Code',
                        onPressed: _verifyCode,
                      ),
                
                const SizedBox(height: 20),
                
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Use Different Email'),
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