import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const CheckoutScreen({super.key, required this.product});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedPayment = 'Cash on Delivery (COD)';
  bool _isSubmitting = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _altPhoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _customCityController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  final List<String> _cities = [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Peshawar',
    'Quetta',
    'Gujranwala',
    'Sialkot',
    'Hyderabad',
    'Sukkur',
    'Bahawalpur',
    'Abbottabad',
    'Other',
  ];
  String _selectedCity = 'Karachi';

  @override
  void initState() {
    super.initState();
    _prefillUserData();
  }

  void _prefillUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final meta = user.userMetadata;
      if (meta != null &&
          meta['full_name'] != null &&
          meta['full_name'].toString().isNotEmpty) {
        _nameController.text = meta['full_name'].toString();
      }
      if (user.phone != null && user.phone!.isNotEmpty) {
        _phoneController.text = user.phone!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _addressController.dispose();
    _customCityController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint, {IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: const Color(0xffFF5722), size: 20)
          : null,
      filled: true,
      fillColor: const Color(0xff252525),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xffFF5722), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.product['name'] ?? 'Product';
    final price = double.tryParse(widget.product['price'].toString()) ?? 1200.0;
    const deliveryFee = 200.0;

    // Spec: convenience fee of 2% on orders > 5,000
    final convenienceFee = price > 5000 ? price * 0.02 : 0.0;
    final total = price + deliveryFee + convenienceFee;

    // Self-ordering prevention check
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final sellerId = widget.product['seller_id'];
    final isOwnProduct =
        currentUserId != null && sellerId != null && currentUserId == sellerId;

    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Color(0xff1e1e1e)
            : Colors.white,
        title: Text('Confirm Order',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Self-order warning if applicable
              if (isOwnProduct)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.redAccent, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You are the seller of this product. You cannot purchase items from your own store.',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              // Buyer Protection Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user, color: Colors.green, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Buyer Protection Enabled\nYour contact and delivery details will be safely shared with the courier & seller for prompt delivery.',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Item summary card
              Text('Item Summary',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Color(0xff1e1e1e)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xffFF5722).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined,
                          color: Color(0xffFF5722)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            'Qty: ${widget.product['quantity'] ?? 1}${widget.product['size'] != null ? ' | Size: ${widget.product['size']}' : ''}${widget.product['color'] != null ? ' | Color: ${widget.product['color']}' : ''}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text('₨ ${price.toStringAsFixed(0)}',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Delivery Form Section
              Row(
                children: const [
                  Icon(Icons.local_shipping_outlined,
                      color: Color(0xffFF5722), size: 20),
                  SizedBox(width: 8),
                  Text('Delivery Details',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Color(0xff1e1e1e)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipient Name
                    Text('Full Name / Recipient *',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13),
                      decoration: _inputDecoration('e.g. Muhammad Ali',
                          prefixIcon: Icons.person_outline),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty)
                          return 'Please enter recipient name';
                        if (val.trim().length < 2) return 'Name too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Phone Number
                    Text('Mobile Number *',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13),
                      decoration: _inputDecoration(
                          '0300 1234567 (for courier rider)',
                          prefixIcon: Icons.phone_android),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty)
                          return 'Please enter mobile number';
                        final cleaned = val.replaceAll(RegExp(r'[^0-9]'), '');
                        if (cleaned.length < 10)
                          return 'Enter a valid 11-digit mobile number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Alt Phone / WhatsApp
                    Text('Alternate / WhatsApp Number (Optional)',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _altPhoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13),
                      decoration: _inputDecoration(
                          '03xx xxxxxxx (backup contact)',
                          prefixIcon: Icons.chat_bubble_outline),
                    ),
                    const SizedBox(height: 14),

                    // City Selector
                    Text('City *',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xff252525),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCity,
                          isExpanded: true,
                          dropdownColor: const Color(0xff252525),
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: Color(0xffFF5722)),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 13),
                          items: _cities.map((city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(city),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _selectedCity = val);
                          },
                        ),
                      ),
                    ),

                    if (_selectedCity == 'Other') ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _customCityController,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13),
                        decoration: _inputDecoration('Enter your city name'),
                        validator: (val) {
                          if (_selectedCity == 'Other' &&
                              (val == null || val.trim().isEmpty)) {
                            return 'Please specify your city';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Complete Address
                    Text('Complete Delivery Address *',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13),
                      decoration: _inputDecoration(
                        'House/Flat #, Street #, Sector/Area',
                        prefixIcon: Icons.home_outlined,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty)
                          return 'Please enter complete street address';
                        if (val.trim().length < 8)
                          return 'Please provide full house/street details';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Nearest Landmark / Delivery instructions
                    Text('Nearest Landmark / Instructions (Optional)',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _instructionsController,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13),
                      decoration: _inputDecoration(
                          'e.g. Near Bilal Masjid, call before arrival',
                          prefixIcon: Icons.notes_outlined),
                    ),

                    const Divider(color: Colors.white10, height: 28),
                    const Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.grey, size: 16),
                        SizedBox(width: 8),
                        Text('Estimated Delivery: 2-3 Business Days — ₨ 200',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Options
              Text('Select Payment Method',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildPaymentRadio('Cash on Delivery (COD)',
                  'Pay cash when rider delivers to your doorstep'),
              _buildPaymentRadio(
                  'Pay Now (Card/Wallet)', 'Direct secure digital checkout'),
              const SizedBox(height: 24),

              // Order Cost breakdowns
              Text('Order Pricing Summary',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildBreakdownRow('Product Subtotal', price),
              _buildBreakdownRow('Courier Delivery Fee', deliveryFee),
              if (convenienceFee > 0)
                _buildBreakdownRow(
                    'Buyer convenience fee (2%)', convenienceFee),
              const Divider(color: Colors.white10, height: 24),
              _buildBreakdownRow('Total Amount', total, isBold: true),

              const SizedBox(height: 32),

              // Place Order button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isOwnProduct ? Colors.grey : const Color(0xffFF5722),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: (isOwnProduct || _isSubmitting)
                      ? null
                      : () => _handlePlaceOrder(),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Place Order (${_selectedPayment.contains('COD') ? 'COD' : 'Pay Online'})',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePlaceOrder() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required delivery fields.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final finalCity = _selectedCity == 'Other'
        ? _customCityController.text.trim()
        : _selectedCity;
    final buyerName = _nameController.text.trim();
    final buyerPhone = _phoneController.text.trim();
    final buyerAltPhone = _altPhoneController.text.trim();
    final deliveryAddress = _addressController.text.trim();
    final deliveryInstructions = _instructionsController.text.trim();
    final String method = _selectedPayment.contains('COD') ? 'COD' : 'PAY_NOW';

    bool success = true;
    String errorMessage = '';

    try {
      if (widget.product.containsKey('items') &&
          widget.product['items'] != null) {
        final items = widget.product['items'] as List;
        for (var item in items) {
          final response = await ApiService.createOrder(
            item['id'],
            item['quantity'] ?? 1,
            method,
            size: item['size'],
            color: item['color'],
            buyerName: buyerName,
            buyerPhone: buyerPhone,
            buyerAltPhone: buyerAltPhone.isNotEmpty ? buyerAltPhone : null,
            deliveryAddress: deliveryAddress,
            city: finalCity,
            deliveryInstructions:
                deliveryInstructions.isNotEmpty ? deliveryInstructions : null,
          );
          if (response.statusCode != 200) {
            success = false;
            errorMessage = response.body;
          }
        }
      } else if (widget.product.containsKey('id')) {
        final qty = widget.product['quantity'] ?? 1;
        final response = await ApiService.createOrder(
          widget.product['id'],
          qty,
          method,
          size: widget.product['size'],
          color: widget.product['color'],
          buyerName: buyerName,
          buyerPhone: buyerPhone,
          buyerAltPhone: buyerAltPhone.isNotEmpty ? buyerAltPhone : null,
          deliveryAddress: deliveryAddress,
          city: finalCity,
          deliveryInstructions:
              deliveryInstructions.isNotEmpty ? deliveryInstructions : null,
        );
        if (response.statusCode != 200) {
          success = false;
          errorMessage = response.body;
        }
      } else {
        success = false;
        errorMessage = 'Product information missing.';
      }
    } catch (e) {
      success = false;
      errorMessage = e.toString();
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Color(0xff1e1e1e)
              : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Order Confirmed!',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your order has been placed successfully. The seller has received your contact and delivery address.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deliver to: $buyerName',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('$deliveryAddress, $finalCity',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text('Contact: $buyerPhone',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffFF5722),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context); // close alert dialog
                Navigator.pop(
                    context, true); // close checkout screen with success result
              },
              child: Text('Done',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $errorMessage'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildPaymentRadio(String method, String subtitle) {
    final isSelected = _selectedPayment == method;
    return InkWell(
      onTap: () => setState(() => _selectedPayment = method),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Color(0xff1e1e1e)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected ? const Color(0xffFF5722) : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xffFF5722) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? Colors.white : Colors.grey,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 14 : 13,
            ),
          ),
          Text(
            '₨ ${val.toStringAsFixed(0)}',
            style: TextStyle(
              color: isBold ? const Color(0xffFF5722) : Colors.white,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
