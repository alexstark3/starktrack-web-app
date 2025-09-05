import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/auth/company_login_screen.dart';
import 'home.dart';

class ContactPage extends StatefulWidget {
  final String? interestedIn;
  
  const ContactPage({super.key, this.interestedIn});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _addressController = TextEditingController();
  final _workersController = TextEditingController();
  final _phoneController = TextEditingController();
  final _interestedInController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the interested in field with the plan if provided
    if (widget.interestedIn != null) {
      _interestedInController.text = widget.interestedIn!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _workersController.dispose();
    _phoneController.dispose();
    _interestedInController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    
    return Home(
      onLogoPressed: () => Navigator.pop(context),
      onHomePressed: () => Navigator.pop(context),
      onFeaturesPressed: () => Navigator.pop(context),
      onPricingPressed: () => Navigator.pop(context),
      onContactPressed: () {}, // Current page
      onLoginPressed: () {
        // Navigate to app login page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CompanyLoginScreen(),
          ),
        );
      },
      onAboutUsPressed: () => Navigator.pop(context),
      content: _buildContactContent(colors),
    );
  }

  Widget _buildContactContent(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo_full.png',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      AppLocalizations.of(context)!.getInTouch,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: colors.textColor.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.haveQuestionsAboutStarkTrack,
                      style: TextStyle(
                        fontSize: 18,
                        color: colors.textColor.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Contact Form
              _buildContactForm(colors),
              
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactForm(AppColors colors) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      decoration: BoxDecoration(
        color: colors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primaryBlue.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colors.textColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.sendUsMessage,
              style: TextStyle(
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.bold,
                color: colors.textColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            
            // Contact Person Section
            Text(
              '${AppLocalizations.of(context)!.contactPerson}:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            // Name Field (Required)
            _buildTextField(
              controller: _nameController,
              label: '${AppLocalizations.of(context)!.name} *',
              hint: AppLocalizations.of(context)!.enterContactPersonName,
              colors: colors,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterContactPersonName;
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Surname Field (Required)
            _buildTextField(
              controller: _surnameController,
              label: '${AppLocalizations.of(context)!.surname} *',
              hint: AppLocalizations.of(context)!.enterContactPersonSurname,
              colors: colors,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterContactPersonSurname;
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Email Field (Required)
            _buildTextField(
              controller: _emailController,
              label: '${AppLocalizations.of(context)!.emailAddress} *',
              hint: AppLocalizations.of(context)!.enterEmailAddress,
              colors: colors,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterEmail;
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return AppLocalizations.of(context)!.pleaseEnterValidEmail;
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Company Field
            _buildTextField(
              controller: _companyController,
              label: AppLocalizations.of(context)!.company,
              hint: AppLocalizations.of(context)!.enterCompanyName,
              colors: colors,
            ),
            
            const SizedBox(height: 24),
            
            // Company Address Field
            _buildTextField(
              controller: _addressController,
              label: AppLocalizations.of(context)!.companyAddress,
              hint: AppLocalizations.of(context)!.enterCompanyAddress,
              colors: colors,
            ),
            
            const SizedBox(height: 24),
            
            // Number of Workers Field
            _buildTextField(
              controller: _workersController,
              label: AppLocalizations.of(context)!.numberOfWorkers,
              hint: AppLocalizations.of(context)!.enterNumberOfWorkers,
              colors: colors,
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: 24),
            
            // Phone Number Field
            _buildTextField(
              controller: _phoneController,
              label: AppLocalizations.of(context)!.phoneNumber,
              hint: AppLocalizations.of(context)!.enterPhoneNumber,
              colors: colors,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^[\+]?[0-9\s\-\(\)]{7,}$').hasMatch(value)) {
                    return AppLocalizations.of(context)!.pleaseEnterValidPhoneNumber;
                  }
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Interested In Field
            _buildTextField(
              controller: _interestedInController,
              label: AppLocalizations.of(context)!.interestedIn,
              hint: AppLocalizations.of(context)!.enterInterestedIn,
              colors: colors,
            ),
            
            const SizedBox(height: 24),
            
            // Message Field
            _buildTextField(
              controller: _messageController,
              label: AppLocalizations.of(context)!.message,
              hint: 'Tell us how we can help you...',
              colors: colors,
              maxLines: 5,
            ),
            
            const SizedBox(height: 32),
            
            // Submit Button
            Center(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryBlue,
                  foregroundColor: colors.whiteTextOnBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(colors.whiteTextOnBlue),
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.sendMessage,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required AppColors colors,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(
            fontSize: 16,
            color: colors.textColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colors.textColor.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: colors.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colors.textColor.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colors.textColor.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colors.primaryBlue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colors.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colors.error,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Send email using Firebase Functions
        await _sendEmail();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Thank you for your message! We\'ll get back to you soon.'),
              backgroundColor: Theme.of(context).extension<AppColors>()!.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );

          // Clear form
          _nameController.clear();
          _surnameController.clear();
          _emailController.clear();
          _companyController.clear();
          _addressController.clear();
          _workersController.clear();
          _phoneController.clear();
          _interestedInController.clear();
          _messageController.clear();
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send message. Please try again. Error: $e'),
              backgroundColor: Theme.of(context).extension<AppColors>()!.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _sendEmail() async {
    // Store contact form data in Firestore
    // This will trigger a Firebase Function to send the email
    await FirebaseFirestore.instance.collection('contact_messages').add({
      'contactPersonName': _nameController.text,
      'contactPersonSurname': _surnameController.text,
      'email': _emailController.text,
      'company': _companyController.text.isNotEmpty ? _companyController.text : AppLocalizations.of(context)!.notProvided,
      'companyAddress': _addressController.text.isNotEmpty ? _addressController.text : AppLocalizations.of(context)!.notProvided,
      'numberOfWorkers': _workersController.text.isNotEmpty ? _workersController.text : AppLocalizations.of(context)!.notProvided,
      'phoneNumber': _phoneController.text.isNotEmpty ? _phoneController.text : AppLocalizations.of(context)!.notProvided,
      'interestedIn': _interestedInController.text.isNotEmpty ? _interestedInController.text : 'General inquiry',
      'message': _messageController.text,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending', // pending, sent, failed
    });
  }

}
