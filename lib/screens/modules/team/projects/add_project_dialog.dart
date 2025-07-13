import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:diacritic/diacritic.dart';
import '../../../../theme/app_colors.dart';
import '../clients/add_client_dialog.dart';

class AddProjectDialog extends StatefulWidget {
  final String companyId;
  const AddProjectDialog({Key? key, required this.companyId}) : super(key: key);

  @override
  State<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameCtrl = TextEditingController();
  final _projectRefCtrl = TextEditingController(); // Project ID (internal reference)
  final _streetCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _postCodeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _clientSearchCtrl = TextEditingController();

  String? _selectedClientName;
  String? _error;
  String? _suggestedId;
  bool _isSaving = false;

  @override
  void dispose() {
    _projectNameCtrl.dispose();
    _projectRefCtrl.dispose();
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _postCodeCtrl.dispose();
    _cityCtrl.dispose();
    _clientSearchCtrl.dispose();
    super.dispose();
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
                  'Add New Project',
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
                    labelText: 'Project Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: colors.lightGray,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _projectRefCtrl,
                  decoration: InputDecoration(
                    labelText: 'Project ID',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: colors.lightGray,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 16),

                // --- Address fields ---
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _streetCtrl,
                        decoration: InputDecoration(
                          labelText: 'Street',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: colors.lightGray,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        enabled: !_isSaving,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 90,
                      child: TextFormField(
                        controller: _numberCtrl,
                        decoration: InputDecoration(
                          labelText: 'No.',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: colors.lightGray,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        enabled: !_isSaving,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: TextFormField(
                        controller: _postCodeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Post Code',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: colors.lightGray,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        enabled: !_isSaving,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cityCtrl,
                        decoration: InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: colors.lightGray,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        enabled: !_isSaving,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Client picker ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Client',
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
                                child: const Text("Cancel"),
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
                      child: const Text('Cancel'),
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
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
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save',
                              style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildClientPicker(BuildContext context, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _clientSearchCtrl,
          decoration: InputDecoration(
            labelText: 'Search clients...',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Create new client',
              onPressed: () async {
                final created = await showDialog<bool>(
                  context: context,
                  builder: (ctx) =>
                      AddClientDialog(companyId: widget.companyId),
                );
                if (created == true) setState(() {});
              },
            ),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: colors.lightGray,
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
                  child: Text("No matching clients. Click + to add.",
                      style: TextStyle(color: colors.darkGray)),
                );
              }

              return ListView(
                shrinkWrap: true,
                children: filtered.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 6),
                    dense: true,
                    title: Text(data['name'] ?? '-',
                        style: TextStyle(color: colors.primaryBlue)),
                    subtitle:
                        (data['client_email'] ?? '').toString().isNotEmpty
                            ? Text(data['client_email'],
                                style: TextStyle(
                                    color: colors.darkGray, fontSize: 13))
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
            child: Text("Selected: $_selectedClientName",
                style: TextStyle(color: colors.primaryBlue)),
          ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    if (!_formKey.currentState!.validate() || _selectedClientName == null) {
      setState(() {
        _isSaving = false;
        if (_selectedClientName == null)
          _error = 'Client must be selected or created';
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
        'project_id': _projectRefCtrl.text.trim(),
        'name': enteredProjectName,
        'address': {
          'street': _streetCtrl.text.trim(),
          'number': _numberCtrl.text.trim(),
          'post_code': _postCodeCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
        },
        'client': clientId,
        'created_at': FieldValue.serverTimestamp(),
      });
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = 'Failed to save project. Please try again.';
        _isSaving = false;
      });
    }
  }
}
