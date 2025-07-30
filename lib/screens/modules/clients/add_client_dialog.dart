import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:diacritic/diacritic.dart'; // <-- Import this!
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class AddClientDialog extends StatefulWidget {
  final String companyId;
  const AddClientDialog({Key? key, required this.companyId}) : super(key: key);

  @override
  State<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<AddClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _postCodeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  String? _error;
  String? _suggestedName;
  bool _isSaving = false;

  // --- Generate the clientId from the name ---
  String clientIdFromName(String name) {
    // Remove diacritics, spaces, and non-alphanumerics, lowercase everything
    return removeDiacritics(name)
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toLowerCase();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _firstNameCtrl.dispose();
    _surnameCtrl.dispose();
    _countryCtrl.dispose();
    _numberCtrl.dispose();
    _postCodeCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context)!.addNewClient,
                    style: TextStyle(
                      color: colors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    )),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.clientName,
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _firstNameCtrl,
                  decoration: InputDecoration(
                    labelText: '${AppLocalizations.of(context)!.contactPerson} ${AppLocalizations.of(context)!.firstName}',
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _surnameCtrl,
                  decoration: InputDecoration(
                    labelText: '${AppLocalizations.of(context)!.contactPerson} ${AppLocalizations.of(context)!.surname}',
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _addressCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.street,
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _numberCtrl,
                  decoration: InputDecoration(
                    labelText: '${AppLocalizations.of(context)!.street} ${AppLocalizations.of(context)!.number}',
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _postCodeCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.postCode,
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _cityCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.city,
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _countryCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.country,
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(
                    labelText: '${AppLocalizations.of(context)!.clientName} ${AppLocalizations.of(context)!.email}',
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
                    if (!emailRegex.hasMatch(v.trim())) return 'Invalid email';
                    return null;
                  },
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _phoneCtrl,
                  decoration: InputDecoration(
                    labelText: '${AppLocalizations.of(context)!.clientName} ${AppLocalizations.of(context)!.phone}',
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 18),

                if (_error != null)
                  Text(_error!,
                      style: TextStyle(color: colors.error, fontWeight: FontWeight.bold)),

                if (_suggestedName != null)
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Suggested: $_suggestedName',
                        style: TextStyle(
                            color: colors.primaryBlue, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _nameCtrl.text = _suggestedName!;
                                _suggestedName = null;
                                _error = null;
                              });
                              _save();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primaryBlue,
                              foregroundColor: colors.whiteTextOnBlue,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: const Text("Accept"),
                          ),
                          const SizedBox(width: 20),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _suggestedName = null;
                                _error = null;
                              });
                            },
                            child: const Text("Cancel"),
                          ),
                        ],
                      ),
                    ],
                  ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        child: Text(AppLocalizations.of(context)!.cancel),
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(false)),
                    const SizedBox(width: 18),
                    ElevatedButton(
                      child: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(AppLocalizations.of(context)!.save, style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryBlue,
                        foregroundColor: colors.whiteTextOnBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: _isSaving ? null : _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() => _isSaving = false);
      return;
    }

    // Generate clientId from name field!
    String enteredName = _nameCtrl.text.trim();
    String clientId = clientIdFromName(enteredName);
    String baseClientId = clientId;
    int counter = 1;

    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('clients')
        .doc(clientId);

    final docSnap = await docRef.get();

    // Unique check (suggest new ID if needed)
    if (docSnap.exists) {
      while (true) {
        clientId = "$baseClientId$counter";
        final testDoc = FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('clients')
            .doc(clientId);
        final testSnap = await testDoc.get();
        if (!testSnap.exists) break;
        counter++;
      }
      setState(() {
        _isSaving = false;
        _suggestedName = clientId;
        _error = '${AppLocalizations.of(context)!.clientName} bereits verwendet (durch ID).';
      });
      return;
    }

    try {
      await docRef.set({
        'name': enteredName,
        'street': _addressCtrl.text.trim(),
        'number': _numberCtrl.text.trim(),
        'post_code': _postCodeCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'contact_person': {
          'first_name': _firstNameCtrl.text.trim(),
          'surname': _surnameCtrl.text.trim(),
        },
        'client': clientId, // Store the client ID for linking in projects
        'createdAt': FieldValue.serverTimestamp(),
      });
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Speichern des ${AppLocalizations.of(context)!.client.toLowerCase()}. Bitte versuchen Sie es erneut.';
        _isSaving = false;
      });
    }
  }
}

