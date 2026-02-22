# SSL Pinning Implementation Guide

**Stack:** Flutter · Dio `^5.9.1` · Self-Hosted Supabase (Docker)  

---

## Overview

When the app talks to our self-hosted Supabase backend, it does so over HTTPS. By default, the app trusts any certificate signed by a recognized Certificate Authority (CA). This is the weak point — an attacker on the same network only needs a CA-signed certificate (any CA) to intercept traffic.

SSL Pinning fixes this by making the app reject any certificate that doesn't match a value we've explicitly trusted, even if it's a perfectly valid CA-signed cert.

> **This applies to our stack because we self-host.** On managed Supabase (Cloudflare), certificates rotate outside our control and pinning isn't feasible. Since we run Supabase in Docker, we own the certificates and can pin them.

### What We Pin

We use **Public Key Pinning (SPKI)** rather than full certificate pinning.

| Method | Behavior |
|---|---|
| Certificate Pinning | Pins the entire cert. Breaks on every renewal unless you ship an app update simultaneously. |
| **Public Key Pinning ✅** | Pins just the public key. Survives certificate renewal as long as the key pair is reused. |

---

## Prerequisites

- Supabase Docker instance running with HTTPS on Kong (port `8443`)
- A TLS certificate for your server (self-signed for dev, CA-issued for staging/prod)
- OpenSSL installed locally
- Flutter SDK ≥ 3.0 / Dart ≥ 3.0
- Required packages: `dio`, `crypto`, and `asn1lib`

Add these packages to `pubspec.yaml`:

```yaml
dependencies:
  dio: ^5.9.1
  crypto: ^3.0.7      # For SHA-256 hashing
  asn1lib: ^1.6.1     # For parsing X.509 certificate ASN.1 structure
```

---

## Extracting the Public Key Hash

The SHA-256 SPKI hash is what the app pins. You extract it from the server's certificate using OpenSSL. **Always extract two hashes — your current cert and your next/backup cert.**

### From a Certificate File

```bash
openssl x509 -in server.pem -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64
```

### From a Live Running Server

```bash
# Replace YOUR_HOST with your server IP or hostname
openssl s_client -connect YOUR_HOST:8443 </dev/null 2>/dev/null \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64
```

### Storing the Hashes

Store hashes in a dedicated constants file — never scatter them across the codebase.

```dart
// lib/core/security/ssl_pins.dart

class SslPins {
  SslPins._();

  /// SHA-256 SPKI hash of the current server public key.
  static const String primary = 'abc123XYZhash+in+base64+format=';

  /// SHA-256 SPKI hash of the backup/next server public key.
  /// Update this BEFORE rotating the primary cert on the server.
  static const String backup = 'xyz789BackupHash+base64+format=';

  static const List<String> all = [primary, backup];
}
```

> ⚠️ **Always keep at least two pins.** A single pin means any cert rotation will break the app for all users until a hotfix ships.

---

## Understanding X.509 Certificate Structure

Before implementing pinning, it helps to understand the X.509 certificate structure (RFC 5280):

```
Certificate ::= SEQUENCE {
  tbsCertificate       TBSCertificate,      [index 0] ← Contains the SPKI
  signatureAlgorithm   AlgorithmIdentifier, [index 1]
  signatureValue       BIT STRING           [index 2]
}

TBSCertificate ::= SEQUENCE {
  version              [0] EXPLICIT Version (optional),  [index 0]
  serialNumber         CertificateSerialNumber,          [index 1]
  signature            AlgorithmIdentifier,              [index 2]
  issuer               Name,                             [index 3]
  validity             Validity,                         [index 4]
  subject              Name,                             [index 5]
  subjectPublicKeyInfo SubjectPublicKeyInfo,             [index 6] ← TARGET
  ...
}
```

**Key Points:**
- The certificate is a DER-encoded ASN.1 SEQUENCE
- We navigate to `tbsCertificate.elements[6]` to get the SPKI
- The SPKI contains both the algorithm and the public key
- We hash the **entire SPKI structure** (not just the key itself)

---

## Dio Implementation

> ⚠️ **Dio 5.x Breaking Change**
> `DefaultHttpClientAdapter` from `package:dio/adapter.dart` no longer exists in Dio 5.x.
> The correct adapter is `IOHttpClientAdapter` from **`package:dio/io.dart`**.
> Any tutorial or code referencing `DefaultHttpClientAdapter` is outdated.

