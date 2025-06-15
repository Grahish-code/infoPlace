import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../models/alert_model.dart';
import 'package:intl/intl.dart';

class AlertScreen extends StatelessWidget {
  const AlertScreen({super.key});

  String _formatTime(DateTime date) {
    return DateFormat('dd MMM, hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final alerts = Provider.of<WeatherProvider>(context).alerts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Alerts'),
      ),
      body: alerts.isEmpty
          ? const Center(child: Text('No alerts available'))
          : ListView.builder(
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return Card(
            margin: const EdgeInsets.all(12),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.event,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'By: ${alert.sender ?? 'Unknown'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(alert.description),
                  const SizedBox(height: 10),
                  Text(
                    'From: ${alert.start != null ? _formatTime(alert.start! as DateTime) : 'N/A'}\n'
                        'To: ${alert.end != null ? _formatTime(alert.end! as DateTime) : 'N/A'}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