class EditClientDialog extends StatefulWidget {
  final String companyId;
  final Map<String, dynamic> client;
  const EditClientDialog({Key? key, required this.companyId, required this.client}) : super(key: key);

  @override
  State<EditClientDialog> createState() => _EditClientDialogState();
}

class _EditClientDialogState extends State<EditClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _postCodeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill all fields with existing client data
    final client = widget.client;
    _nameCtrl.text = client['name'] ?? '';
    _addressCtrl.text = client['street'] ?? '';
    _numberCtrl.text = client['number'] ?? '';
    _postCodeCtrl.text = client['post_code'] ?? '';
    _cityCtrl.text = client['city'] ?? '';
    _countryCtrl.text = client['country'] ?? '';
    _emailCtrl.text = client['email'] ?? '';
    _phoneCtrl.text = client['phone'] ?? '';
    
    final contactPerson = client['contact_person'] ?? {};
    _firstNameCtrl.text = contactPerson['first_name'] ?? '';
    _surnameCtrl.text = contactPerson['surname'] ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _firstNameCtrl.dispose();
    _surnameCtrl.dispose();
    _countryCtrl.dispose();
    _numberCtrl.dispose();
    _postCodeCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${AppLocalizations.of(context)!.edit} ${AppLocalizations.of(context)!.client}',
                    style: TextStyle(
                      color: colors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    )),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.clientName,
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _firstNameCtrl,
                  decoration: InputDecoration(
                    labelText: '${AppLocalizations.of(context)!.contactPerson} ${AppLocalizations.of(context)!.firstName}',
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _surnameCtrl,
                  decoration: InputDecoration(
                    labelText: '${AppLocalizations.of(context)!.contactPerson} ${AppLocalizations.of(context)!.surname}',
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _addressCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.street,
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _numberCtrl,
                  decoration: InputDecoration(
                    labelText: '${AppLocalizations.of(context)!.street} ${AppLocalizations.of(context)!.number}',
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _postCodeCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.postCode,
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _cityCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.city,
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _countryCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.country,
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(
                    labelText: '${AppLocalizations.of(context)!.clientName} ${AppLocalizations.of(context)!.email}',
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
                    if (!emailRegex.hasMatch(v.trim())) return 'Invalid email';
                    return null;
                  },
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _phoneCtrl,
                  decoration: InputDecoration(
                    labelText: '${AppLocalizations.of(context)!.clientName} ${AppLocalizations.of(context)!.phone}',
                    filled: true,
                    fillColor: colors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  enabled: !_isSaving,
                ),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: colors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        child: Text(AppLocalizations.of(context)!.cancel),
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(false)),
                    const SizedBox(width: 18),
                    ElevatedButton(
                      child: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(AppLocalizations.of(context)!.save, style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryBlue,
                        foregroundColor: colors.whiteTextOnBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: _isSaving ? null : _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Generate the clientId from the name
  String clientIdFromName(String name) {
    return removeDiacritics(name)
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toLowerCase();
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() => _isSaving = false);
      return;
    }

    String enteredName = _nameCtrl.text.trim();
    String originalName = widget.client['name'] ?? '';
    
    // Check if name changed and if new name would create duplicate
    if (enteredName != originalName) {
      String newClientId = clientIdFromName(enteredName);
      String currentClientId = widget.client['id'];
      
      // Only check for duplicates if the new ID would be different from current
      if (newClientId != currentClientId) {
        final docRef = FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('clients')
            .doc(newClientId);

        final docSnap = await docRef.get();
        
        if (docSnap.exists) {
          // Try to find a unique ID by adding numbers
          String baseClientId = newClientId;
          int counter = 1;
          
          while (true) {
            newClientId = "$baseClientId$counter";
            final testDoc = FirebaseFirestore.instance
                .collection('companies')
                .doc(widget.companyId)
                .collection('clients')
                .doc(newClientId);
            final testSnap = await testDoc.get();
            if (!testSnap.exists) break;
            counter++;
          }
          
          setState(() {
            _isSaving = false;
            _error = 'Client name already exists. Suggested ID: $newClientId';
          });
          return;
        }
      }
    }

    try {
      // Update the existing client document
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('clients')
          .doc(widget.client['id'])
          .update({
        'name': _nameCtrl.text.trim(),
        'street': _addressCtrl.text.trim(),
        'number': _numberCtrl.text.trim(),
        'post_code': _postCodeCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'contact_person': {
          'first_name': _firstNameCtrl.text.trim(),
          'surname': _surnameCtrl.text.trim(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = 'Failed to update client. Please try again.';
        _isSaving = false;
      });
    }
  }
}
