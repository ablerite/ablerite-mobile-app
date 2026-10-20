// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final files =
      Directory('assets/images/self_help_covers')
          .listSync()
          .whereType<File>()
          .where(
            (file) => RegExp(
              r'/(main|health|wealth|relationships|career|spiritual|growth)-.*\.png$',
            ).hasMatch(file.path),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  const thumbW = 192;
  const thumbH = 108;
  const gap = 8;
  const columns = 6;
  final rows = (files.length / columns).ceil();
  final sheet = img.Image(
    width: columns * thumbW + (columns + 1) * gap,
    height: rows * thumbH + (rows + 1) * gap,
  );
  img.fill(sheet, color: img.ColorRgb8(9, 13, 18));

  for (var i = 0; i < files.length; i++) {
    final source = img.decodePng(files[i].readAsBytesSync());
    if (source == null) {
      throw StateError('Could not decode ${files[i].path}');
    }
    final thumb = img.copyResize(source, width: thumbW, height: thumbH);
    final x = gap + (i % columns) * (thumbW + gap);
    final y = gap + (i ~/ columns) * (thumbH + gap);
    img.compositeImage(sheet, thumb, dstX: x, dstY: y);
  }

  final output = File('/private/tmp/self-help-covers-contact.png');
  output.writeAsBytesSync(img.encodePng(sheet));
  print('Wrote ${output.path} with ${files.length} covers');
}
