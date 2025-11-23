import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as gc;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Kampus Locator',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Position? _pos;
  String? _address;
  String _status = 'Siap.';
  bool _isHighAccuracy = true; // Poin 11: Toggle Akurasi
  StreamSubscription<Position>? _sub; // Poin 5: Stream
  bool _tracking = false; // Poin 5: Tracking Status

  // Poin 6 & 11: Data Event Kampus (Minimal 3)
  final List<Map<String, dynamic>> events = [
    {'title': 'Seminar AI (Gedung A)', 'lat': -7.4300, 'lng': 109.2400},
    {'title': 'Job Fair (Auditorium)', 'lat': -7.4350, 'lng': 109.2450},
    {'title': 'Expo UKM (Lapangan)', 'lat': -7.4290, 'lng': 109.2380},
  ];

  @override
  void dispose() {
    _sub?.cancel(); // Poin 8: Batalkan stream
    super.dispose();
  }

  // Poin 5: Memeriksa layanan & izin
  Future<bool> _ensureServiceAndPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _status = 'Service GPS Mati.');
      await Geolocator.openLocationSettings();
      return false;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      setState(() => _status = 'Izin ditolak permanen.');
      return false;
    }
    return true;
  }

  // Poin 5: Lokasi Satu Kali (Get Current)
  Future<void> _getCurrent() async {
    if (!await _ensureServiceAndPermission()) return;

    setState(() => _status = 'Mengambil lokasi (${_isHighAccuracy ? "High" : "Low"})...');
    try {
      final p = await Geolocator.getCurrentPosition(
        // Poin 8 & 11: Optimasi Accuracy
        desiredAccuracy: _isHighAccuracy ? LocationAccuracy.high : LocationAccuracy.low,
      );
      setState(() {
        _pos = p;
        _status = 'Lokasi update (One-time).';
      });
      _reverseGeocode(p);
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  // Poin 5: Pelacakan Kontinu (Stream)
  Future<void> _toggleTracking() async {
    if (_tracking) {
      await _sub?.cancel();
      setState(() {
        _tracking = false;
        _status = 'Tracking stop.';
      });
      return;
    }
    if (!await _ensureServiceAndPermission()) return;

    // Poin 8: DistanceFilter untuk hemat baterai
    final settings = LocationSettings(
      accuracy: _isHighAccuracy ? LocationAccuracy.high : LocationAccuracy.low,
      distanceFilter: 10,
    );

    _sub = Geolocator.getPositionStream(locationSettings: settings).listen((p) {
      setState(() {
        _pos = p;
        _tracking = true;
        _status = 'Tracking aktif...';
      });
      _reverseGeocode(p);
    }, onError: (e) {
      setState(() => _status = 'Stream error: $e');
    });
  }

  // Poin 5: Reverse Geocoding (Opsional)
  Future<void> _reverseGeocode(Position p) async {
    try {
      final placemarks = await gc.placemarkFromCoordinates(p.latitude, p.longitude);
      if (placemarks.isNotEmpty) {
        final m = placemarks.first;
        setState(() {
          _address = '${m.street}, ${m.locality}';
        });
      }
    } catch (_) {}
  }

  // Poin 6: Hitung Jarak
  double distanceM(Position me, Map e) => Geolocator.distanceBetween(
    me.latitude, me.longitude, e['lat'] as double, e['lng'] as double,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Kampus Locator')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel Status
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: $_status', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (_pos != null) ...[
                      const SizedBox(height: 5),
                      Text('Lat: ${_pos!.latitude.toStringAsFixed(5)}'),
                      Text('Lng: ${_pos!.longitude.toStringAsFixed(5)}'),
                      Text('Speed: ${_pos!.speed.toStringAsFixed(1)} m/s'), // Poin 5
                      if (_address != null) Text('Alamat: $_address'),
                    ],
                    const Divider(),
                    // Poin 11: Toggle Akurasi
                    SwitchListTile(
                      title: const Text("Mode Akurasi Tinggi"),
                      subtitle: Text(_isHighAccuracy ? "GPS (Boros)" : "Wifi/Seluler (Hemat)"),
                      value: _isHighAccuracy,
                      onChanged: (val) {
                        setState(() => _isHighAccuracy = val);
                      },
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Event Terdekat:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            // Poin 6: List Event & Jarak
            Expanded(
              child: _pos == null
                  ? const Center(child: Text('Tekan "Cek Lokasi" dulu.'))
                  : ListView(
                children: events.map((e) {
                  final d = distanceM(_pos!, e);
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.event, color: Colors.blue),
                      title: Text(e['title']),
                      subtitle: Text('${d.toStringAsFixed(1)} meter'),
                      trailing: const Icon(Icons.arrow_forward),
                      // Poin 16: Navigasi ke Peta dari List
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OsmMapPage(center: LatLng(e['lat'], e['lng'])),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // Poin 16: Tombol Navigasi & Kontrol
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _getCurrent,
                  icon: const Icon(Icons.my_location),
                  label: const Text('One-Time'),
                ),
                FilledButton.icon(
                  onPressed: _toggleTracking,
                  icon: Icon(_tracking ? Icons.stop : Icons.play_arrow),
                  label: Text(_tracking ? 'Stop Stream' : 'Start Stream'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    if (_pos != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OsmMapPage(center: LatLng(_pos!.latitude, _pos!.longitude)),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lokasi belum ada")));
                    }
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Lihat Peta'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Poin 15: Integrasi OpenStreetMap
class OsmMapPage extends StatelessWidget {
  final LatLng center;
  const OsmMapPage({super.key, required this.center});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peta Lokasi')),
      body: FlutterMap(
        options: MapOptions(initialCenter: center, initialZoom: 15),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.event_kampus_locator',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: center,
                width: 40,
                height: 40,
                child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}