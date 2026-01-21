import 'package:flutter/material.dart';

class HourlyForecastItem extends StatelessWidget {
  final String time;
  final String iconUrl;
  final String temp;
  const HourlyForecastItem({super.key, required this.time, required this.iconUrl, required this.temp});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 15,
      child: Container(
        width: 95,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              time,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines : 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Image.network(iconUrl,
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text('$temp°C'),
          ],
        ),
      ),
    );
  }
}
