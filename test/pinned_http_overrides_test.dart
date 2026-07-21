import 'dart:io';
import 'dart:typed_data';

import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:dngmsp/app/viewmodel/pinned_http_overrides.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IotPinnedCertificatePolicy', () {
    final validFrom = DateTime.utc(2021, 5, 28);
    final validTo = DateTime.utc(2031, 5, 26);
    final policy = IotPinnedCertificatePolicy(
      host: '117.2.155.59',
      port: 2024,
      certificateDer: Uint8List.fromList(<int>[1, 2, 3, 4]),
    );

    test('allows only the exact host, port, certificate and validity', () {
      expect(
        policy.allows(
          requestedHost: '117.2.155.59',
          requestedPort: 2024,
          presentedCertificateDer: <int>[1, 2, 3, 4],
          validFrom: validFrom,
          validTo: validTo,
          now: DateTime.utc(2026),
        ),
        isTrue,
      );
    });

    test('rejects a different host, port or certificate', () {
      bool allows(String host, int port, List<int> certificate) {
        return policy.allows(
          requestedHost: host,
          requestedPort: port,
          presentedCertificateDer: certificate,
          validFrom: validFrom,
          validTo: validTo,
          now: DateTime.utc(2026),
        );
      }

      expect(allows('attacker.example', 2024, <int>[1, 2, 3, 4]), isFalse);
      expect(allows('117.2.155.59', 443, <int>[1, 2, 3, 4]), isFalse);
      expect(allows('117.2.155.59', 2024, <int>[1, 2, 3, 5]), isFalse);
    });

    test('rejects certificates outside their validity period', () {
      expect(
        policy.allows(
          requestedHost: '117.2.155.59',
          requestedPort: 2024,
          presentedCertificateDer: <int>[1, 2, 3, 4],
          validFrom: validFrom,
          validTo: validTo,
          now: DateTime.utc(2032),
        ),
        isFalse,
      );
    });

    test('loads the bundled X.509 certificate asset', () async {
      final pem = await rootBundle.loadString(
        IotPinnedHttpOverrides.certificateAsset,
      );
      final der = IotPinnedHttpOverrides.decodePemCertificate(pem);

      expect(der.length, greaterThan(1024));
      expect(der.take(2), orderedEquals(<int>[0x30, 0x82]));
    });

    test(
      'connects to the configured API using only the pinned certificate',
      () async {
        final uri = Uri.parse(IOT_REQUEST_URL);
        final overrides = await IotPinnedHttpOverrides.fromAsset(
          host: uri.host,
          port: uri.port,
        );
        final socket = await SecureSocket.connect(
          uri.host,
          uri.port,
          timeout: const Duration(seconds: 8),
          onBadCertificate: (certificate) => overrides.policy.allows(
            requestedHost: uri.host,
            requestedPort: uri.port,
            presentedCertificateDer: certificate.der,
            validFrom: certificate.startValidity,
            validTo: certificate.endValidity,
          ),
        );
        try {
          expect(socket.peerCertificate, isNotNull);
        } finally {
          socket.destroy();
        }
      },
      skip: !const bool.fromEnvironment('RUN_PINNED_TLS_NETWORK_TEST'),
    );
  });
}
