import 'package:flairtips/models/user.dart';
import 'package:flairtips/screens/payment_status_screen.dart';
import 'package:flairtips/utils/api_service.dart';
import 'package:flairtips/utils/user_provider.dart';
import 'package:flairtips/widgets/filled_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PaymentScreen extends StatefulWidget {
  final int planId;
  const PaymentScreen({required this.planId, super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _errorMessage;
  String? _successMessage;
  
  // Focus node for better UX
  final FocusNode _phoneFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    
    // Start animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
      }
    });
    
    // Set up focus node listener
    _phoneFocus.addListener(() {
      if (!_phoneFocus.hasFocus && _phoneController.text.isNotEmpty) {
        _formKey.currentState?.validate();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final input = value.trim();
    
    // Accept formats: 07XXXXXXXX (10 digits starting with 07)
    // or 2547XXXXXXXX (12 digits starting with 2547)
    final pattern = RegExp(r'^(07\d{8}|2547\d{8})$');

    if (!pattern.hasMatch(input)) {
      return 'Enter a valid phone number\n(07XXXXXXXX or 2547XXXXXXXX)';
    }

    return null;
  }

  String _formatPhoneNumber(String phone) {
    final cleanPhone = phone.trim();
    
    // If starts with 07, convert to 254 format
    if (cleanPhone.startsWith('07')) {
      return '254${cleanPhone.substring(1)}';
    }
    
    // If starts with 2547, return as is
    if (cleanPhone.startsWith('2547')) {
      return cleanPhone;
    }
    
    // For any other format, try to clean it
    // Remove any non-digit characters
    final digitsOnly = cleanPhone.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.startsWith('7') && digitsOnly.length == 9) {
      return '254$digitsOnly';
    } else if (digitsOnly.startsWith('07') && digitsOnly.length == 10) {
      return '254${digitsOnly.substring(1)}';
    }
    
    return cleanPhone;
  }

  Future<void> _submitPayment(int userId) async {
    if (_formKey.currentState?.validate() ?? false) {
      // Dismiss keyboard
      FocusScope.of(context).unfocus();
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _successMessage = null;
      });

      try {
        final rawPhone = _phoneController.text.trim();
        final formattedPhone = _formatPhoneNumber(rawPhone);
        
        // Call initiatePayment from api_service
        final result =await initiatePayment(
          planId: widget.planId,
          phone: formattedPhone,
          userId: userId,
        );
        
        // Since initiatePayment throws on non-200, we know it was successful
        _showSuccess('Payment request sent! Check your phone for STK Push.');

        // In a real app, you might want to poll for payment status here
        // For now, just show success and reset after delay
        await Future.delayed(const Duration(seconds: 3));
        
        // Extract merchant and checkout IDs
      final merchantRequestId = result['result']['MerchantRequestID'];
      final checkoutRequestId = result['result']['CheckoutRequestID'];
      
      // Navigate to payment status screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentStatusScreen(
            merchantRequestId: merchantRequestId,
            checkoutRequestId: checkoutRequestId,
            planId: widget.planId,
            phoneNumber: formattedPhone,
          ),
        ),
      );
        
      } catch (e) {
        final errorMessage = e.toString();
        
        // Extract meaningful error message
        String displayError;
        if (errorMessage.contains('Invalid PhoneNumber')) {
          displayError = 'Invalid phone number. Please use format: 07XXXXXXXX or 2547XXXXXXXX';
        } else if (errorMessage.contains('Server error')) {
          displayError = errorMessage.replaceAll('Exception: Server error: ', '');
        } else {
          displayError = errorMessage.replaceAll('Exception: ', '');
        }
        
        _showError(displayError);
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
      margin: const EdgeInsets.only(bottom: 16),
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
      margin: const EdgeInsets.only(bottom: 16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Request Sent',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _successMessage!,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check your phone to complete the payment.',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dialog to show full details
void _showPaymentDetailsDialog(BuildContext context, Map<String, dynamic> result) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Payment Response'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Full Response:', style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              )),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  result.toString(),
                  style: const TextStyle(
                    fontFamily: 'Monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Instructions',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '1. Enter your M-PESA registered phone number\n'
            '2. Tap "Pay Now"\n'
            '3. Check your phone for STK Push\n'
            '4. Enter your M-PESA PIN to complete payment',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: true);
    final user = userProvider.user;

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
                  'Pay KES ${_getPlanAmount(widget.planId)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment info section
                    _buildPaymentInfo(),
                    
                    // Message display
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildMessageDisplay(),
                    ),
                    
                    // Loading overlay or form
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isLoading ? _buildLoadingOverlay() : _buildFormFields(user),
                    ),
                  ],
                ),
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
                'Processing Payment...',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we send payment request',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildFormFields(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plan information
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.diamond,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPlanName(widget.planId),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPlanDescription(widget.planId),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'KES ${_getPlanAmount(widget.planId)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Phone input field
        Text(
          'M-PESA Phone Number',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          focusNode: _phoneFocus,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Enter 07XXXXXXXX or 2547XXXXXXXX',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.phone_android),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          validator: validatePhone,
          onChanged: (_) => _clearMessages(),
          onEditingComplete: () {
            if (user != null) {
              final isValid = _formKey.currentState?.validate() ?? false;
              if (isValid) {
                _submitPayment(int.parse(user.id));
              }
            }
          },
        ),
        
        // Format hint
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text(
            'Use the phone number registered with M-PESA',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        
        const SizedBox(height: 30),
        
        // User info (optional)
        if (user != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Payment button
        AppFilledButton(
          text: 'Pay KES ${_getPlanAmount(widget.planId)}',
          onPressed: (user == null || _isLoading)
              ? null
              : () => _submitPayment(int.parse(user.id)),
          isLoading: _isLoading,
        ),
        
        const SizedBox(height: 16),
        
        // Note about payment
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade600,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You will receive an STK Push on your phone to authorize the payment.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Terms and conditions
        Center(
          child: Text(
            'By proceeding, you agree to our Terms of Service',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  // Helper methods for plan information
  String _getPlanName(int planId) {
    switch (planId) {
      case 0:
        return 'Daily Premium';
      case 1:
        return 'Weekly Premium';
      case 2:
        return 'Monthly Premium';
      default:
        return 'Premium Plan';
    }
  }

  String _getPlanDescription(int planId) {
    switch (planId) {
      case 0:
        return 'Access premium tips for 24 hours';
      case 1:
        return 'Access premium tips for 7 days';
      case 2:
        return 'Access premium tips for 30 days';
      default:
        return 'Access premium betting tips';
    }
  }

  double _getPlanAmount(int planId) {
    switch (planId) {
      case 0:
        return 50.00;
      case 1:
        return 300.00;
      case 2:
        return 1000.00;
      default:
        return 50.00;
    }
  }
}