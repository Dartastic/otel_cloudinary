// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_cloudinary_suppression.dart';

const _tracerName = 'dartastic_otel_libs_cloudinary';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class CloudinaryResult {
  const CloudinaryResult({
    this.publicId,
    this.resourceType,
    this.format,
    this.transformationCount,
    this.eager,
    this.bytes,
    this.width,
    this.height,
    this.durationSec,
    this.assetFolder,
    this.cloudName,
    this.usedAddon,
    this.requestId,
    this.statusCode,
  });

  /// `public_id`.
  final String? publicId;

  /// `image` / `video` / `raw` / `auto`.
  final String? resourceType;

  /// `jpg` / `png` / `webp` / `mp4` / `webm` / `mov` / ...
  final String? format;

  /// Number of `transformation` parameters applied — Cloudinary
  /// counts each chained transform against the monthly allowance.
  final int? transformationCount;

  /// True if eager transformations were requested at upload time
  /// (these pre-generate variants, billed up-front).
  final bool? eager;

  /// Final asset size in bytes.
  final int? bytes;

  final int? width;
  final int? height;

  /// Video duration when resource_type == video.
  final double? durationSec;

  /// `asset_folder` for asset-folder organization mode.
  final String? assetFolder;

  /// Cloud name (sub-account).
  final String? cloudName;

  /// AI add-on used (`url2png`, `aws_rek_*`, `imagga_tagging`,
  /// `google_translation`, `webpurify`, etc.) — each add-on is metered
  /// separately.
  final String? usedAddon;

  /// `X-Cld-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

class CloudinaryCallResult<T> {
  const CloudinaryCallResult({required this.value, this.result});
  final T value;
  final CloudinaryResult? result;
}

/// Wraps a Cloudinary API call in a CLIENT span. [operation] is one of
/// `upload`, `upload.large`, `explicit`, `destroy`, `rename`,
/// `transformation`, `multi`, `sprite`, `text`, `resources.list`,
/// `resources.search`, `tags.list`, `usage.get`, `admin.config`,
/// `webhook.notify`.
Future<T> tracedCloudinary<T>({
  required String operation,
  required Future<CloudinaryCallResult<T>> Function() invoke,
  String? cloudName,
}) async {
  if (cloudinaryInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'cloudinary',
    'rpc.method': operation,
    'cloudinary.operation': operation,
  };
  if (cloudName != null) m['cloudinary.cloud_name'] = cloudName;

  final span = _tracer().startSpan(
    'cloudinary $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.publicId != null) {
        extras.add(OTel.attributeString(
          'cloudinary.public_id',
          r.result!.publicId!,
        ));
      }
      if (r.result!.resourceType != null) {
        extras.add(OTel.attributeString(
          'cloudinary.resource_type',
          r.result!.resourceType!,
        ));
      }
      if (r.result!.format != null) {
        extras.add(OTel.attributeString(
          'cloudinary.format',
          r.result!.format!,
        ));
      }
      if (r.result!.transformationCount != null) {
        extras.add(OTel.attributeInt(
          'cloudinary.transformation_count',
          r.result!.transformationCount!,
        ));
      }
      if (r.result!.eager != null) {
        extras.add(OTel.attributeBool(
          'cloudinary.eager',
          r.result!.eager!,
        ));
      }
      if (r.result!.bytes != null) {
        extras.add(OTel.attributeInt(
          'cloudinary.bytes',
          r.result!.bytes!,
        ));
      }
      if (r.result!.width != null) {
        extras.add(OTel.attributeInt(
          'cloudinary.width',
          r.result!.width!,
        ));
      }
      if (r.result!.height != null) {
        extras.add(OTel.attributeInt(
          'cloudinary.height',
          r.result!.height!,
        ));
      }
      if (r.result!.durationSec != null) {
        extras.add(OTel.attributeDouble(
          'cloudinary.duration_sec',
          r.result!.durationSec!,
        ));
      }
      if (r.result!.assetFolder != null) {
        extras.add(OTel.attributeString(
          'cloudinary.asset_folder',
          r.result!.assetFolder!,
        ));
      }
      if (r.result!.cloudName != null) {
        extras.add(OTel.attributeString(
          'cloudinary.cloud_name',
          r.result!.cloudName!,
        ));
      }
      if (r.result!.usedAddon != null) {
        extras.add(OTel.attributeString(
          'cloudinary.addon',
          r.result!.usedAddon!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'cloudinary.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Cloudinary HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
