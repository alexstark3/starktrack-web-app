import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../security/company_id_generator.dart';
import '../services/company_module_service.dart';
import '../../screens/modules/admin/add_user.dart';
import '../../screens/modules/admin/user_address.dart';

class AddCompanyDialog extends StatefulWidget {
  final Function() onCompanyAdded;
  final Map<String, dynamic>? existingCompany;

  const AddCompanyDialog({
    super.key,
    required this.onCompanyAdded,
    this.existingCompany,
  });

  @override
  State<AddCompanyDialog> createState() => _AddCompanyDialogState();
}

class _AddCompanyDialogState extends State<AddCompanyDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _userLimitController =
      TextEditingController(text: '10');

  Map<String, dynamic> _addressData = {};
  List<String> _selectedModules = [];
  String? _tempCompanyId;
  String? _selectedAdminName;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAddressData();
    _initializeExistingData();

    // Trigger rebuild after initialization for existing company data
    if (widget.existingCompany != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    }
  }

  void _initializeAddressData() {
    _addressData = {
      'country': 'Switzerland',
      'area': '',
      'city': '',
      'postCode': '',
      'street': '',
      'streetNumber': '',
    };
  }

  void _initializeExistingData() {
    if (widget.existingCompany != null) {
      final company = widget.existingCompany!;

      print('🔍 DEBUG: Initializing existing company data: ${company['name']}');

      // Set company name
      _nameController.text = company['name'] ?? '';

      // Set user limit
      _userLimitController.text = (company['userLimit'] ?? 10).toString();

      // Set address data
      final address = company['address'] as Map<String, dynamic>? ?? {};
      print('🔍 DEBUG: Company address data: $address');

      _addressData = {
        'country': address['country'] ?? 'Switzerland',
        'area': address['area'] ?? '',
        'city': address['city'] ?? '',
        'postCode': address['postCode']?.toString() ?? '',
        'street': address['street'] ?? '',
        'streetNumber': address['streetNumber']?.toString() ?? '',
      };

      print('🔍 DEBUG: Initialized address data: $_addressData');

      // Set modules
      final modulesData = company['modules'];
      if (modulesData != null) {
        if (modulesData is List) {
          _selectedModules = List<String>.from(modulesData);
        } else if (modulesData is Map) {
          _selectedModules = modulesData.keys.cast<String>().toList();
        }
      }
    }
  }

  void _onAddressChanged(Map<String, dynamic> newAddressData) {
    print('🔍 DEBUG: AddCompanyDialog - Address changed: $newAddressData');
    // Only update if the address data is actually different
    if (_addressData.toString() != newAddressData.toString()) {
      setState(() {
        _addressData = newAddressData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Dialog(
      backgroundColor: colors.backgroundDark,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.primaryBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.business,
                    color: colors.whiteTextOnBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.existingCompany != null
                        ? 'Edit Company'
                        : 'Add New Company',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.whiteTextOnBlue,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Name
                    Text(
                      'Company Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter company name',
                        filled: true,
                        fillColor: colors.cardColorDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.primaryBlue),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.primaryBlue),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: colors.primaryBlue, width: 2),
                        ),
                      ),
                      style: TextStyle(color: colors.textColor),
                    ),
                    const SizedBox(height: 24),

                    // Company Address
                    Text(
                      'Company Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    UserAddress(
                      addressData: _addressData,
                      onAddressChanged: _onAddressChanged,
                      title: 'Company Address',
                      isSwissAddress: true,
                      showCard: false,
                      showStreetAndNumber: true,
                    ),
                    // Debug output for address data
                    if (widget.existingCompany != null)
                      Text(
                        'DEBUG: Address data being passed: $_addressData',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                        ),
                      ),
                    const SizedBox(height: 24),

                    // User Limit
                    Text(
                      'User Limit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _userLimitController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter user limit',
                        filled: true,
                        fillColor: colors.cardColorDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.primaryBlue),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.primaryBlue),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: colors.primaryBlue, width: 2),
                        ),
                      ),
                      style: TextStyle(color: colors.textColor),
                    ),
                    const SizedBox(height: 24),

                    // Module Assignment
                    Text(
                      'Assign Modules',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildModuleSelection(),
                    const SizedBox(height: 24),

                    // Company Admin
                    Text(
                      'Company Admin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Debug output for tempCompanyId
                    if (widget.existingCompany == null)
                      Text(
                        'DEBUG: _tempCompanyId = $_tempCompanyId',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                        ),
                      ),
                    InkWell(
                      onTap: _tempCompanyId != null
                          ? _showCreateAdminDialog
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.primaryBlue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_add,
                              color: colors.primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedAdminName ??
                                    (_tempCompanyId != null
                                        ? 'Click to create company admin'
                                        : 'Create company first'),
                                style: TextStyle(
                                  color: _selectedAdminName != null
                                      ? colors.textColor
                                      : colors.textColor.withOpacity(0.7),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: colors.primaryBlue,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: colors.textColor),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _createCompany,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primaryBlue,
                            foregroundColor: colors.whiteTextOnBlue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(widget.existingCompany != null
                                  ? 'Update Company'
                                  : 'Create Company'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleSelection() {
    final colors = Theme.of(context).extension<AppColors>()!;
    final availableModules = CompanyModuleService.getAvailableModules();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.primaryBlue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: availableModules.map((module) {
          final isSelected = _selectedModules.contains(module);
          return CheckboxListTile(
            title: Text(
              CompanyModuleService.getModuleDisplayName(module),
              style: TextStyle(color: colors.textColor),
            ),
            subtitle: Text(
              CompanyModuleService.getModuleDescription(module),
              style: TextStyle(color: colors.textColor.withOpacity(0.7)),
            ),
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedModules.add(module);
                } else {
                  _selectedModules.remove(module);
                }
              });
            },
            activeColor: colors.primaryBlue,
            checkColor: colors.whiteTextOnBlue,
          );
        }).toList(),
      ),
    );
  }

  Future<void> _createCompany() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a company name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final companyName = _nameController.text.trim();
      final userLimit = int.tryParse(_userLimitController.text) ?? 10;

      if (widget.existingCompany != null) {
        // Update existing company
        final companyId = widget.existingCompany!['id'];

        print('🔍 DEBUG: Updating company with ID: $companyId');

        await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .update({
          'name': companyName,
          'address': _addressData,
          'userLimit': userLimit,
          'modules': _selectedModules,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('🔍 DEBUG: Company updated with ID: $companyId');

        setState(() => _isLoading = false);

        Navigator.of(context).pop();
        widget.onCompanyAdded();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Create new company
        final companyId =
            CompanyIdGenerator.generateSecureCompanyId(companyName);

        print('🔍 DEBUG: Creating company with name: $companyName');
        print('🔍 DEBUG: Generated company ID: $companyId');

        await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .set({
          'name': companyName,
          'address': _addressData,
          'userLimit': userLimit,
          'userCount': 0,
          'modules': _selectedModules,
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
          'secureId': companyId,
          'originalId': CompanyIdGenerator.extractCompanyName(companyId),
        });

        print('🔍 DEBUG: Company created with ID: $companyId');

        // Store company ID for admin creation
        _tempCompanyId = companyId;
        print(
            '🔍 DEBUG: Company created, _tempCompanyId set to: $_tempCompanyId');

        setState(() {
          _isLoading = false;
        });

        // Force a rebuild to ensure UI updates
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });

        print(
            '🔍 DEBUG: setState called, _tempCompanyId should be: $_tempCompanyId');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Company created successfully! Now create the company admin.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print(
          '❌ Error ${widget.existingCompany != null ? 'updating' : 'creating'} company: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Error ${widget.existingCompany != null ? 'updating' : 'creating'} company: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateAdminDialog() {
    if (_tempCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create the company first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddUserDialog(
        companyId: _tempCompanyId!,
        teamLeaders: [], // No team leaders for super admin context
        currentUserRoles: [
          'super_admin'
        ], // Super admin can create company admins
        preSelectedRoles: ['company_admin'],
        onUserAdded: () async {
          // Update company user count and add admin email
          await FirebaseFirestore.instance
              .collection('companies')
              .doc(_tempCompanyId)
              .update({
            'userCount': 1,
            'adminEmail':
                'admin@company.com', // This should be the actual email
          });

          // Update the admin name in the field
          setState(() {
            _selectedAdminName = 'Admin Created';
          });

          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company admin created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _userLimitController.dispose();
    super.dispose();
  }
}
