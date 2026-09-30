import 'dart:async';
import 'package:flutter/material.dart';
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
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = '';
  Timer? _statusTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_phoneController.text.isEmpty) {
      setState(() => _statusMessage = 'Please enter phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Initiating payment...';
    });

    try {
      // Step 1: Initiate payment
      final response = await initiatePayment(
        planId: widget.planId,
        phone: _phoneController.text,
        userId: 1, // Replace with actual user ID
      );

      if (response['status'] == 1) {
        final data = response['data'];
        final merchantId = data['MerchantRequestID'];
        final checkoutId = data['CheckoutRequestID'];
        
        setState(() {
          _statusMessage = 'Payment initiated. Checking status...';
        });

        // Step 2: Start checking status
        _checkPaymentStatus(merchantId, checkoutId);
      } else {
        throw Exception(response['message'] ?? 'Payment failed');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _checkPaymentStatus(String merchantId, String checkoutId) async {
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final status = await checkTransactionStatus(
          merchantRequestId: merchantId,
          checkoutRequestId: checkoutId,
        );

        if (status['status'] == 1) {
          final result = status['data']['ResultCode'];
          
          if (result == 0) {
            // Success
            timer.cancel();
            setState(() {
              _statusMessage = 'Payment successful!';
              _isLoading = false;
            });
          } else if (result == 1032) {
            // Cancelled
            timer.cancel();
            setState(() {
              _statusMessage = 'Payment cancelled';
              _isLoading = false;
            });
          }
          // Continue polling for other codes
        }
      } catch (e) {
        print('Status check error: $e');
      }
    });

    // Stop after 2 minutes
    Timer(const Duration(minutes: 2), () {
      _statusTimer?.cancel();
      if (_isLoading) {
        setState(() {
          _statusMessage = 'Payment timeout';
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Plan: ${widget.planName}'),
            Text('Amount: KES ${widget.amount}'),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '07XXXXXXXX',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _processPayment,
              child: _isLoading 
                  ? const CircularProgressIndicator()
                  : const Text('Pay Now'),
            ),
            const SizedBox(height: 20),
            Text(_statusMessage),
          ],
        ),
      ),
    );
  }
}


//usage
/*
// Navigate to payment screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ServicePayment(
      planId: 1,
      planName: 'Premium Monthly',
      amount: 100.0,
    ),
  ),
);
*/
