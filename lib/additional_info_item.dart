import 'package:flutter/material.dart';

class AdditionalInfoItem extends StatelessWidget {
  final IconData icon;
  final String lable;
  final String value;
  const AdditionalInfoItem({
    super.key,
    required this.icon,
    required this.lable,
    required this.value,
  });

  Color _getIconColor() {
    switch (lable) {
      case 'Humidity':
        return Colors.blue;
      case 'Wind':
        return Colors.teal;
      case 'Pressure':
        return Colors.deepPurple;
      case 'UV Index':
        return Colors.orange;
      case 'Visibility':
        return Colors.indigo;
      case 'AQI':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: _getIconColor(),
          ),
        const SizedBox(height: 8),
        Text(lable),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}



