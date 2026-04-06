import 'dart:io';

import 'package:qr/qr.dart';
import 'package:highway/toll_gate_data.dart';

void main() {
  final outputDir = Directory('exports/qrs');
  outputDir.createSync(recursive: true);

  for (final gate in TollGateCatalog.gates) {
    final fileName =
        '${gate.id}_${_slugify(gate.name)}.svg';
    final file = File('${outputDir.path}/$fileName');
    file.writeAsStringSync(_buildGateSvg(gate));
  }

  final indexFile = File('${outputDir.path}/README.txt');
  final buffer = StringBuffer()
    ..writeln('Generated gate QR image files')
    ..writeln()
    ..writeln('Each QR encodes the gate payload used by the app.')
    ..writeln();

  for (final gate in TollGateCatalog.gates) {
    buffer.writeln(
      '${gate.id} - ${gate.name}: ${gate.qrPayload}',
    );
  }

  indexFile.writeAsStringSync(buffer.toString());
  stdout.writeln('Generated ${TollGateCatalog.gates.length} QR SVG files in ${outputDir.path}');
}

String _buildGateSvg(TollGate gate) {
  final qrCode = QrCode.fromData(
    data: gate.qrPayload,
    errorCorrectLevel: QrErrorCorrectLevel.M,
  );
  final qrImage = QrImage(qrCode);

  const moduleSize = 10;
  const quietZone = 4;
  const cardPadding = 24;
  const labelHeight = 90;

  final qrSize = (qrImage.moduleCount + quietZone * 2) * moduleSize;
  final width = qrSize + cardPadding * 2;
  final height = qrSize + labelHeight + cardPadding * 2;

  final rects = <String>[];
  for (var row = 0; row < qrImage.moduleCount; row++) {
    for (var col = 0; col < qrImage.moduleCount; col++) {
      if (!qrImage.isDark(row, col)) {
        continue;
      }

      final x = cardPadding + (col + quietZone) * moduleSize;
      final y = cardPadding + (row + quietZone) * moduleSize;
      rects.add(
        '<rect x="$x" y="$y" width="$moduleSize" height="$moduleSize" fill="#111111"/>',
      );
    }
  }

  final qrTop = cardPadding;
  final qrBottom = qrTop + qrSize;
  final labelY = qrBottom + 24;

  return '''
<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height" role="img" aria-label="${_escapeXml(gate.name)} gate QR code">
  <rect width="$width" height="$height" rx="28" fill="#ffffff"/>
  <rect x="12" y="12" width="${width - 24}" height="${height - 24}" rx="22" fill="#f8fafc" stroke="#d7deea"/>
  <text x="${width / 2}" y="$labelY" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="28" font-weight="700" fill="#111827">${_escapeXml(gate.name)}</text>
  <text x="${width / 2}" y="${labelY + 30}" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="16" fill="#475569">${_escapeXml(gate.id)} | ${_escapeXml(gate.highway)}</text>
  <text x="${width / 2}" y="${labelY + 56}" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#64748b">${_escapeXml(gate.qrPayload)}</text>
  <rect x="$cardPadding" y="$cardPadding" width="$qrSize" height="$qrSize" rx="16" fill="#ffffff"/>
  ${rects.join('\n  ')}
</svg>
''';
}

String _slugify(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

String _escapeXml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
