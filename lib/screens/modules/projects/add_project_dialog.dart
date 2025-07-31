import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:diacritic/diacritic.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../clients/add_client_dialog.dart';
import '../admin/user_address.dart';

class AddProjectDialog extends StatefulWidget {
  final String companyId;
  const AddProjectDialog({super.key, required this.companyId});

  @override
  State<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameCtrl = TextEditingController();
  final _projectRefCtrl =
      TextEditingController(); // Project Ref (internal reference)
  final _clientSearchCtrl = TextEditingController();

  String? _selectedClientName;
  String? _error;
  String? _suggestedId;
  bool _isSaving = false;
  Map<String, dynamic> _addressData = {};

  @override
  void dispose() {
    _projectNameCtrl.dispose();
    _projectRefCtrl.dispose();
    _clientSearchCtrl.dispose();
    super.dispose();
  }

  void _onAddressChanged(Map<String, dynamic> addressData) {
    setState(() {
      _addressData = addressData;
    });
  }

  String projectIdFromName(String name) {
    return removeDiacritics(name)
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toLowerCase();
  }

  String clientIdFromName(String name) {
    return removeDiacritics(name)
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.addNewProject,
                  style: TextStyle(
                    color: colors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _projectNameCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.projectName,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.black26,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.black26,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: colors.primaryBlue, width: 2),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _projectRefCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.projectRef,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.black26,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.black26,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: colors.primaryBlue, width: 2),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 16),

                // --- Address widget ---
                UserAddress(
                  addressData: _addressData,
                  onAddressChanged: _onAddressChanged,
                  title: AppLocalizations.of(context)!.address,
                  showCard: false,
                ),
                const SizedBox(height: 20),

                // --- Client picker ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.of(context)!.client,
                    style: TextStyle(
                        color: colors.darkGray,
                        fontWeight: FontWeight.w600,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                _buildClientPicker(context, colors),
                const SizedBox(height: 20),

                if (_error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Text(
                        _error!,
                        style: TextStyle(
                            color: colors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),

                if (_suggestedId != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Text(
                            'Project name already used.',
                            style: TextStyle(
                                color: colors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Suggested: $_suggestedId',
                            style: TextStyle(
                                color: colors.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _projectNameCtrl.text = _suggestedId!;
                                    _suggestedId = null;
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
                                    _suggestedId = null;
                                    _error = null;
                                  });
                                },
                                child:
                                    Text(AppLocalizations.of(context)!.cancel),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    const SizedBox(width: 18),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryBlue,
                        foregroundColor: colors.whiteTextOnBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(AppLocalizations.of(context)!.save,
                              style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildClientPicker(BuildContext context, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _clientSearchCtrl,
          decoration: InputDecoration(
            labelText:
                '${AppLocalizations.of(context)!.search} ${AppLocalizations.of(context)!.clients}...',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              tooltip: AppLocalizations.of(context)!.createNewClient,
              onPressed: () async {
                final created = await showDialog<bool>(
                  context: context,
                  builder: (ctx) =>
                      AddClientDialog(companyId: widget.companyId),
                );
                if (created == true) setState(() {});
              },
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.black26,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.black26,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.primaryBlue, width: 2),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(maxHeight: 170),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('companies')
                .doc(widget.companyId)
                .collection('clients')
                .orderBy('name')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final allDocs = snapshot.data!.docs;
              final filtered = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return (data['name'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(_clientSearchCtrl.text.trim().toLowerCase());
              }).toList();

              if (filtered.isEmpty && _clientSearchCtrl.text.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                      "${AppLocalizations.of(context)!.noClientsFound} ${AppLocalizations.of(context)!.tapToAdd}.",
                      style: TextStyle(color: colors.darkGray)),
                );
              }

              return ListView(
                shrinkWrap: true,
                children: filtered.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    dense: true,
                    title: Text(data['name'] ?? '-',
                        style: TextStyle(color: colors.primaryBlue)),
                    subtitle: (data['client_email'] ?? '').toString().isNotEmpty
                        ? Text(data['client_email'],
                            style:
                                TextStyle(color: colors.darkGray, fontSize: 13))
                        : null,
                    trailing: _selectedClientName == data['name']
                        ? Icon(Icons.check_circle, color: colors.success)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedClientName = data['name'];
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
        if (_selectedClientName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
                "${AppLocalizations.of(context)!.view}: $_selectedClientName",
                style: TextStyle(color: colors.primaryBlue)),
          ),
      ],
    );
  }

  Future<void> _save() async {
    if (!mounted) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    if (!_formKey.currentState!.validate() || _selectedClientName == null) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        if (_selectedClientName == null) {
          _error = AppLocalizations.of(context)!.clientMustBeSelectedOrCreated;
        }
      });
      return;
    }

    // Generate normalized project ID for Firestore doc
    String enteredProjectName = _projectNameCtrl.text.trim();
    String baseProjectId = projectIdFromName(enteredProjectName);
    String projectId = baseProjectId;
    int counter = 1;

    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('projects')
        .doc(projectId);

    final docSnap = await docRef.get();

    if (docSnap.exists) {
      while (true) {
        projectId = "$baseProjectId$counter";
        final testDoc = FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('projects')
            .doc(projectId);
        final testSnap = await testDoc.get();
        if (!testSnap.exists) break;
        counter++;
      }
      setState(() {
        _isSaving = false;
        _suggestedId = projectId;
        _error = 'Project name already used (as ID)';
      });
      return;
    }

    String clientId = _selectedClientName != null
        ? clientIdFromName(_selectedClientName!)
        : '';

    try {
      await docRef.set({
        'projectRef': _projectRefCtrl.text.trim(),
        'name': enteredProjectName,
        'address': {
          'street': _addressData['street'] ?? '',
          'number': _addressData['number'] ?? '',
          'post_code': _addressData['post_code'] ?? '',
          'city': _addressData['city'] ?? '',
          'country': _addressData['country'] ?? '',
          'area': _addressData['area'] ?? '',
        },
        'client': clientId,
        'created_at': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to save project. Please try again.';
        _isSaving = false;
      });
    }
  }
}
