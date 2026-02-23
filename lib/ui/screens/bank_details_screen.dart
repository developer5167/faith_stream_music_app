import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/payout/payout_bloc.dart';
import '../../blocs/payout/payout_event.dart';
import '../../blocs/payout/payout_state.dart';
import '../../models/payout.dart';
import '../../utils/constants.dart';

class BankDetailsScreen extends StatefulWidget {
  final ArtistBankDetails? existingDetails;

  const BankDetailsScreen({super.key, this.existingDetails});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _paymentType = 'UPI';

  // UPI
  final _upiController = TextEditingController();
  // Bank
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountNameController = TextEditingController();
  // Common
  final _panController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final d = widget.existingDetails;
    if (d != null) {
      _paymentType = d.paymentType;
      _upiController.text = d.upiId ?? '';
      _accountNumberController.text = d.accountNumber ?? '';
      _ifscController.text = d.ifscCode ?? '';
      _accountNameController.text = d.accountName ?? '';
      _panController.text = d.panNumber ?? '';
    }
  }

  @override
  void dispose() {
    _upiController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _accountNameController.dispose();
    _panController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PayoutBloc, PayoutState>(
      listener: (context, state) {
        if (state is PayoutActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green.shade700,
            ),
          );
          Navigator.pop(context);
        }
        if (state is PayoutError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSaving = state is PayoutActionInProgress;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              widget.existingDetails != null
                  ? 'Update Bank Details'
                  : 'Add Bank Details',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoBanner(),
                  const SizedBox(height: 24),

                  // Payment Type Toggle
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentTypeToggle(),
                  const SizedBox(height: 24),

                  // Fields based on type
                  if (_paymentType == 'UPI') ...[
                    _buildField(
                      controller: _upiController,
                      label: 'UPI ID',
                      hint: 'yourname@upi',
                      icon: Icons.qr_code,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'UPI ID is required' : null,
                    ),
                  ] else ...[
                    _buildField(
                      controller: _accountNameController,
                      label: 'Account Holder Name',
                      hint: 'As per bank records',
                      icon: Icons.person,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Account name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _accountNumberController,
                      label: 'Account Number',
                      hint: 'Enter bank account number',
                      icon: Icons.account_balance,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Account number is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _ifscController,
                      label: 'IFSC Code',
                      hint: 'e.g. SBIN0001234',
                      icon: Icons.code,
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'IFSC is required' : null,
                    ),
                  ],

                  const SizedBox(height: 16),
                  _buildField(
                    controller: _panController,
                    label: 'PAN Number (optional)',
                    hint: 'e.g. ABCDE1234F',
                    icon: Icons.credit_card,
                    textCapitalization: TextCapitalization.characters,
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B21A8),
                        disabledBackgroundColor: Colors.grey.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF818CF8), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your payment details are encrypted and secure. Payouts are processed within 2–5 business days after admin approval.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleOption('UPI', Icons.qr_code_2)),
          Expanded(child: _buildToggleOption('BANK', Icons.account_balance)),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String type, IconData icon) {
    final isSelected = _paymentType == type;
    return GestureDetector(
      onTap: () => setState(() => _paymentType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B21A8) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 8),
            Text(
              type == 'UPI' ? 'UPI' : 'Bank Transfer',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6B21A8)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        errorStyle: const TextStyle(color: Colors.red),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final details = ArtistBankDetails(
      artistUserId: '',
      paymentType: _paymentType,
      upiId: _paymentType == 'UPI' ? _upiController.text.trim() : null,
      accountNumber: _paymentType == 'BANK'
          ? _accountNumberController.text.trim()
          : null,
      ifscCode: _paymentType == 'BANK'
          ? _ifscController.text.trim().toUpperCase()
          : null,
      accountName: _paymentType == 'BANK'
          ? _accountNameController.text.trim()
          : null,
      panNumber: _panController.text.trim().isEmpty
          ? null
          : _panController.text.trim().toUpperCase(),
    );

    context.read<PayoutBloc>().add(PayoutSaveBankDetails(details));
  }
}
