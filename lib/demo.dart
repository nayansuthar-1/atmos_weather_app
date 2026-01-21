import 'dart:convert';
import 'dart:ui';

import 'package:atmos/config.dart';
import 'package:flutter/material.dart';
import 'hourly_forecast_item.dart';
import 'additional_info_item.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WeatherScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const WeatherScreen({super.key, required this.onToggleTheme});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String queryLocation = 'Mandar Rajasthan';
  late Future<Map<String, dynamic>> weather;
  String locationName = '';
  String region = '';
  Future<Map<String, dynamic>> getCurrentWeatherByLocation(
      dynamic queryLocation) async {
    try {
      // const lat = 24.5667;
      // const lon = 72.3833;

      final searchUri = Uri.https(
        'api.weatherapi.com',
        '/v1/search.json',
        {
          'key': weatherApiKey,
          'q': queryLocation,
          'days': '1',
          'aqi': 'yes',
          'alerts': 'no',
        },
      );

      final searchRes = await http.get(searchUri);
      final searchData = jsonDecode(searchRes.body);

      if (searchData.isEmpty) {
        throw 'Location Not Found!';
      }

      final lat = searchData[0]['lat'];
      final lon = searchData[0]['lon'];

      final weatherUri = Uri.https(
        'api.weatherapi.com',
        '/v1/forecast.json',
        {
          'key': weatherApiKey,
          'q': '$lat,$lon',
          'days': '1',
          'aqi': 'yes',
          'alerts': 'no',
        },
      );

      final weatherRes = await http.get(weatherUri);
      final data = jsonDecode(weatherRes.body);

      if (weatherRes.statusCode != 200) {
        throw data['error']['message'];
      }
      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    weather = getCurrentWeatherByLocation(queryLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onToggleTheme,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.lightbulb_outline
                  : Icons.lightbulb,
              key: ValueKey(Theme.of(context).brightness),
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
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                weather = getCurrentWeatherByLocation(queryLocation);
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder(
        future: weather,
        builder: (context, snapshot) {
          // print(snapshot.runtimeType);

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data'));
          }

          final data = snapshot.data!;

          final current = data['current'];

          final currentTemp = current['temp_c'];
          final currentSky = current['condition']['text'];
          final pressure = current['pressure_mb'].toString();
          final humidity = current['humidity'].toString();
          final windSpeed = current['wind_kph'].toString();
          final uvIndex = current['uv'].toString();
          final visibility = '${current['vis_km']} km';
          final aqi =
              data['current']['air_quality']['pm2_5'].toStringAsFixed(1);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // main card..
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 15,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: RepaintBoundary(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  '$currentTemp°C',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Icon(
                                  currentSky == 'Clouds' || currentSky == 'Rain'
                                      ? Icons.cloud
                                      : Icons.sunny,
                                  size: 65,
                                ),
                                SizedBox(height: 10),
                                Text(currentSky,
                                    style: TextStyle(fontSize: 20)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Hourly Forecast',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),
                //.........this makes n widgets at a time ............//
                //weather forecast cards..
                // SingleChildScrollView(
                //   scrollDirection: Axis.horizontal,
                //   child: Row(
                //     children: [
                //       for (int i = 1; i <= 5; i++)
                //         HourlyForecastItem(
                //           time: data['list'][i]['dt'].toString(),
                //           icon:
                //               data['list'][i]['weather'][0]['main'] ==
                //                       'Clouds' ||
                //                   data['list'][i]['weather'][0]['main'] ==
                //                       'Rain'
                //               ? Icons.cloud
                //               : Icons.sunny,
                //           temp: data['list'][i]['main']['temp'].toString(),
                //         ),
                //     ],
                //   ),
                // ),

                //.............. this makes widget as we scroll ............//
                SizedBox(
                  height: 130,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemCount: 23,
                    itemBuilder: (context, index) {
                      final hourlyList =
                          data['forecast']['forecastday'][0]['hour'];

                      final hourData = hourlyList[index + 1];

                      final time = DateTime.parse(hourData['time']);
                      final temp = hourData['temp_c'].toString();

                      final iconUrl = 'https:${hourData['condition']['icon']}';

                      return HourlyForecastItem(
                        time: DateFormat.j().format(time),
                        temp: temp,
                        iconUrl: iconUrl,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // additional infos..
                const Text(
                  'Additional Information',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 115,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: AdditionalInfoItem(
                          icon: Icons.water_drop,
                          lable: 'Humidity',
                          value: '$humidity %',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: AdditionalInfoItem(
                          icon: Icons.air,
                          lable: 'Wind',
                          value: '$windSpeed km/h',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: AdditionalInfoItem(
                          icon: Icons.speed,
                          lable: 'Pressure',
                          value: '$pressure mb',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: AdditionalInfoItem(
                          icon: Icons.wb_sunny,
                          lable: 'UV Index',
                          value: uvIndex,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: AdditionalInfoItem(
                          icon: Icons.visibility,
                          lable: 'Visibility',
                          value: '$visibility',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: AdditionalInfoItem(
                          icon: Icons.masks,
                          lable: 'AQI',
                          value: aqi,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
