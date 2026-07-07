import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/entities/unit.dart';
import 'package:perfum_ahmed_gaper/src/features/units/presentation/bloc/unit_cubit.dart';
import 'package:perfum_ahmed_gaper/src/features/units/presentation/bloc/unit_state.dart';
import 'unit_form_page.dart';

class UnitDetailPage extends StatelessWidget {
  final String unitId;

  const UnitDetailPage({super.key, required this.unitId});

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnitCubit, UnitState>(
      builder: (context, state) {
        if (state is UnitLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Unit Details')),
            body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (state is UnitError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Unit Details')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<UnitCubit>().loadUnit(unitId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (state is UnitDetailLoaded) {
          final unit = state.unit;
          return Scaffold(
            appBar: AppBar(
              title: Text(unit.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<UnitCubit>(),
                          child: UnitFormPage(unit: unit),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Name', unit.name),
                  const Divider(),
                  _detailRow('Abbreviation', unit.abbreviation),
                  const Divider(),
                  _detailRow('Type', unit.type.name),
                  if (unit.description != null) ...[
                    const Divider(),
                    _detailRow('Description', unit.description!),
                  ],
                  const Divider(),
                  _detailRow('Status', unit.active ? 'Active' : 'Inactive'),
                  const Divider(),
                  _detailRow('Created', _formatDate(unit.createdAt.toLocal())),
                  const Divider(),
                  _detailRow('Updated', _formatDate(unit.updatedAt.toLocal())),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDeactivate(context, unit),
                      icon: const Icon(Icons.block, color: Colors.red),
                      label: Text(unit.active ? 'Deactivate Unit' : 'Reactivate Unit',
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Unit Details')),
          body: const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, Unit unit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(unit.active ? 'Deactivate Unit' : 'Reactivate Unit'),
        content: Text(unit.active
            ? 'Are you sure you want to deactivate "${unit.name}"?'
            : 'Are you sure you want to reactivate "${unit.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<UnitCubit>().deleteUnit(unit.id);
            },
            child: Text(unit.active ? 'Deactivate' : 'Reactivate', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
