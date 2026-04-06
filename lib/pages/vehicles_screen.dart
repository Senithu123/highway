import 'package:flutter/material.dart';

import '../app_empty_state.dart';
import '../app_models.dart';
import '../toll_repository.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Vehicles')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVehicleSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
      body: StreamBuilder<List<Vehicle>>(
        stream: TollRepository.instance.watchVehicles(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehicles = snapshot.data!;
          if (vehicles.isEmpty) {
            return const AppEmptyState(
              icon: Icons.directions_car_outlined,
              title: 'No vehicles added yet',
              subtitle:
                  'Register your first vehicle so toll charges can match the right category.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    child: const Icon(Icons.directions_car_filled_outlined),
                  ),
                  title: Text(vehicle.displayName),
                  subtitle: Text(vehicle.category.label),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: vehicles.length,
          );
        },
      ),
    );
  }

  Future<void> _showAddVehicleSheet(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final plateController = TextEditingController();
    final nicknameController = TextEditingController();
    var category = VehicleCategory.car;
    var isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> save() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setModalState(() => isSaving = true);
              try {
                await TollRepository.instance.addVehicle(
                  plateNumber: plateController.text,
                  category: category,
                  nickname: nicknameController.text,
                );

                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vehicle added successfully.')),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                }
              } finally {
                if (context.mounted) {
                  setModalState(() => isSaving = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Register Vehicle',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: plateController,
                      decoration: const InputDecoration(
                        labelText: 'Plate Number',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Plate number is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nicknameController,
                      decoration: const InputDecoration(
                        labelText: 'Nickname',
                        hintText: 'Family car, Work van, etc.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<VehicleCategory>(
                      initialValue: category,
                      items: VehicleCategory.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => category = value);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Category',
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: isSaving ? null : save,
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Vehicle'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
