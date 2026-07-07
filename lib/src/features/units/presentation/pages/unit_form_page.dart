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

  bool get isEditing => widget.unit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.unit?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Unit' : 'Add Unit'),
      ),
      body: BlocListener<UnitCubit, UnitState>(
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
          child: UnitForm(
            formKey: _formKey,
            nameController: _nameController,
            initialName: widget.unit?.name,
            isEditing: isEditing,
            onSave: _onSave,
          ),
        ),
      ),
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final cubit = context.read<UnitCubit>();
    if (isEditing) {
      cubit.updateUnit(widget.unit!.id, name);
    } else {
      cubit.createUnit(name);
    }
  }
}
