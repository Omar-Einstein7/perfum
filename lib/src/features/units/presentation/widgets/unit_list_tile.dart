import 'package:flutter/material.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/entities/unit.dart';

class UnitListTile extends StatelessWidget {
  final Unit unit;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const UnitListTile({
    super.key,
    required this.unit,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: Text(unit.name),
        subtitle: Text('Created ${unit.createdAt.toLocal().toString().split('.')[0]}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