### The Pinned Client

```dart
// lib/core/network/pinned_dio_client.dart

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart'; // ← Dio 5.x: IOHttpClientAdapter lives here
import 'package:flutter/foundation.dart';
import 'package:asn1lib/asn1lib.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import '../security/ssl_pins.dart';

Dio createPinnedDio({required String baseUrl}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  // Pinning is only available on native platforms, not web
  if (!kIsWeb) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = _pinnedCertificateCallback;
        return client;
      },
    );
  }

  return dio;
}

/// Returns true only if the server certificate's public key
/// matches one of our pinned SPKI hashes.
bool _pinnedCertificateCallback(
  X509Certificate cert,
  String host,
  int port,
) {
  final publicKeyHash = _extractPublicKeyHash(cert.der);

  if (publicKeyHash == null) {
    AppLogger().tag('SslPinning').warning('Could not extract public key hash — rejecting.');
    return false;
  }

  final isPinned = SslPins.all.contains(publicKeyHash);

  if (!isPinned) {
    AppLogger().tag('SslPinning').error(
      '❌ REJECTED: $host:$port\n'
      'Expected one of: ${SslPins.all.join(", ")}\n'
      'Received: $publicKeyHash',
    );
  } else {
    AppLogger().tag('SslPinning').info('✅ ACCEPTED: $host:$port');
  }

  return isPinned;
}

/// Extracts the Subject Public Key Info (SPKI) from a certificate's DER bytes
/// and returns its SHA-256 hash in base64 format.
///
/// This implements public key pinning (not certificate pinning), which means
/// the pin survives certificate renewals as long as the same key pair is reused.
///
/// The hash produced matches the OpenSSL command:
/// openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
///
/// ⚠️ IMPORTANT: Hashing the entire certificate DER (cert.der) is NOT a recognized
/// pinning standard. The full certificate includes the signature and validity
/// window which change on every renewal, defeating the purpose of public key
/// pinning over certificate pinning.
String? _extractPublicKeyHash(Uint8List certificateDer) {
  try {
    // Step 1: Parse the X.509 certificate structure
    // Certificate ::= SEQUENCE { tbsCertificate, signatureAlgorithm, signature }
    final asn1Parser = ASN1Parser(certificateDer);
    final certificateSequence = asn1Parser.nextObject() as ASN1Sequence;

    if (certificateSequence.elements == null || certificateSequence.elements!.isEmpty) {
      AppLogger().tag('SslPinning').warning('Certificate sequence is empty');
      return null;
    }

    // Step 2: Extract the TBSCertificate (To-Be-Signed Certificate)
    // This is always the first element [index 0] of the certificate
    final tbsCertificate = certificateSequence.elements![0] as ASN1Sequence;

    if (tbsCertificate.elements == null || tbsCertificate.elements!.length < 7) {
      AppLogger().tag('SslPinning').warning('TBSCertificate has insufficient elements');
      return null;
    }

    // Step 3: Extract the SubjectPublicKeyInfo (SPKI)
    // TBSCertificate structure (RFC 5280):
    // [0] version (optional, explicit)
    // [1] serialNumber
    // [2] signature
    // [3] issuer
    // [4] validity
    // [5] subject
    // [6] subjectPublicKeyInfo ← This is what we need
    final subjectPublicKeyInfo = tbsCertificate.elements![6] as ASN1Sequence;

    // Step 4: Encode the SPKI back to DER bytes
    final spkiBytes = subjectPublicKeyInfo.encode();

    // Step 5: Hash the SPKI bytes with SHA-256
    final hash = sha256.convert(spkiBytes);

    // Step 6: Encode to base64 for comparison with pinned values
    return base64.encode(hash.bytes);

  } catch (e, stackTrace) {
    AppLogger().tag('SslPinning').error(
      'SPKI extraction failed: $e',
      e,
      stackTrace,
    );
    return null;
  }
}
```

> **Note:** We parse the certificate's ASN.1 structure to extract only the Subject Public Key Info (SPKI) field before hashing. This is the standard approach for public key pinning (RFC 7469) and matches what OpenSSL produces. Hashing the entire `cert.der` is incorrect because it includes the signature and validity dates which change on every renewal, defeating the purpose of public key pinning.

### Verifying Your Implementation

Before deploying, verify that your Dart implementation produces the same hash as OpenSSL:

