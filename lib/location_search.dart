import 'package:flutter/material.dart';

class LocationSearch extends StatefulWidget {
  final Function(String) onSearch;
  const LocationSearch({super.key, required this.onSearch});

  @override
  State<LocationSearch> createState() => _LocationSearchState();
}

class _LocationSearchState extends State<LocationSearch> {
  final TextEditingController _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Enter Location',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onSubmitted: (value) => {
        if (value.trim().isNotEmpty){
          widget.onSearch(value.trim()),
        },
      },
    );
  }
}
