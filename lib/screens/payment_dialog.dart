import 'package:flutter/material.dart';
import '../models/sale.dart';

class PaymentDialog extends StatefulWidget {
  final double total;
  final List<SaleItem> cartItems;
  final Function(
    String customerName,
    String customerPhone,
    PaymentMethod paymentMethod,
    String? notes,
  )
  onPayment;

  const PaymentDialog({
    super.key,
    required this.total,
    required this.cartItems,
    required this.onPayment,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      child: Container(
        width: isMobile ? MediaQuery.of(context).size.width * 0.9 : 500,
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment Details',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, size: isMobile ? 20 : 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...widget.cartItems.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.productName} × ${item.quantity}',
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 14,
                                    ),
                                  ),
                                  Text(
                                    '₹${item.total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal:',
                                style: TextStyle(fontSize: isMobile ? 12 : 14),
                              ),
                              Text(
                                '₹${widget.total.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: isMobile ? 12 : 14),
                              ),
                            ],
                          ),

                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Customer Details',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customerNameController,
                    decoration: InputDecoration(
                      labelText: 'Customer Name',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person, size: isMobile ? 20 : 24),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isMobile ? 10 : 12,
                      ),
                    ),
                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter customer name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customerPhoneController,
                    decoration: InputDecoration(
                      labelText: 'Customer Phone (Optional)',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone, size: isMobile ? 20 : 24),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isMobile ? 10 : 12,
                      ),
                    ),
                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children:
                        PaymentMethod.values.map((method) {
                          return ChoiceChip(
                            label: Text(
                              _getPaymentMethodLabel(method),
                              style: TextStyle(fontSize: isMobile ? 12 : 14),
                            ),
                            selected: _selectedPaymentMethod == method,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedPaymentMethod = method;
                                });
                              }
                            },
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note, size: isMobile ? 20 : 24),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isMobile ? 10 : 12,
                      ),
                    ),
                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(fontSize: isMobile ? 12 : 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              widget.onPayment(
                                _customerNameController.text.trim(),
                                _customerPhoneController.text.trim(),
                                _selectedPaymentMethod,
                                _notesController.text.trim().isEmpty
                                    ? null
                                    : _notesController.text.trim(),
                              );
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 10 : 12,
                            ),
                          ),
                          child: Text(
                            'Process Payment',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.wallet:
        return 'Wallet';
    }
  }
}
