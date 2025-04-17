import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:main_draft1/main.dart';
import 'package:intl/intl.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> plan;

  const PaymentPage({super.key, required this.plan});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

// Custom formatter for expiry date (MM/YY)
class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.length > 4) {
      newText = newText.substring(0, 4);
    }

    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      if (i == 2 && newText.length > 2) {
        buffer.write('/');
      }
      buffer.write(newText[i]);
    }

    String formatted = buffer.toString();
    int selectionIndex = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

// Custom formatter for card number (spaces every 4 digits)
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.length > 16) {
      newText = newText.substring(0, 16);
    }

    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(newText[i]);
    }

    String formatted = buffer.toString();
    int selectionIndex = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isProcessing = false;
  bool _obscureCVV = true;

  // Card type detection
  String _cardType = '';
  final Map<String, String> _cardIcons = {
    'visa': '💳',
    'mastercard': '💳',
    'amex': '💳',
    'discover': '💳',
    'unknown': '💳',
  };

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Detect card type based on first digits
  void _detectCardType(String cardNumber) {
    cardNumber = cardNumber.replaceAll(' ', '');

    if (cardNumber.isEmpty) {
      setState(() => _cardType = 'unknown');
      return;
    }

    if (cardNumber.startsWith('4')) {
      setState(() => _cardType = 'visa');
    } else if (RegExp(r'^5[1-5]').hasMatch(cardNumber)) {
      setState(() => _cardType = 'mastercard');
    } else if (RegExp(r'^3[47]').hasMatch(cardNumber)) {
      setState(() => _cardType = 'amex');
    } else if (RegExp(r'^(6011|65|64[4-9])').hasMatch(cardNumber)) {
      setState(() => _cardType = 'discover');
    } else {
      setState(() => _cardType = 'unknown');
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Calculate subscription dates
      final startDate = DateTime.now();
      final endDate =
          startDate.add(Duration(days: widget.plan['plan_duration']));

      // Create subscription record
      await supabase.from('tbl_subscription').insert({
        'user_id': userId,
        'plan_id': widget.plan['id'],
        'start_date': startDate.toIso8601String(),
        'expiry_date': endDate.toIso8601String(),
        'sub_status': 1
      });

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Show success and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to subscription page
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF3949AB), Color(0xFFF5F5F5)],
            stops: [0.0, 0.2, 0.2],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlanSummary(),
                const SizedBox(height: 24),
                _buildPaymentForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanSummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Color(0xFF3949AB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.plan['plan_name'] ?? 'Unknown Plan',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.plan['plan_duration']} days subscription',
                        style: const TextStyle(
                          color: Color(0xFF5C6BC0),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${widget.plan['plan_amount']}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₹${widget.plan['plan_amount']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.credit_card,
                      color: Color(0xFF3949AB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Payment Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Cardholder Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Cardholder Name',
                  hintText: 'John Smith',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF3949AB), width: 2),
                  ),
                  prefixIcon:
                      const Icon(Icons.person, color: Color(0xFF3949AB)),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cardholder name';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                    return 'Name can only contain letters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Card Number Field
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  hintText: '1234 5678 9012 3456',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    // borderSide: const BorderSide(color: ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF3949AB), width: 2),
                  ),
                  prefixIcon:
                      const Icon(Icons.credit_card, color: Color(0xFF3949AB)),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      _cardIcons[_cardType] ?? '💳',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  CardNumberInputFormatter(),
                ],
                onChanged: (value) {
                  _detectCardType(value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter card number';
                  }
                  final cleanValue = value.replaceAll(' ', '');
                  if (cleanValue.length != 16) {
                    return 'Card number must be 16 digits';
                  }
                  if (!RegExp(r'^[0-9]+$').hasMatch(cleanValue)) {
                    return 'Card number can only contain digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Expiry Date and CVV Fields
              Row(
                children: [
                  // Expiry Date (MM/YY)
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _expiryDateController,
                      decoration: InputDecoration(
                        labelText: 'Expiry Date',
                        hintText: 'MM/YY',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFBDBDBD)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF3949AB), width: 2),
                        ),
                        prefixIcon: const Icon(Icons.calendar_month,
                            color: Color(0xFF3949AB)),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        ExpiryDateInputFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                          return 'Invalid format (MM/YY)';
                        }
                        final parts = value.split('/');
                        final month = int.tryParse(parts[0]);
                        final year = int.tryParse(parts[1]);
                        if (month == null || month < 1 || month > 12) {
                          return 'Invalid month';
                        }
                        if (year == null) {
                          return 'Invalid year';
                        }
                        final currentYear = DateTime.now().year % 100;
                        final currentMonth = DateTime.now().month;
                        if (year < currentYear ||
                            (year == currentYear && month < currentMonth)) {
                          return 'Card expired';
                        }
                        if (year > currentYear + 10) {
                          return 'Invalid year';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // CVV
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFBDBDBD)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF3949AB), width: 2),
                        ),
                        prefixIcon:
                            const Icon(Icons.lock, color: Color(0xFF3949AB)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCVV
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF3949AB),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureCVV = !_obscureCVV;
                            });
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: _obscureCVV,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (value.length < 3 || value.length > 4) {
                          return 'Invalid CVV';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Payment Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Pay ₹${widget.plan['plan_amount']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Security Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.security,
                      color: Color(0xFF3949AB),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This is a secure payment. Your card details are encrypted and protected.',
                        style: TextStyle(
                          color: Color(0xFF616161),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Demo Notice
              const Center(
                child: Text(
                  'This is a demo payment gateway. No real payment will be processed.',
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
