import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/weather_services.dart';
import '../providers/alert_provider.dart';
import '../models/alert_model.dart';
import 'package:intl/intl.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Fetch alerts when screen loads
    setState(() {
      _isLoading = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchAndUpdateAlerts(
        context,
        lat: 18.983,
        lon: 73.1,
        notifyUser: true,
      ).then((_) {
        setState(() {
          _isLoading = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = Provider.of<AlertProvider>(context);
    final alerts = alertProvider.alerts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Alerts'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : alerts.isEmpty
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
                    'By: ${alert.sender}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(alert.description),
                  const SizedBox(height: 10),
                  Text(
                    'From: ${alert.start != 0 ? _formatTime(alert.start) : 'N/A'}\n'
                        'To: ${alert.end != 0 ? _formatTime(alert.end) : 'N/A'}',
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

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd MMM, hh:mm a').format(date);
  }

  Future<void> fetchAndUpdateAlerts(
      BuildContext context, {
        required double lat,
        required double lon,
        bool notifyUser = true,
      }) async {
    try {
      final alerts = await WeatherService.checkWeatherAlert(
        lat: lat,
        lon: lon,
        notifyUser: notifyUser,
      );
      Provider.of<AlertProvider>(context, listen: false).updateAlerts(alerts);
      print('Successfully updated ${alerts.length} alerts');
    } catch (e) {
      print('Error fetching alerts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load alerts: $e')),
      );
    }
  }
}