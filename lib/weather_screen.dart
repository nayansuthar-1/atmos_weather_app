import 'dart:convert';
import 'dart:ui';

import 'package:atmos/config.dart';
import 'package:flutter/material.dart';
import 'hourly_forecast_item.dart';
import 'additional_info_item.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const WeatherScreen({super.key, required this.onToggleTheme});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String queryLocation = 'Mumbai';
  double? selectedLat;
  double? selectedLon;
  bool isMapLoading = false;

  IconData _getWeatherIcon(String condition, bool isDay) {
    final text = condition.toLowerCase();

    if (text.contains('thunder')) {
      return Icons.flash_on;
    }

    if (text.contains('rain') || text.contains('drizzle')) {
      return Icons.umbrella;
    }

    if (text.contains('cloud')) {
      return isDay ? Icons.cloud : Icons.cloud_outlined;
    }

    if (text.contains('clear') || text.contains('sunny')) {
      return isDay ? Icons.wb_sunny : Icons.nights_stay;
    }

    return Icons.wb_cloudy;
  }

  Future<Map<String, dynamic>>? weather;

  // ......api call.......//
  Future<Map<String, dynamic>> getCurrentWeatherByLocation(
      String location) async {
    try {
      final uri = Uri.https(
        'api.weatherapi.com',
        '/v1/forecast.json',
        {
          'key': weatherApiKey,
          'q': location,
          'days': '1',
          'aqi': 'yes',
          'alerts': 'no',
        },
      );

      final res = await http.get(uri);
      final data = jsonDecode(res.body);

      if (res.statusCode != 200) {
        throw data['error']['message'];
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> _saveLastLocation({
    String? query,
    double? lat,
    double? lon,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (query != null) {
      await prefs.setString('last_query', query);
    }

    if (lat != null && lon != null) {
      await prefs.setDouble('last_lat', lat);
      await prefs.setDouble('last_lon', lon);
    }
  }

  @override
  void initState() {
    super.initState();
    weather = null;
    _loadLastLocation();
  }

  Future<void> _loadLastLocation() async {
    final prefs = await SharedPreferences.getInstance();

    final savedLat = prefs.getDouble('last_lat');
    final savedLon = prefs.getDouble('last_lon');
    final savedQuery = prefs.getString('last_query');

    if (savedLat != null && savedLon != null) {
      selectedLat = savedLat;
      selectedLon = savedLon;
      weather = getCurrentWeatherByLocation('$savedLat,$savedLon');
    } else if (savedQuery != null) {
      queryLocation = savedQuery;
      weather = getCurrentWeatherByLocation(savedQuery);
    } else {
      weather = getCurrentWeatherByLocation(queryLocation);
    }

    setState(() {});
  }

  Color _getWeatherIconColor(String condition) {
    if (condition.contains('Sunny') || condition.contains('Clear')) {
      return Colors.orange;
    } else if (condition.contains('Cloud')) {
      return Colors.blueGrey;
    } else if (condition.contains('Rain') || condition.contains('Drizzle')) {
      return Colors.blue;
    } else if (condition.contains('Thunder')) {
      return Colors.deepPurple;
    } else if (condition.contains('Snow')) {
      return Colors.lightBlueAccent;
    } else {
      return Colors.grey;
    }
  }

  //.........gps access and locate........//
  Future<void> _useMyLocation() async {
    try {
      setState(() {
        isMapLoading = true;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Please enable location services';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw 'Location permission denied';
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permission permanently denied. Enable it from settings.';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      
      final double lat = double.parse(position.latitude.toStringAsFixed(3));
      final double lon = double.parse(position.longitude.toStringAsFixed(3));

      
      final newFuture = getCurrentWeatherByLocation('$lat,$lon');

      setState(() {
        // ✅ Save rounded values
        _saveLastLocation(
          lat: lat,
          lon: lon,
        );

        selectedLat = lat;
        selectedLon = lon;
        weather = newFuture;
      });

      newFuture.whenComplete(() {
        if (mounted) {
          setState(() {
            isMapLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isMapLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onToggleTheme,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Icon(
              Icons.lightbulb,
              key: ValueKey(Theme.of(context).brightness),
              size: 26,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.amber //  glowing color
                  : Colors.grey, // normal/off
              shadows: Theme.of(context).brightness == Brightness.dark
                  ? [
                      Shadow(
                        color: Colors.amber.withValues(alpha: 0.8),
                        blurRadius: 15,
                      ),
                      Shadow(
                        color: Colors.amber.withValues(alpha: 0.8),
                        blurRadius: 30,
                      ),
                    ]
                  : [],
            ),
          ),
        ),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Atmos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            weather == null
                ? const SizedBox()
                : FutureBuilder<Map<String, dynamic>>(
                    future: weather,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();

                      final data = snapshot.data!;
                      final name = data['location']['name'];
                      final region = data['location']['region'];

                      return Text(
                        '$name, $region',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                      );
                    },
                  ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Use my location',
            icon: const Icon(
              Icons.place,
              size: 30,
              color: Colors.lightBlue,
            ),
            onPressed: () async {
              try {
                await _useMyLocation();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            //..........LOCATION INPUT.............//////
            TextField(
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Enter location',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  final query = value.trim();

                  setState(() {
                    queryLocation = query;
                    selectedLat = null;
                    selectedLon = null;
                    weather = getCurrentWeatherByLocation(query);
                  });

                  _saveLastLocation(query: query);
                }
              },
            ),

            const SizedBox(height: 18),

            // ........ WEATHER DATA............//
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    if (selectedLat != null && selectedLon != null) {
                      weather = getCurrentWeatherByLocation(
                        '$selectedLat,$selectedLon',
                      );
                    } else {
                      weather = getCurrentWeatherByLocation(queryLocation);
                    }
                  });
                },
                child: weather == null
                    ? const Center(
                        child: CircularProgressIndicator.adaptive(),
                      )
                    : FutureBuilder<Map<String, dynamic>>(
                        future: weather,
                        builder: (context, snapshot) {

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator.adaptive());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text(snapshot.error.toString()));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: Text('No data'));
                    }

                    final data = snapshot.data!;

                    final current = data['current'];

                    final isDay = current['is_day'] == 1;
                    final currentTemp = current['temp_c'];
                    final currentSky = current['condition']['text'];
                    final pressure = current['pressure_mb'].toString();
                    final humidity = current['humidity'].toString();
                    final windSpeed = current['wind_kph'].toString();
                    final uvIndex = current['uv'].toString();
                    final visibility = '${current['vis_km']} km';
                    final aqi =
                        current['air_quality']['pm2_5'].toStringAsFixed(1);
                    final lat = data['location']['lat'];
                    final lon = data['location']['lon'];
                    final astro = data['forecast']['forecastday'][0]['astro'];
                    final sunrise = astro['sunrise'];
                    final sunset = astro['sunset'];
                    final dayText = DateFormat('EEEE').format(DateTime.now());
                    final dateText = DateFormat('d MMM').format(DateTime.now());

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // MAIN CARD
                          SizedBox(
                            width: double.infinity,
                            child: Card(
                              elevation: 15,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Text(
                                          '$currentTemp°C',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Icon(
                                          _getWeatherIcon(currentSky, isDay),
                                          size: 65,
                                          color: isDay
                                              ? _getWeatherIconColor(currentSky)
                                              : Colors.indigoAccent,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(currentSky,
                                            style:
                                                const TextStyle(fontSize: 20)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 24),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    children: [
                                      const Icon(Icons.wb_twilight,
                                          color: Color.fromARGB(
                                              255, 255, 169, 41)),
                                      const SizedBox(height: 6),
                                      const Text('Sunrise'),
                                      Text(
                                        sunrise,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        dayText.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha :0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dateText,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Icon(Icons.wb_twilight,
                                          color:
                                              Color.fromARGB(255, 209, 62, 17)),
                                      const SizedBox(height: 6),
                                      const Text('Sunset'),
                                      Text(
                                        sunset,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          const SizedBox(height: 10),

                          SizedBox(
                            height: 130,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 12,
                              itemBuilder: (context, index) {
                                final hourlyList =
                                    data['forecast']['forecastday'][0]['hour'];

                                final hourData = hourlyList[index + 1];

                                final time = DateTime.parse(hourData['time']);
                                final temp = hourData['temp_c'].toString();

                                final iconUrl =
                                    'https:${hourData['condition']['icon']}';

                                return HourlyForecastItem(
                                  time: DateFormat.j().format(time),
                                  temp: temp,
                                  iconUrl: iconUrl,
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          const SizedBox(height: 12),

                          SizedBox(
                            height: 115,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                  child: AdditionalInfoItem(
                                    icon: Icons.water_drop,
                                    lable: 'Humidity',
                                    value: '$humidity %',
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                  child: AdditionalInfoItem(
                                    icon: Icons.air,
                                    lable: 'Wind',
                                    value: '$windSpeed km/h',
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                  child: AdditionalInfoItem(
                                    icon: Icons.masks,
                                    lable: 'AQI',
                                    value: aqi,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                  child: AdditionalInfoItem(
                                    icon: Icons.speed,
                                    lable: 'Pressure',
                                    value: '$pressure mb',
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                  child: AdditionalInfoItem(
                                    icon: Icons.visibility,
                                    lable: 'Visibility',
                                    value: visibility,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                  child: AdditionalInfoItem(
                                    icon: Icons.wb_sunny,
                                    lable: 'UV Index',
                                    value: uvIndex,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),

                          const SizedBox(height: 12),

                          SizedBox(
                            height: 400,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  FlutterMap(
                                    options: MapOptions(
                                      initialCenter: LatLng(
                                        selectedLat ?? lat,
                                        selectedLon ?? lon,
                                      ),
                                      initialZoom: 10,
                                      keepAlive: true,
                                      onTap: (tapPosition, point) {
                                        setState(() {
                                          isMapLoading = true;
                                          selectedLat = point.latitude;
                                          selectedLon = point.longitude;
                                        });

                                        _saveLastLocation(
                                          lat: point.latitude,
                                          lon: point.longitude,
                                        );

                                        final newFuture =
                                            getCurrentWeatherByLocation(
                                          '${point.latitude},${point.longitude}',
                                        );

                                        setState(() {
                                          weather = newFuture;
                                        });

                                        newFuture.whenComplete(() {
                                          if (mounted) {
                                            setState(() {
                                              isMapLoading = false;
                                            });
                                          }
                                        });
                                      },
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                                        subdomains: const ['a', 'b', 'c'],
                                        userAgentPackageName:
                                            'com.example.atmos',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(
                                              selectedLat ?? lat,
                                              selectedLon ?? lon,
                                            ),
                                            width: 40,
                                            height: 40,
                                            child: const Icon(
                                              Icons.location_pin,
                                              color: Colors.red,
                                              size: 40,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (isMapLoading)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black
                                            .withValues(alpha: 0.15),
                                        child: const Center(
                                          child: CircularProgressIndicator
                                              .adaptive(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : Colors.grey.shade200,
                            child: Column(
                              children: const [
                                Text(
                                  'Powered by WeatherAPI.com',
                                  style: TextStyle(fontSize: 12),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Maps © OpenStreetMap contributors',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
