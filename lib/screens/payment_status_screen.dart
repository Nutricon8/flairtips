import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flairtips/utils/api_service.dart';
import 'package:flairtips/utils/user_provider.dart';
import 'package:flairtips/widgets/filled_button.dart';
import 'package:provider/provider.dart';

class PaymentStatusScreen extends StatefulWidget {
  final String merchantRequestId;
  final String checkoutRequestId;
  final int planId;
  final String phoneNumber;

  const PaymentStatusScreen({
    super.key,
    required this.merchantRequestId,
    required this.checkoutRequestId,
    required this.planId,
    required this.phoneNumber,
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  bool _isLoading = true;
  bool _isPolling = true;
  bool _isSuccess = false;
  bool _isFailed = false;
  String _statusMessage = 'Checking payment status...';
  String? _mpesaReceiptNumber;
  double? _amount;
  String? _transactionDate;
  int _pollingAttempts = 0;
  final int _maxPollingAttempts = 20;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _checkStatus();

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pollingAttempts >= _maxPollingAttempts) {
        timer.cancel();
        setState(() {
          _isPolling = false;
          _isLoading = false;
          _statusMessage = 'Payment check timeout. Please verify manually.';
        });
        return;
      }

      if (!_isSuccess && !_isFailed && mounted) {
        _checkStatus();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;

    setState(() {
      _pollingAttempts++;
    });

    try {
      // Get recent payments from api_service.dart
      final recentPayments = await getRecentPayments();

      // Look for our payment
      for (final payment in recentPayments) {
        final paymentPhone = payment['phone']?.toString() ?? '';
        final ourPhone = widget.phoneNumber;

        // Check if phone matches
        if (paymentPhone == ourPhone) {
          // Found our payment!
          _pollingTimer?.cancel();

          setState(() {
            _isLoading = false;
            _isPolling = false;
            _isSuccess = true;
            _mpesaReceiptNumber = payment['transaction_id'];
            _amount = double.tryParse(payment['amount']?.toString() ?? '0');
            _transactionDate = payment['deposit_date'];
            _statusMessage = 'Payment Successful!';
          });

          // Update subscription status
          _updateSubscriptionAfterPayment();

          return; // Stop checking
        }
      }

      // No match found yet
      setState(() {
        if (_pollingAttempts >= _maxPollingAttempts) {
          _isPolling = false;
          _isLoading = false;
          _statusMessage = 'Payment not found.\nPlease check your M-PESA.';
        } else {
          _statusMessage = 'Checking... (${_pollingAttempts * 5}s)';
        }
      });
    } catch (e) {
      print('Error: $e');

      if (_pollingAttempts >= _maxPollingAttempts) {
        setState(() {
          _isPolling = false;
          _isLoading = false;
          _statusMessage = 'Unable to verify payment.\nPlease check manually.';
        });
      }
    }
  }

  Future<void> _updateSubscriptionAfterPayment() async {
    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.updateSubscriptionStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Premium access activated!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      print('Subscription updated after payment');
    } catch (e) {
      print('Error updating subscription after payment: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment successful! Please restart app to see premium access.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _retryPolling() {
    setState(() {
      _isLoading = true;
      _isPolling = true;
      _pollingAttempts = 0;
      _statusMessage = 'Checking payment status...';
    });
    _startPolling();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isPolling ? null : () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStatusColor().withOpacity(0.3),
              ),
              child: Icon(_getStatusIcon(), size: 60, color: _getStatusColor()),
            ),

            const SizedBox(height: 30),

            Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            if (_isPolling) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 10),
              Text(
                'Attempt $_pollingAttempts of $_maxPollingAttempts',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
            ],

            if (_isSuccess && _mpesaReceiptNumber != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      Theme.of(
                        context,
                      ).colorScheme.surface, //Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Receipt Number', _mpesaReceiptNumber!),
                    if (_amount != null)
                      _buildDetailRow('Amount', 'KES $_amount'),
                    if (_transactionDate != null)
                      _buildDetailRow('Date', _formatDate(_transactionDate!)),
                    _buildDetailRow('Phone', widget.phoneNumber),
                    _buildDetailRow('Plan', _getPlanName(widget.planId)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (!_isPolling) ...[
              if (_isFailed)
                AppFilledButton(text: 'Try Again', onPressed: _retryPolling),

              if (_isSuccess)
                AppFilledButton(
                  text: 'Continue to App',
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                    Navigator.pushReplacementNamed(context, '/main');
                  },
                ),

              if (!_isSuccess && !_isFailed)
                AppFilledButton(text: 'Check Again', onPressed: _retryPolling),
            ],

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reference Information:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Merchant ID', widget.merchantRequestId),
                  _buildDetailRow('Checkout ID', widget.checkoutRequestId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      if (dateStr.length == 14) {
        final year = dateStr.substring(0, 4);
        final month = dateStr.substring(4, 6);
        final day = dateStr.substring(6, 8);
        final hour = dateStr.substring(8, 10);
        final minute = dateStr.substring(10, 12);
        return '$day/$month/$year $hour:$minute';
      }
    } catch (e) {
      print('Error formatting date: $e');
    }
    return dateStr;
  }

  String _getPlanName(int planId) {
    switch (planId) {
      case 0:
        return 'Daily Plan';
      case 1:
        return 'Weekly Plan';
      case 2:
        return 'Monthly Plan';
      default:
        return 'Premium Plan';
    }
  }

  Color _getStatusColor() {
    if (_isSuccess) return Colors.green;
    if (_isFailed) return Colors.red;
    if (_isPolling) return Colors.blue;
    return Colors.orange;
  }

  IconData _getStatusIcon() {
    if (_isSuccess) return Icons.check_circle;
    if (_isFailed) return Icons.error;
    if (_isPolling) return Icons.hourglass_empty;
    return Icons.pending;
  }
}
