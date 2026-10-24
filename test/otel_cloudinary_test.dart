// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_cloudinary/otel_cloudinary.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_cloudinary-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('upload records resource + transformations + bytes', () async {
    await tracedCloudinary<String>(
      operation: 'upload',
      cloudName: 'acme',
      invoke: () async => const CloudinaryCallResult(
        value: 'ok',
        result: CloudinaryResult(
          publicId: 'samples/img1',
          resourceType: 'image',
          format: 'webp',
          transformationCount: 3,
          eager: true,
          bytes: 248192,
          width: 1920,
          height: 1080,
          cloudName: 'acme',
          usedAddon: 'imagga_tagging',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('cloudinary upload')!);
    expect(a['cloudinary.cloud_name'], 'acme');
    expect(a['cloudinary.transformation_count'], 3);
    expect(a['cloudinary.eager'], true);
    expect(a['cloudinary.bytes'], 248192);
    expect(a['cloudinary.format'], 'webp');
    expect(a['cloudinary.addon'], 'imagga_tagging');
  });

  test('video upload records duration', () async {
    await tracedCloudinary<String>(
      operation: 'upload.large',
      invoke: () async => const CloudinaryCallResult(
        value: 'ok',
        result: CloudinaryResult(
          resourceType: 'video',
          format: 'mp4',
          durationSec: 92.5,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('cloudinary upload.large')!);
    expect(a['cloudinary.resource_type'], 'video');
    expect(a['cloudinary.duration_sec'], 92.5);
  });

  test('suppression skips spans', () async {
    await runWithoutCloudinaryInstrumentationAsync(() async {
      await tracedCloudinary<String>(
        operation: 'resources.list',
        invoke: () async => const CloudinaryCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('cloudinary '), isEmpty);
  });
}
