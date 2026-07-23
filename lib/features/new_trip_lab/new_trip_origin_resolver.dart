import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'new_trip_lab_models.dart';

abstract interface class OriginResolver {
  Future<PrototypeOriginResolution> resolve();
}

class DeviceOriginResolver implements OriginResolver {
  const DeviceOriginResolver({this.timeout = const Duration(seconds: 8)});

  final Duration timeout;

  @override
  Future<PrototypeOriginResolution> resolve() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const PrototypeOriginResolution.failed(
          PrototypeOriginFailure.servicesDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const PrototypeOriginResolution.failed(
          PrototypeOriginFailure.permissionDeniedForever,
        );
      }
      if (permission == LocationPermission.denied) {
        return const PrototypeOriginResolution.failed(
          PrototypeOriginFailure.permissionDenied,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(timeout);

      try {
        final placemarks = await Geocoding()
            .placemarkFromCoordinates(position.latitude, position.longitude)
            .timeout(timeout);
        if (placemarks.isEmpty) {
          return const PrototypeOriginResolution.failed(
            PrototypeOriginFailure.lookupFailed,
          );
        }
        final placemark = placemarks.first;
        final city =
            <String?>[
                  placemark.locality,
                  placemark.subAdministrativeArea,
                  placemark.administrativeArea,
                ]
                .whereType<String>()
                .map((value) => value.trim())
                .firstWhere((value) => value.isNotEmpty, orElse: () => '');
        if (city.isEmpty) {
          return const PrototypeOriginResolution.failed(
            PrototypeOriginFailure.lookupFailed,
          );
        }
        return PrototypeOriginResolution.resolved(
          PrototypeOriginSelection(
            label: city,
            source: PrototypeOriginSource.device,
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
      } on TimeoutException {
        return const PrototypeOriginResolution.failed(
          PrototypeOriginFailure.timedOut,
        );
      } catch (_) {
        return const PrototypeOriginResolution.failed(
          PrototypeOriginFailure.lookupFailed,
        );
      }
    } on TimeoutException {
      return const PrototypeOriginResolution.failed(
        PrototypeOriginFailure.timedOut,
      );
    } catch (_) {
      return const PrototypeOriginResolution.failed(
        PrototypeOriginFailure.unavailable,
      );
    }
  }
}

class FixedOriginResolver implements OriginResolver {
  const FixedOriginResolver(this.result);

  factory FixedOriginResolver.resolved(String city) => FixedOriginResolver(
    PrototypeOriginResolution.resolved(
      PrototypeOriginSelection(
        label: city,
        source: PrototypeOriginSource.device,
      ),
    ),
  );

  factory FixedOriginResolver.failed(PrototypeOriginFailure failure) =>
      FixedOriginResolver(PrototypeOriginResolution.failed(failure));

  final PrototypeOriginResolution result;

  @override
  Future<PrototypeOriginResolution> resolve() async => result;
}
