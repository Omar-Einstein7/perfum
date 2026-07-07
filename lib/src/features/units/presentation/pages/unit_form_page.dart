import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/entities/unit.dart';
import 'package:perfum_ahmed_gaper/src/features/units/presentation/bloc/unit_cubit.dart';
import 'package:perfum_ahmed_gaper/src/features/units/presentation/bloc/unit_state.dart';
import 'package:perfum_ahmed_gaper/src/features/units/presentation/widgets/unit_form.dart';

class UnitFormPage extends StatefulWidget {
  final Unit? unit;
  const UnitFormPage({super.key, this.unit});
  @override
  State<UnitFormPage> createState() => _UnitFormPageState();
}

class _UnitFormPageState extends State<UnitFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _abbreviationController;
  late final TextEditingController _descriptionController;
  UnitType? _selectedType;

  bool get isEditing => widget.unit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.unit?.name ?? '');
    _abbreviationController = TextEditingController(text: widget.unit?.abbreviation ?? '');
    _descriptionController = TextEditingController(text: widget.unit?.description ?? '');
    _selectedType = widget.unit?.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _abbreviationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((UnitCubit c) => c.state is UnitLoading);

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Unit' : 'Add Unit')),
      body: BlocListener<UnitCubit, UnitState>(
        listenWhen: (previous, current) =>
            current is UnitLoaded || current is UnitError,
        listener: (context, state) {
          if (state is UnitLoaded || state is UnitInitial) {
            Navigator.of(context).pop();
          }
          if (state is UnitError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: UnitForm(
              formKey: _formKey,
              nameController: _nameController,
              abbreviationController: _abbreviationController,
              descriptionController: _descriptionController,
              selectedType: _selectedType,
              onTypeChanged: (type) => setState(() => _selectedType = type),
              isEditing: isEditing,
              isLoading: isLoading,
              onSave: _onSave,
            ),
          ),
        ),
      ),
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<UnitCubit>();
    if (isEditing) {
      cubit.updateUnit(
        id: widget.unit!.id,
        name: _nameController.text.trim(),
        abbreviation: _abbreviationController.text.trim(),
        type: _selectedType,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
    } else {
      cubit.createUnit(
        name: _nameController.text.trim(),
        abbreviation: _abbreviationController.text.trim(),
        type: _selectedType!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
    }
  }
}
