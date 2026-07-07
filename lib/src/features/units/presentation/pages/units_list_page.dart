import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/entities/unit.dart';
import 'package:perfum_ahmed_gaper/src/features/units/presentation/bloc/unit_cubit.dart';
import 'package:perfum_ahmed_gaper/src/features/units/presentation/bloc/unit_state.dart';
import 'package:perfum_ahmed_gaper/src/features/units/presentation/pages/unit_form_page.dart';

class UnitsListPage extends StatefulWidget {
  const UnitsListPage({super.key});

  @override
  State<UnitsListPage> createState() => _UnitsListPageState();
}

class _UnitsListPageState extends State<UnitsListPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<UnitCubit>().loadUnits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<UnitCubit>().loadUnits(search: query.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Units of Measure'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search units...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: BlocConsumer<UnitCubit, UnitState>(
              listener: (context, state) {
                if (state is UnitDeleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unit deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is UnitLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is UnitError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<UnitCubit>().loadUnits(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is UnitLoaded) {
                  if (state.units.isEmpty) {
                    return const Center(child: Text('No units found. Add one!'));
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => context.read<UnitCubit>().loadUnits(
                            page: state.page,
                            search: _searchController.text.trim(),
                          ),
                          child: ListView.builder(
                            itemCount: state.units.length,
                            itemBuilder: (context, index) {
                              final unit = state.units[index];
                              return ListTile(
                                title: Text(unit.name),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _navigateToForm(context, unit: unit),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _confirmDelete(context, unit.id, unit.name, state.page),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      if (state.pages > 1)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: state.page > 1
                                    ? () => context.read<UnitCubit>().loadUnits(
                                          page: state.page - 1,
                                          search: _searchController.text.trim(),
                                        )
                                    : null,
                              ),
                              Text('Page ${state.page} of ${state.pages}'),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: state.page < state.pages
                                    ? () => context.read<UnitCubit>().loadUnits(
                                          page: state.page + 1,
                                          search: _searchController.text.trim(),
                                        )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToForm(BuildContext context, {Unit? unit}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<UnitCubit>(),
          child: UnitFormPage(unit: unit),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name, int currentPage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Unit'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<UnitCubit>().deleteUnit(id, currentPage: currentPage);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
