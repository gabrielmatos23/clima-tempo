import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const ClimaApp());

class ClimaApp extends StatelessWidget {
  const ClimaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Clima Agora',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF176B87),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF3F8FA),
      fontFamily: 'Roboto',
    ),
    home: const WeatherPage(),
  );
}

class WeatherData {
  const WeatherData({
    required this.city,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.code,
  });

  final String city;
  final String country;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int code;
}

class WeatherService {
  final http.Client _client = http.Client();

  Future<WeatherData> fetch(String city) async {
    final geo = await _getJson(
      Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': city,
        'count': '1',
        'language': 'pt',
        'format': 'json',
      }),
    );
    final results = geo['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      throw const WeatherException(
        'Não encontramos essa cidade. Confira o nome e tente novamente.',
      );
    }

    final place = results.first as Map<String, dynamic>;
    final forecast = await _getJson(
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '${place['latitude']}',
        'longitude': '${place['longitude']}',
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m',
        'timezone': 'auto',
      }),
    );
    final current = forecast['current'] as Map<String, dynamic>;
    return WeatherData(
      city: place['name'] as String,
      country: (place['country'] as String?) ?? '',
      temperature: (current['temperature_2m'] as num).toDouble(),
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      code: (current['weather_code'] as num).toInt(),
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const WeatherException(
        'O serviço de clima está indisponível. Tente novamente em instantes.',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

class WeatherException implements Exception {
  const WeatherException(this.message);
  final String message;
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _controller = TextEditingController(text: 'São Paulo');
  final _service = WeatherService();
  WeatherData? _weather;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final city = _controller.text.trim();
    if (city.isEmpty) {
      setState(() => _error = 'Digite o nome de uma cidade.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.fetch(city);
      if (mounted) {
        setState(() => _weather = result);
      }
    } on WeatherException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } on http.ClientException {
      if (mounted) {
        setState(
          () => _error = 'Sem conexão com a internet. Verifique sua rede e tente novamente.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Ocorreu um erro ao buscar os dados. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weather = _weather;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.wb_sunny_rounded,
                      color: Color(0xFF176B87),
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Clima Agora',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Consulte o tempo em qualquer cidade.',
                  style: TextStyle(color: Colors.blueGrey.shade600),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          hintText: 'Ex.: Rio de Janeiro',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: _loading ? null : _search,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Icon(Icons.search),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_loading) ...[
                  const SizedBox(height: 100),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 18),
                  const Center(child: Text('Buscando informações do clima...')),
                ] else if (_error != null)
                  _ErrorCard(message: _error!, onRetry: _search)
                else if (weather != null) ...[
                  _CurrentWeatherCard(weather: weather),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.thermostat,
                          label: 'Sensação',
                          value: '${weather.feelsLike.round()}°C',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.water_drop_outlined,
                          label: 'Umidade',
                          value: '${weather.humidity}%',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MetricCard(
                    icon: Icons.air_rounded,
                    label: 'Vento',
                    value: '${weather.windSpeed.toStringAsFixed(1)} km/h',
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Dados fornecidos pela API Open-Meteo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentWeatherCard extends StatelessWidget {
  const _CurrentWeatherCard({required this.weather});
  final WeatherData weather;

  @override
  Widget build(BuildContext context) {
    final (description, icon) = _weatherDescription(weather.code);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF176B87), Color(0xFF64B5C6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF176B87).withValues(alpha: .2),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${weather.city}${weather.country.isEmpty ? '' : ', ${weather.country}'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 68),
              const SizedBox(width: 12),
              Text(
                '${weather.temperature.round()}°',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 76,
                  height: 1,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Temperatura atual',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .82),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF176B87)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1EF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          size: 38,
          color: Color(0xFFB5473C),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF7F3029)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      ],
    ),
  );
}

(String, IconData) _weatherDescription(int code) {
  if (code == 0) {
    return ('Céu limpo', Icons.wb_sunny_rounded);
  }
  if (code <= 3) {
    return ('Parcialmente nublado', Icons.cloud_outlined);
  }
  if (code == 45 || code == 48) {
    return ('Neblina', Icons.foggy);
  }
  if (code >= 51 && code <= 67) {
    return ('Chuvisco ou chuva', Icons.grain_rounded);
  }
  if (code >= 71 && code <= 77) {
    return ('Neve', Icons.ac_unit_rounded);
  }
  if (code >= 80 && code <= 82) {
    return ('Pancadas de chuva', Icons.umbrella_rounded);
  }
  if (code >= 95) {
    return ('Trovoadas', Icons.thunderstorm_rounded);
  }
  return ('Condição variável', Icons.cloud_rounded);
}
