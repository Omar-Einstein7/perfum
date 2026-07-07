import 'package:flutter/material.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/entities/unit.dart';

class UnitForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController abbreviationController;
  final TextEditingController descriptionController;
  final UnitType? selectedType;
  final ValueChanged<UnitType?> onTypeChanged;
  final VoidCallback onSave;
  final bool isEditing;
  final bool isLoading;

  const UnitForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.abbreviationController,
    required this.descriptionController,
    this.selectedType,
    required this.onTypeChanged,
    required this.onSave,
    this.isEditing = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: nameController,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Unit Name',
              hintText: 'e.g. Kilogram, Carton, Meter',
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
          const SizedBox(height: 16),
          TextFormField(
            controller: abbreviationController,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Abbreviation',
              hintText: 'e.g. kg, pcs, m',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Abbreviation is required';
              }
              if (value.trim().length > 10) {
                return 'Abbreviation must be 10 characters or less';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<UnitType>(
            initialValue: selectedType,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
            ),
            items: UnitType.values.map((type) {
              return DropdownMenuItem(value: type, child: Text(type.name));
            }).toList(),
            onChanged: isLoading ? null : onTypeChanged,
            validator: (value) {
              if (value == null) return 'Unit type is required';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: descriptionController,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'e.g. Metric unit of mass',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value != null && value.length > 500) {
                return 'Description must be 500 characters or less';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSave,
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEditing ? 'Update' : 'Create'),
            ),
          ),
        ],
      ),
    );
  }
}
