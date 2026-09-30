import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../utils/api_service.dart';

class ServicePayment extends StatefulWidget {
  final int planId;
  final String planName;
  final double amount;

  const ServicePayment({
    Key? key,
    required this.planId,
    required this.planName,
    required this.amount,
  }) : super(key: key);

  @override
  State<ServicePayment> createState() => _ServicePaymentState();
}

class _ServicePaymentState extends State<ServicePayment> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isProcessing = false;
  String? _paymentStatus;
  String? _transactionId;
  Timer? _statusCheckTimer;
  bool _paymentInitiated = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _paymentStatus = null;
    });

    try {
      final user = Provider.of<User?>(context, listen: false);
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Step 1: Initiate payment
      final response = await initiatePayment(
        planId: widget.planId,
        phone: _phoneController.text.trim(),
        userId: user.id,
      );

      if (response['status'] == 1) {
        final data = response['data'];
        final merchantRequestId = data['MerchantRequestID'];
        final checkoutRequestId = data['CheckoutRequestID'];
        
        setState(() {
          _paymentStatus = 'Payment initiated. Checking status...';
          _paymentInitiated = true;
          _transactionId = checkoutRequestId;
        });

        // Step 2: Start polling for status
        _startStatusPolling(merchantRequestId, checkoutRequestId);
      } else {
        throw Exception(response['message'] ?? 'Payment initiation failed');
      }
    } catch (e) {
      setState(() {
        _paymentStatus = 'Error: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  void _startStatusPolling(String merchantRequestId, String checkoutRequestId) {
    // Cancel any existing timer
    _statusCheckTimer?.cancel();
    
    // Start polling every 5 seconds
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final statusResponse = await checkTransactionStatus(
          merchantRequestId: merchantRequestId,
          checkoutRequestId: checkoutRequestId,
        );

        if (statusResponse['status'] == 1) {
          final resultCode = statusResponse['data']['ResultCode'];
          
          if (resultCode == 0) {
            // Payment successful
            timer.cancel();
            setState(() {
              _paymentStatus = 'Payment successful! Thank you for subscribing.';
              _isProcessing = false;
            });
            
            // Show success dialog
            _showSuccessDialog();
          } else if (resultCode == 1032) {
            // User cancelled
            timer.cancel();
            setState(() {
              _paymentStatus = 'Payment cancelled by user.';
              _isProcessing = false;
              _paymentInitiated = false;
            });
          } else if (resultCode == 1037) {
            // Payment timeout
            timer.cancel();
            setState(() {
              _paymentStatus = 'Payment timeout. Please try again.';
              _isProcessing = false;
              _paymentInitiated = false;
            });
          } else if (resultCode == 2001) {
            // Insufficient funds
            timer.cancel();
            setState(() {
              _paymentStatus = 'Insufficient funds. Please check your balance.';
              _isProcessing = false;
              _paymentInitiated = false;
            });
          }
          // Other result codes continue polling
        }
      } catch (e) {
        // Continue polling on error
        print('Status check error: $e');
      }
    });

    // Stop polling after 5 minutes
    Timer(const Duration(minutes: 5), () {
      _statusCheckTimer?.cancel();
      if (_paymentInitiated) {
        setState(() {
          _paymentStatus = 'Payment timeout. Please check with your bank.';
          _isProcessing = false;
          _paymentInitiated = false;
        });
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful'),
        content: const Text('Your subscription has been activated successfully. You can now access premium tips.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Also pop the payment screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscribe Now'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan Info Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.planName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'KES ${widget.amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Get access to all premium predictions, detailed analysis, and expert insights.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Phone Number Input
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'MPesa Phone Number',
                  hintText: '07XXXXXXXX',
                  prefixText: '+254 ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  final phone = value.trim();
                  if (!phone.startsWith('07') || phone.length != 10) {
                    return 'Please enter a valid Kenyan phone number (07XXXXXXXX)';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Payment Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing || _paymentInitiated ? null : _initiatePayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Pay with MPesa',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Status Display
              if (_paymentStatus != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _paymentStatus!.contains('successful')
                        ? Colors.green.shade50
                        : _paymentStatus!.contains('Error') || _paymentStatus!.contains('failed')
                            ? Colors.red.shade50
                            : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _paymentStatus!.contains('successful')
                          ? Colors.green.shade200
                          : _paymentStatus!.contains('Error') || _paymentStatus!.contains('failed')
                              ? Colors.red.shade200
                              : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_paymentStatus!.contains('successful'))
                        const Icon(Icons.check_circle, color: Colors.green),
                      if (_paymentStatus!.contains('Error') || _paymentStatus!.contains('failed'))
                        const Icon(Icons.error, color: Colors.red),
                      if (!_paymentStatus!.contains('successful') && 
                          !_paymentStatus!.contains('Error') && 
                          !_paymentStatus!.contains('failed'))
                        const Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _paymentStatus!,
                          style: TextStyle(
                            color: _paymentStatus!.contains('successful')
                                ? Colors.green.shade800
                                : _paymentStatus!.contains('Error') || _paymentStatus!.contains('failed')
                                    ? Colors.red.shade800
                                    : Colors.blue.shade800,
                          ),
                        ),
                      ),
                      if (_paymentInitiated && !_paymentStatus!.contains('successful'))
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Instructions
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instructions:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('1. Enter your MPesa registered phone number'),
                      Text('2. Click "Pay with MPesa"'),
                      Text('3. Check your phone for MPesa prompt'),
                      Text('4. Enter your MPesa PIN when prompted'),
                      Text('5. Wait for payment confirmation'),
                    ],
                  ),
                ),
              ),
              
              // Transaction ID (if available)
              if (_transactionId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Transaction ID: $_transactionId',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontFamily: 'monospace',
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
