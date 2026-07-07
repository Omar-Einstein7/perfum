import 'package:flutter/material.dart';

class UnitForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final String? initialName;
  final VoidCallback onSave;
  final bool isEditing;

  const UnitForm({
    super.key,
    required this.formKey,
    required this.nameController,
    this.initialName,
    required this.onSave,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Unit Name',
              hintText: 'e.g. Carton, Piece, Meter',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Unit name is required';
              }
              if (value.trim().length > 100) {
                return 'Unit name must be 100 characters or less';
              }
              return null;
            },
            autofocus: true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSave,
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ),
        ],
      ),
    );
  }
}
