// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_cloudinary/otel_cloudinary.dart';

/// Traces Cloudinary calls with OpenTelemetry.
///
/// `otel_cloudinary` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Cloudinary call in
/// [tracedCloudinary]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'cloudinary-example');

  // Wraps a Cloudinary API call in a CLIENT span.
  final cloudinaryId = await tracedCloudinary<String>(
    operation: 'upload.large',
    cloudName: 'example',
    invoke: () async {
      // Make the Cloudinary call here, then report what it returned.
      const id = 'cloudinary_8f3a2c';
      return const CloudinaryCallResult(
          value: id,
          result: CloudinaryResult(
              publicId: 'public_id',
              resourceType: 'image',
              format: 'jpg',
              transformationCount: 3,
              eager: true,
              bytes: 512,
              width: 1,
              height: 1,
              durationSec: 0.5,
              assetFolder: 'asset_folder',
              cloudName: 'example',
              usedAddon: 'url2png',
              requestId: 'request_8f3a2c',
              statusCode: 200));
    },
  );
  OTelLog.info('tracedCloudinary upload.large returned $cloudinaryId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutCloudinaryInstrumentationAsync.
  await runWithoutCloudinaryInstrumentationAsync(
    () => tracedCloudinary<String>(
      operation: 'upload.large',
      cloudName: 'example',
      invoke: () async {
        const id = 'cloudinary_8f3a2c';
        return const CloudinaryCallResult(
            value: id,
            result: CloudinaryResult(
                publicId: 'public_id',
                resourceType: 'image',
                format: 'jpg',
                transformationCount: 3,
                eager: true,
                bytes: 512,
                width: 1,
                height: 1,
                durationSec: 0.5,
                assetFolder: 'asset_folder',
                cloudName: 'example',
                usedAddon: 'url2png',
                requestId: 'request_8f3a2c',
                statusCode: 200));
      },
    ),
  );

  await OTel.shutdown();
}
