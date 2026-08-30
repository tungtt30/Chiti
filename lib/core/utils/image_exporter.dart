import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Renders an off-screen "long report" widget to a high-resolution PNG and
/// offers share / gallery-save actions.
///
/// The report widget must be a plain non-scrolling [Column] (no `ListView`,
/// and no vertical `Expanded` / `Flexible` / `Spacer`), sized to a fixed
/// [maxWidth] so the exported image keeps the same layout as the on-screen
/// report.
///
/// Capture happens inside the **real widget tree** via a transparent
/// `OverlayEntry`: the report inherits Theme / MediaQuery / Localizations /
/// Directionality from the app, so widgets using `AppLocalizations.of` and
/// `Localizations.localeOf` work correctly. (Render-to-image utilities that
/// build their own isolated tree lack Localizations and produce empty/gray
/// images.)
class ImageExporter {
  ImageExporter._();

  static const double _pixelRatio = 3.0;
  static const Duration _captureDelay = Duration(milliseconds: 200);

  /// One-shot convenience: mounts [report], waits [delay] for the entry to be
  /// built and painted, rasterizes to PNG and tears the entry down.
  static Future<Uint8List> captureLongReport({
    required Widget report,
    required BuildContext context,
    double maxWidth = 400,
    double pixelRatio = _pixelRatio,
    Duration delay = _captureDelay,
  }) async {
    final capture = startCapture(
      report: report,
      context: context,
      maxWidth: maxWidth,
    );
    try {
      return await capture.rasterize(pixelRatio: pixelRatio, delay: delay);
    } finally {
      capture.dispose();
    }
  }

  /// Mounts the invisible capture entry for [report] and returns a session.
  ///
  /// The returned session must be rasterized (after a frame has painted the
  /// entry) and disposed. Keeping mount/rasterize/teardown separate lets
  /// widget tests drive each phase with explicit `pump`s.
  static ReportCapture startCapture({
    required Widget report,
    required BuildContext context,
    double maxWidth = 400,
  }) {
    final width = math.min(MediaQuery.sizeOf(context).width, maxWidth);
    final surface = Theme.of(context).colorScheme.surface;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      throw StateError('No root Overlay available for capture');
    }
    final boundaryKey = GlobalKey();

    // Transparent overlay entry: laid out at the report's natural height and
    // painted invisibly so the on-screen UI is never disturbed, while the
    // RepaintBoundary is fully painted and ready for toImage. OverflowBox
    // (not UnconstrainedBox, which reports debug overflow errors) lets the
    // report exceed the screen height silently. Opacity must stay > 0 —
    // RenderOpacity skips painting its child entirely when the alpha rounds
    // to 0, which yields an empty/gray capture (and trips the
    // !debugNeedsPaint assert in debug builds).
    final entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: Opacity(
          opacity: 0.01,
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            minHeight: 0,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: RepaintBoundary(
              key: boundaryKey,
              child: Material(
                color: surface,
                child: SizedBox(width: width, child: report),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    return ReportCapture._(entry: entry, boundaryKey: boundaryKey);
  }

  /// Writes [bytes] to a unique PNG in the app's temporary directory.
  static Future<File> writePng(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/chiti_report_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Opens the native share sheet with [file] attached.
  static Future<ShareResult> sharePng(
    File file, {
    required String text,
    String? subject,
  }) {
    return Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: text,
      subject: subject,
    );
  }

  /// Saves [file] to the device photo gallery (gal handles the API <= 28
  /// permission and API 29+ MediaStore write internally).
  static Future<void> saveToGallery(File file) async {
    if (!await Gal.hasAccess(toAlbum: false)) {
      await Gal.requestAccess(toAlbum: false);
    }
    await Gal.putImage(file.path);
  }
}

/// A mounted, invisible capture entry. Use with [ImageExporter.startCapture].
class ReportCapture {
  final OverlayEntry entry;
  final GlobalKey boundaryKey;

  ReportCapture._({required this.entry, required this.boundaryKey});

  /// Rasterizes the mounted report to PNG bytes.
  ///
  /// [delay] gives the entry a moment to build and paint when called right
  /// after [ImageExporter.startCapture]. In widget tests, pump a frame first
  /// and call this with a zero delay inside a single `runAsync` window.
  Future<Uint8List> rasterize({
    double pixelRatio = ImageExporter._pixelRatio,
    Duration delay = ImageExporter._captureDelay,
  }) async {
    await Future<void>.delayed(delay);
    final renderObject = boundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('Capture boundary not laid out');
    }
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      throw StateError('Failed to encode PNG');
    }
    return byteData.buffer.asUint8List();
  }

  /// Removes the capture entry from the overlay. Call exactly once.
  void dispose() => entry.remove();
}