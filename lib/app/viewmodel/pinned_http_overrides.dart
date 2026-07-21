import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

class IotPinnedCertificatePolicy {
  final String host;
  final int port;
  final Uint8List certificateDer;

  IotPinnedCertificatePolicy({
    required String host,
    required this.port,
    required Uint8List certificateDer,
  }) : host = host.toLowerCase(),
       certificateDer = Uint8List.fromList(certificateDer);

  bool allows({
    required String requestedHost,
    required int requestedPort,
    required List<int> presentedCertificateDer,
    required DateTime validFrom,
    required DateTime validTo,
    DateTime? now,
  }) {
    final checkedAt = now ?? DateTime.now();
    return requestedHost.toLowerCase() == host &&
        requestedPort == port &&
        !checkedAt.isBefore(validFrom) &&
        !checkedAt.isAfter(validTo) &&
        _sameBytes(certificateDer, presentedCertificateDer);
  }

  static bool _sameBytes(List<int> expected, List<int> actual) {
    if (expected.length != actual.length) return false;
    var difference = 0;
    for (var index = 0; index < expected.length; index++) {
      difference |= expected[index] ^ actual[index];
    }
    return difference == 0;
  }
}

class IotPinnedHttpOverrides extends HttpOverrides {
  static const String certificateAsset =
      'assets/certificates/iot_server_2024.pem';

  final IotPinnedCertificatePolicy policy;

  IotPinnedHttpOverrides._(this.policy);

  static Future<IotPinnedHttpOverrides> fromAsset({
    required String host,
    required int port,
    String assetPath = certificateAsset,
  }) async {
    final pem = await rootBundle.loadString(assetPath);
    return IotPinnedHttpOverrides._(
      IotPinnedCertificatePolicy(
        host: host,
        port: port,
        certificateDer: decodePemCertificate(pem),
      ),
    );
  }

  static Uint8List decodePemCertificate(String pem) {
    final encoded = pem
        .replaceAll('-----BEGIN CERTIFICATE-----', '')
        .replaceAll('-----END CERTIFICATE-----', '')
        .replaceAll(RegExp(r'\s'), '');
    if (encoded.isEmpty) {
      throw const FormatException('Pinned certificate is empty');
    }
    return base64Decode(encoded);
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (certificate, host, port) {
        return policy.allows(
          requestedHost: host,
          requestedPort: port,
          presentedCertificateDer: certificate.der,
          validFrom: certificate.startValidity,
          validTo: certificate.endValidity,
        );
      };
  }
}