**Step 1: Extract hash using OpenSSL**
```bash
openssl x509 -in your-cert.pem -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64
```

**Step 2: Test your Dart function**
```dart
import 'dart:io';

void main() {
  // Load your certificate
  final certPem = File('your-cert.pem').readAsStringSync();

  // Convert PEM to DER (remove headers and decode base64)
  final certBase64 = certPem
      .replaceAll('-----BEGIN CERTIFICATE-----', '')
      .replaceAll('-----END CERTIFICATE-----', '')
      .replaceAll('\n', '');
  final certDer = base64.decode(certBase64);

  // Extract hash using your implementation
  final hash = _extractPublicKeyHash(certDer);

  print('Dart implementation: $hash');
  print('Compare with OpenSSL output above');
}
```

**The hashes must match exactly.** If they don't, there's an error in the SPKI extraction.

---

## Environment Configuration

Never disable pinning silently. Use an explicit environment enum so pinning state is always intentional.

```dart
// lib/core/network/network_factory.dart

import 'package:dio/dio.dart';
import 'pinned_dio_client.dart';

enum AppEnvironment { development, staging, production }

class NetworkFactory {
  NetworkFactory._();

  static Dio create({
    required AppEnvironment env,
    required String baseUrl,
  }) {
    return switch (env) {
      // Dev: pinning disabled — allows local proxy debugging (Charles, Proxyman)
      AppEnvironment.development => _unpinnedDio(baseUrl: baseUrl),

      // Staging & Production: pinning always active
      AppEnvironment.staging ||
      AppEnvironment.production =>
        createPinnedDio(baseUrl: baseUrl),
    };
  }

  static Dio _unpinnedDio({required String baseUrl}) {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }
}
```

---

## Handling Pinning Failures

When pinning fails, Dio throws a `DioException`. Add an interceptor to surface a clear, actionable error instead of a generic network failure.

```dart
// lib/core/network/ssl_pinning_interceptor.dart

import 'dart:io';
import 'package:dio/dio.dart';

class SslPinningInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_isPinningFailure(err)) {
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          type: DioExceptionType.badCertificate,
          message:
              'SSL certificate does not match the pinned value. '
              'Connection blocked to prevent a MITM attack.',
          error: err.error,
        ),
      );
      return;
    }
    handler.next(err);
  }

  bool _isPinningFailure(DioException err) {
    return err.error is HandshakeException ||
        err.type == DioExceptionType.badCertificate;
  }
}
```

Register it when creating the Dio instance:

```dart
dio.interceptors.add(SslPinningInterceptor());
```

---

## Certificate Rotation Strategy

Failing to plan certificate rotation is the most common cause of production outages from SSL pinning. Follow this runbook every time a cert needs to change.

### The Two-Pin Rotation Process

