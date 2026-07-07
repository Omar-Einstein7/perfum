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
    final tt = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: Text(unit.name, style: tt.titleSmall),
        subtitle: Text('${unit.abbreviation}  •  ${unit.type.name}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!unit.active)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Inactive', style: tt.labelSmall?.copyWith(color: Colors.grey.shade600)),
              ),
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
