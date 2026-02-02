import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PickLocationScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const PickLocationScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  LatLng? selected;
  GoogleMapController? map;

  @override
  void initState() {
    super.initState();
    selected = LatLng(widget.initialLat, widget.initialLng);
  }

  @override
  Widget build(BuildContext context) {
    final pos = selected ?? LatLng(widget.initialLat, widget.initialLng);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, selected);
            },
            child: const Text('OK'),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: pos, zoom: 15),
        onMapCreated: (c) => map = c,
        markers: {Marker(markerId: const MarkerId('pick'), position: pos)},
        onTap: (p) {
          setState(() => selected = p);
        },
      ),
    );
  }
}