1. Generate the new certificate/key pair on the server — **do not deploy it yet**
2. Extract the SPKI hash from the new certificate (see [Extracting the Public Key Hash](#extracting-the-public-key-hash))
3. Set `SslPins.backup` to the new hash — keep `SslPins.primary` pointing to the current live cert
4. Ship and release the app update — monitor crash rates and adoption
5. Once adoption is sufficient (2+ weeks), swap the new cert into Kong on your server
6. Update `SslPins.primary` to the new hash, set a new `SslPins.backup` for the next rotation
7. Ship the cleanup app update

---

## Server Configuration Reference

This section documents what may need configuring on the Docker/Kong side — either for the current local setup or as a reference when moving to production infrastructure.

### Current Setup: Self-Signed Certificate (Local/Dev)

```bash
# Generate a self-signed cert valid for 365 days
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout server.key \
  -out server.crt \
  -subj '/CN=your.internal.host/O=YourOrg/C=ET'
```

### Kong Gateway TLS (docker-compose.yml)

```yaml
kong:
  image: kong:latest
  environment:
    KONG_SSL_CERT: /etc/kong/certs/server.crt
    KONG_SSL_CERT_KEY: /etc/kong/certs/server.key
    KONG_PROXY_LISTEN: '0.0.0.0:8000, 0.0.0.0:8443 ssl'
  volumes:
    - ./certs:/etc/kong/certs:ro
  ports:
    - '8000:8000'
    - '8443:8443'
```

### Future: Production TLS with Let's Encrypt

When moving to a public domain on a real server, use Certbot. The 90-day validity pairs well with the two-pin rotation process.

```bash
# Obtain a certificate
certbot certonly --standalone -d api.yourdomain.com

# Extract the SPKI hash immediately after issuance
openssl x509 -in /etc/letsencrypt/live/api.yourdomain.com/cert.pem \
  -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64
```

---

## Testing

### Verifying Pinning Is Active

The quickest check: temporarily replace the pinned hash with a wrong value and confirm the app rejects the connection.

```dart
// In ssl_pins.dart — for testing only, revert immediately after
static const String primary = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';

// Expected: DioException with type badCertificate
// or a HandshakeException in the error field
```

### Unit Tests for Pin Constants

```dart
// test/core/security/ssl_pins_test.dart

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/security/ssl_pins.dart';

void main() {
  group('SslPins', () {
    test('contains at least two pins', () {
      expect(
        SslPins.all.length,
        greaterThanOrEqualTo(2),
        reason: 'Always maintain a backup pin for rotation.',
      );
    });

    test('all pins are valid base64', () {
      for (final pin in SslPins.all) {
        expect(
          () => base64.decode(pin),
          returnsNormally,
          reason: 'Pin "$pin" is not valid base64.',
        );
      }
    });

    test('no duplicate pins', () {
      expect(
        SslPins.all.toSet().length,
        equals(SslPins.all.length),
        reason: 'Duplicate pins detected.',
      );
    });
  });
}
```

### Testing with a Proxy (Charles / Proxyman)

With pinning active in staging, your proxy tool should **fail** to intercept traffic — that is the intended behavior and the proof pinning works.

- Use `AppEnvironment.development` for local debugging — proxy tools work freely there
- If a proxy succeeds in staging, pinning is not active — investigate the adapter setup

> ⚠️ Never install a proxy CA cert on a device used for production testing. If it accidentally ends up in a production build it completely defeats pinning.

---

## Best Practices

| Practice | Reason |
|---|---|
| Always maintain 2 active pins (primary + backup) | Enables zero-downtime certificate rotation |
| Use public key pinning, not certificate pinning | Survives cert renewal without an app update |
| Store pins in a single constants file | Single source of truth, easier to audit |
| Disable pinning only via an explicit environment enum | Prevents accidental deploy with pinning off |
| Log rejections in debug mode with host + received hash | Makes diagnosing mismatches much faster |
| Start rotation 30 days before cert expiry | Gives time for app adoption before cert swap |
| Add a CI test asserting `SslPins.all.length >= 2` | Catches accidental deletion of the backup pin |
| Never `return true` unconditionally in `badCertificateCallback` | Returning true always = pinning completely disabled |

---

## Troubleshooting

| Symptom | Likely Cause & Fix |
|---|---|
| `HandshakeException` on every request | Hash mismatch, re-extract the SPKI hash from the live server and compare with `SslPins.primary`. Ensure you're extracting the public key, not hashing the full cert. |
| Works on dev, fails on staging | Dev uses the unpinned client by design — check that `AppEnvironment` is set correctly |
| Pinning broke after cert renewal | New cert has a new public key — was the new SPKI hash added as `backup` before rotating? |
| Proxy interception succeeds on staging | Pinning is not active — verify `IOHttpClientAdapter` is wired up and env is not `development` |
| iOS works, Android fails (or vice versa) | Platform-specific cert chain issue — ensure the full chain (leaf + intermediates) is used for extraction |
| `DioExceptionType` is `connectionError` not `badCertificate` | Normal — some TLS failures surface as connection errors. Check `err.error` for `HandshakeException` |
| Hash never matches, even with correct cert | **You're hashing the wrong bytes.** Old/incorrect implementations hash the entire `cert.der`, which includes the signature and validity dates. You must parse the ASN.1 structure and extract only the SPKI field at index 6 of the TBSCertificate. |
| Pinning breaks on every renewal even with same key | **You're hashing the full certificate instead of the public key.** The certificate DER changes every renewal (new validity dates, new signature), but the public key stays the same. Extract and hash only the SPKI using the implementation above. |
| ASN1 parsing errors | Check that you're using `asn1lib: ^1.6.1` or later. Ensure the certificate is valid DER format. Try parsing with OpenSSL first to verify: `openssl x509 -in cert.pem -text -noout` |

---

## Quick Reference

### Extract SPKI Hash — One-liner

```bash
# From a file
openssl x509 -in server.pem -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64

# From a live server
openssl s_client -connect YOUR_HOST:8443 </dev/null 2>/dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
```