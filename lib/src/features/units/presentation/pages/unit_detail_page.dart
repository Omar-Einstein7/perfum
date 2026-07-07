import 'package:flutter/material.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/entities/unit.dart';

class UnitDetailPage extends StatelessWidget {
  final Unit unit;

  const UnitDetailPage({super.key, required this.unit});

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(unit.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Name', unit.name),
            const Divider(),
            _detailRow('Created', _formatDate(unit.createdAt.toLocal())),
            const Divider(),
            _detailRow('Updated', _formatDate(unit.updatedAt.toLocal())),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
