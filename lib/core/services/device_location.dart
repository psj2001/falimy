import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class DeviceLocation {
  const DeviceLocation({
    this.country,
    this.state,
    this.place,
    this.address,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
  });

  final String? country;
  final String? state;
  final String? place;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;

  bool get hasFix => latitude != null && longitude != null;

  String get summary {
    final parts = [
      if ((place ?? '').trim().isNotEmpty) place!.trim(),
      if ((state ?? '').trim().isNotEmpty) state!.trim(),
      if ((country ?? '').trim().isNotEmpty) country!.trim(),
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    if (hasFix) {
      return '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}';
    }
    return 'Location unavailable';
  }

  Map<String, dynamic> toJson() => {
    if (country != null && country!.trim().isNotEmpty) 'country': country,
    if (state != null && state!.trim().isNotEmpty) 'state': state,
    if (place != null && place!.trim().isNotEmpty) 'place': place,
    if (address != null && address!.trim().isNotEmpty) 'address': address,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
  };
}

Future<DeviceLocation?> captureDeviceLocation({
  bool requestPermission = true,
}) async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    if (!serviceEnabled && requestPermission) {
      return null;
    }

    Position? position;
    if (!requestPermission) {
      position = await Geolocator.getLastKnownPosition();
    }
    position ??= await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );

    String? country;
    String? state;
    String? place;
    String? address;
    try {
      final marks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (marks.isNotEmpty) {
        final mark = marks.first;
        country = _clean(mark.country);
        state = _clean(mark.administrativeArea);
        place =
            _clean(mark.locality) ??
            _clean(mark.subLocality) ??
            _clean(mark.subAdministrativeArea);
        address = [
          mark.street,
          mark.subLocality,
          mark.locality,
          mark.administrativeArea,
          mark.country,
        ].map(_clean).whereType<String>().join(', ');
        if (address.isEmpty) address = null;
      }
    } catch (_) {}

    return DeviceLocation(
      country: country,
      state: state,
      place: place,
      address: address,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
    );
  } catch (_) {
    return null;
  }
}

String? _clean(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? null : text;
}
