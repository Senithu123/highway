import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_empty_state.dart';
import '../app_models.dart';
import '../toll_repository.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip History')),
      body: StreamBuilder<List<TollTrip>>(
        stream: TollRepository.instance.watchTrips(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final trips = snapshot.data!
              .where((trip) => trip.status == TripStatus.completed)
              .toList();

          if (trips.isEmpty) {
            return const AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No completed trips yet',
              subtitle:
                  'Once a trip is paid, it will appear here with the receipt details.',
            );
          }

          final formatter = DateFormat('MMM d, yyyy • h:mm a');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final trip = trips[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    child: const Icon(Icons.route_rounded),
                  ),
                  title: Text('${trip.entryGate} → ${trip.exitGate ?? '-'}'),
                  subtitle: Text(
                    '${trip.vehiclePlateNumber}\n${formatter.format(trip.entryTimestamp)}',
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'LKR ${trip.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        trip.receiptNumber ?? 'Receipt pending',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: trips.length,
          );
        },
      ),
    );
  }
}
