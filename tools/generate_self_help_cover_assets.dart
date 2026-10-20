// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

const _width = 768;
const _height = 432;
const _outDir = 'assets/images/self_help_covers';

final _cards = <_CoverSpec>[
  _CoverSpec('main-health', 'Health', 'vitality', 0xFF6CC5AE, 1),
  _CoverSpec('main-wealth', 'Wealth', 'value', 0xFFE4C15F, 2),
  _CoverSpec(
    'main-relationships',
    'Relationships',
    'connection',
    0xFFD987B8,
    3,
  ),
  _CoverSpec('main-career', 'Career', 'direction', 0xFF82A8E8, 4),
  _CoverSpec('main-spiritual', 'Spiritual', 'meaning', 0xFFBBA2FF, 5),
  _CoverSpec('main-growth', 'Growth', 'evolution', 0xFF9FCE7A, 6),
  _CoverSpec('health-mini-courses', 'Health', 'practice path', 0xFF73D2AA, 7),
  _CoverSpec(
    'health-manifestation',
    'Health',
    'healthy identity',
    0xFF87CFF0,
    8,
  ),
  _CoverSpec('health-psychology', 'Health', 'mind body', 0xFFC0A9FF, 9),
  _CoverSpec('health-nutrition', 'Health', 'clean fuel', 0xFF8DDC78, 10),
  _CoverSpec('health-biohacking', 'Health', 'resilience', 0xFF5FD0C6, 11),
  _CoverSpec('health-longevity', 'Health', 'long life', 0xFFE6D36D, 12),
  _CoverSpec('wealth-mini-courses', 'Wealth', 'roadmap', 0xFFEAC46A, 13),
  _CoverSpec('wealth-manifestation', 'Wealth', 'abundance', 0xFF9CDFA7, 14),
  _CoverSpec('wealth-psychology', 'Wealth', 'money story', 0xFFB9A0F7, 15),
  _CoverSpec('wealth-investing', 'Wealth', 'asset growth', 0xFF8EC8FF, 16),
  _CoverSpec('wealth-side-hustles', 'Wealth', 'income stream', 0xFFFFAA70, 17),
  _CoverSpec('wealth-budgeting', 'Wealth', 'control', 0xFF77D7C5, 18),
  _CoverSpec(
    'relationships-mini-courses',
    'Relationships',
    'shared path',
    0xFFE797B8,
    19,
  ),
  _CoverSpec(
    'relationships-manifestation',
    'Relationships',
    'love vision',
    0xFFFFA3A3,
    20,
  ),
  _CoverSpec(
    'relationships-psychology',
    'Relationships',
    'attachment',
    0xFFC7A8FF,
    21,
  ),
  _CoverSpec(
    'relationships-resolution',
    'Relationships',
    'repair',
    0xFF83CFE6,
    22,
  ),
  _CoverSpec('relationships-dating', 'Relationships', 'choice', 0xFFFF8AB2, 23),
  _CoverSpec(
    'relationships-social',
    'Relationships',
    'community',
    0xFF9CDFA7,
    24,
  ),
  _CoverSpec('career-mini-courses', 'Career', 'skill path', 0xFF86B7F5, 25),
  _CoverSpec('career-manifestation', 'Career', 'work vision', 0xFFA7D7FF, 26),
  _CoverSpec('career-psychology', 'Career', 'performance', 0xFFC2A7F5, 27),
  _CoverSpec('career-leadership', 'Career', 'influence', 0xFFE4C15F, 28),
  _CoverSpec('career-speaking', 'Career', 'voice', 0xFFFFB37D, 29),
  _CoverSpec('career-productivity', 'Career', 'deep work', 0xFF77D7C5, 30),
  _CoverSpec(
    'spiritual-mini-courses',
    'Spiritual',
    'inner path',
    0xFFC4A7FF,
    31,
  ),
  _CoverSpec('spiritual-manifestation', 'Spiritual', 'purpose', 0xFF8DD3F4, 32),
  _CoverSpec('spiritual-psychology', 'Spiritual', 'presence', 0xFFD8B4FE, 33),
  _CoverSpec('spiritual-wisdom', 'Spiritual', 'wisdom', 0xFFE9D27C, 34),
  _CoverSpec('spiritual-quantum', 'Spiritual', 'possibility', 0xFF90E0D0, 35),
  _CoverSpec('spiritual-stoicism', 'Spiritual', 'steadiness', 0xFFA7B4D7, 36),
  _CoverSpec('growth-mini-courses', 'Growth', 'growth path', 0xFFA9D978, 37),
  _CoverSpec('growth-manifestation', 'Growth', 'future self', 0xFF89CFF0, 38),
  _CoverSpec('growth-psychology', 'Growth', 'self awareness', 0xFFC2A7F5, 39),
  _CoverSpec('growth-discipline', 'Growth', 'consistency', 0xFFE8C86B, 40),
  _CoverSpec('growth-time-mgmt', 'Growth', 'time design', 0xFF86B7F5, 41),
  _CoverSpec('growth-confidence', 'Growth', 'self trust', 0xFFFFA3A3, 42),
];

void main() {
  final out = Directory(_outDir)..createSync(recursive: true);
  for (final spec in _cards) {
    final image = _renderCover(spec);
    final file = File('${out.path}/${spec.slug}.png');
    file.writeAsBytesSync(img.encodePng(image, level: 6));
  }
  print('Generated ${_cards.length} self-help cover assets in ${out.path}');
}

img.Image _renderCover(_CoverSpec spec) {
  final image = img.Image(width: _width, height: _height);
  final accent = _rgb(spec.accent);
  final seed = spec.seed;

  for (var y = 0; y < _height; y++) {
    for (var x = 0; x < _width; x++) {
      final nx = x / (_width - 1);
      final ny = y / (_height - 1);
      final glow = max(
        0.0,
        1.0 -
            sqrt(
                  pow(nx - (0.62 + sin(seed) * 0.12), 2) +
                      pow(ny - (0.45 + cos(seed) * 0.1), 2),
                ) *
                1.55,
      );
      final weave =
          (sin((x + seed * 17) * 0.018) + cos((y - seed * 11) * 0.026)) * 3.0;
      final edgeShade = (1.0 - max((nx - .5).abs(), (ny - .5).abs()) * 1.15)
          .clamp(0.52, 1.0);
      final r = ((8 + accent.r * glow * 0.28 + weave) * edgeShade).round();
      final g = ((13 + accent.g * glow * 0.26 + weave) * edgeShade).round();
      final b = ((18 + accent.b * glow * 0.31 + weave) * edgeShade).round();
      image.setPixelRgb(
        x,
        y,
        r.clamp(2, 255),
        g.clamp(2, 255),
        b.clamp(4, 255),
      );
    }
  }

  _drawBackgroundPattern(image, accent, spec);
  _drawMotif(image, spec, accent);
  _drawFrame(image, accent);

  return image;
}

void _drawBackgroundPattern(img.Image image, _Rgb accent, _CoverSpec spec) {
  final c = img.ColorRgba8(accent.r, accent.g, accent.b, 34);
  final light = img.ColorRgba8(226, 238, 240, 24);
  final variant = spec.seed % 7;
  switch (variant) {
    case 0:
      for (var i = 0; i < 9; i++) {
        final y = 34 + i * 46 + (spec.seed % 4) * 5;
        img.drawLine(
          image,
          x1: 46,
          y1: y,
          x2: _width - 46,
          y2: y + ((i.isEven ? 1 : -1) * (18 + spec.seed % 22)),
          color: i.isEven ? c : light,
          thickness: i.isEven ? 2 : 1,
          antialias: true,
        );
      }
      break;
    case 1:
      for (var i = 0; i < 6; i++) {
        final x = 44 + i * 126 + (spec.seed % 5) * 6;
        img.fillRect(
          image,
          x1: x,
          y1: 34,
          x2: x + 48,
          y2: _height - 30,
          color: i.isEven
              ? c
              : img.ColorRgba8(accent.r, accent.g, accent.b, 18),
          radius: 26,
        );
      }
      break;
    case 2:
      for (var i = 0; i < 7; i++) {
        final y = 68 + i * 42;
        for (var x = 34; x < _width - 34; x += 44) {
          final waveY = y + (sin((x + spec.seed * 13) * 0.025) * 18).round();
          img.fillCircle(
            image,
            x: x,
            y: waveY,
            radius: i.isEven ? 4 : 3,
            color: i.isEven ? c : light,
            antialias: true,
          );
        }
      }
      break;
    case 3:
      for (var ring = 0; ring < 5; ring++) {
        final radius = 62 + ring * 42;
        img.drawCircle(
          image,
          x: 120 + (spec.seed % 5) * 22,
          y: 92 + (spec.seed % 4) * 28,
          radius: radius,
          color: ring.isEven ? c : light,
          antialias: true,
        );
      }
      for (var ring = 0; ring < 4; ring++) {
        img.drawCircle(
          image,
          x: _width - 120 - (spec.seed % 3) * 28,
          y: _height - 86 - (spec.seed % 4) * 20,
          radius: 44 + ring * 38,
          color: ring.isEven ? light : c,
          antialias: true,
        );
      }
      break;
    case 4:
      for (var i = 0; i < 11; i++) {
        final angle = -0.9 + i * 0.18;
        img.drawLine(
          image,
          x1: _width ~/ 2,
          y1: _height + 60,
          x2: (_width / 2 + cos(angle) * 560).round(),
          y2: (_height + 60 - sin(angle) * 520).round(),
          color: i.isEven ? c : light,
          thickness: 3,
          antialias: true,
        );
      }
      break;
    case 5:
      for (var i = 0; i < 10; i++) {
        final x1 = -40 + i * 92;
        img.drawLine(
          image,
          x1: x1,
          y1: _height - 20,
          x2: x1 + 180,
          y2: 28,
          color: i.isEven ? c : light,
          thickness: i.isEven ? 3 : 1,
          antialias: true,
        );
      }
      break;
    default:
      for (var i = 0; i < 24; i++) {
        final x = 36 + ((i * 83 + spec.seed * 19) % (_width - 72));
        final y = 36 + ((i * 47 + spec.seed * 29) % (_height - 72));
        img.fillCircle(
          image,
          x: x,
          y: y,
          radius: 5 + (i + spec.seed) % 12,
          color: i.isEven ? c : light,
          antialias: true,
        );
      }
  }
  _drawCornerSignature(image, accent, spec);
}

void _drawCornerSignature(img.Image image, _Rgb accent, _CoverSpec spec) {
  final c = img.ColorRgba8(accent.r, accent.g, accent.b, 130);
  final x = spec.seed.isEven ? 56 : _width - 176;
  final y = spec.seed % 3 == 0 ? _height - 64 : 54;
  switch (spec.seed % 4) {
    case 0:
      img.fillRect(
        image,
        x1: x,
        y1: y,
        x2: x + 108,
        y2: y + 10,
        color: c,
        radius: 5,
      );
      img.fillRect(
        image,
        x1: x,
        y1: y + 22,
        x2: x + 64,
        y2: y + 30,
        color: img.ColorRgba8(226, 238, 240, 60),
        radius: 4,
      );
      break;
    case 1:
      for (var i = 0; i < 4; i++) {
        img.fillCircle(
          image,
          x: x + i * 28,
          y: y + (i.isEven ? 0 : 20),
          radius: 8,
          color: c,
          antialias: true,
        );
      }
      break;
    case 2:
      img.drawLine(
        image,
        x1: x,
        y1: y + 28,
        x2: x + 116,
        y2: y,
        color: c,
        thickness: 5,
        antialias: true,
      );
      img.drawLine(
        image,
        x1: x,
        y1: y + 52,
        x2: x + 82,
        y2: y + 30,
        color: img.ColorRgba8(226, 238, 240, 60),
        thickness: 4,
        antialias: true,
      );
      break;
    default:
      img.drawCircle(
        image,
        x: x + 36,
        y: y + 20,
        radius: 24,
        color: c,
        antialias: true,
      );
      img.drawCircle(
        image,
        x: x + 84,
        y: y + 20,
        radius: 24,
        color: img.ColorRgba8(226, 238, 240, 60),
        antialias: true,
      );
  }
}

void _drawMotif(img.Image image, _CoverSpec spec, _Rgb accent) {
  final cx = 384 + ((spec.seed % 5) - 2) * 12;
  final cy = 204 + ((spec.seed % 7) - 3) * 6;
  final primary = img.ColorRgba8(accent.r, accent.g, accent.b, 215);
  final secondary = img.ColorRgba8(225, 238, 242, 116);
  final dim = img.ColorRgba8(accent.r, accent.g, accent.b, 72);

  switch (spec.slug) {
    case 'main-health':
      _drawLeafCluster(image, cx - 72, cy + 14, primary, secondary);
      _drawPulse(image, cx + 104, cy - 24, secondary, primary);
      break;
    case 'main-wealth':
      _drawCoinStack(image, cx - 74, cy + 44, primary, secondary);
      _drawChartArrow(image, cx + 82, cy - 32, secondary, primary);
      break;
    case 'main-relationships':
      _drawPeople(image, cx - 78, cy + 20, primary, secondary);
      _drawHeart(image, cx + 96, cy - 34, secondary, primary);
      break;
    case 'main-career':
      _drawBriefcase(image, cx - 82, cy + 20, primary, secondary);
      _drawCompass(image, cx + 102, cy - 22, secondary, primary, dim);
      break;
    case 'main-spiritual':
      _drawLotus(image, cx - 70, cy + 30, primary, secondary);
      _drawOrbit(image, cx + 96, cy - 32, secondary, primary, dim);
      break;
    case 'main-growth':
      _drawSeedling(image, cx - 88, cy + 34, primary, secondary);
      _drawSteps(image, cx + 96, cy - 12, secondary, primary);
      break;
    case 'health-mini-courses':
      _drawBookPath(image, cx - 92, cy + 14, primary, secondary);
      _drawCalendar(image, cx + 104, cy - 28, secondary, primary);
      break;
    case 'health-manifestation':
      _drawMirrorFigure(image, cx - 72, cy + 18, primary, secondary);
      _drawOrbit(image, cx + 112, cy - 32, secondary, primary, dim);
      break;
    case 'health-psychology':
      _drawBrain(image, cx - 78, cy - 4, primary, secondary);
      _drawPulse(image, cx + 108, cy + 26, secondary, primary);
      break;
    case 'health-nutrition':
      _drawBowl(image, cx - 82, cy + 30, primary, secondary);
      _drawLeafCluster(image, cx + 106, cy - 24, secondary, primary);
      break;
    case 'health-biohacking':
      _drawCircuitNodes(image, cx - 88, cy + 4, primary, secondary, dim);
      _drawShield(image, cx + 108, cy - 10, secondary, primary);
      break;
    case 'health-longevity':
      _drawHourglass(image, cx - 84, cy + 8, primary, secondary);
      _drawMountainFlag(image, cx + 104, cy + 6, secondary, primary, dim);
      break;
    case 'wealth-mini-courses':
      _drawMapRoute(image, cx - 80, cy + 8, primary, secondary, dim);
      _drawCoinStack(image, cx + 112, cy + 20, secondary, primary);
      break;
    case 'wealth-manifestation':
      _drawOpenHands(image, cx - 84, cy + 24, primary, secondary);
      _drawCoinStack(image, cx + 112, cy - 20, secondary, primary);
      break;
    case 'wealth-psychology':
      _drawBrain(image, cx - 86, cy - 6, primary, secondary);
      _drawCoinStack(image, cx + 102, cy + 38, secondary, primary);
      break;
    case 'wealth-investing':
      _drawChartArrow(image, cx - 82, cy + 28, primary, secondary);
      _drawCompass(image, cx + 112, cy - 28, secondary, primary, dim);
      break;
    case 'wealth-side-hustles':
      _drawBriefcase(image, cx - 86, cy + 22, primary, secondary);
      _drawFlame(image, cx + 112, cy - 14, secondary, primary);
      break;
    case 'wealth-budgeting':
      _drawLedger(image, cx - 84, cy + 16, primary, secondary);
      _drawCoinStack(image, cx + 112, cy + 24, secondary, primary);
      break;
    case 'relationships-mini-courses':
      _drawBookPath(image, cx - 92, cy + 14, primary, secondary);
      _drawPeople(image, cx + 106, cy - 18, secondary, primary);
      break;
    case 'relationships-manifestation':
      _drawHeart(image, cx - 88, cy + 12, primary, secondary);
      _drawOrbit(image, cx + 108, cy - 26, secondary, primary, dim);
      break;
    case 'relationships-psychology':
      _drawAttachmentRings(image, cx - 82, cy + 8, primary, secondary, dim);
      _drawBrain(image, cx + 112, cy - 20, secondary, primary);
      break;
    case 'relationships-resolution':
      _drawHandshake(image, cx - 80, cy + 18, primary, secondary);
      _drawBridge(image, cx + 110, cy + 10, secondary, primary);
      break;
    case 'relationships-dating':
      _drawCompass(image, cx - 80, cy + 4, primary, secondary, dim);
      _drawHeart(image, cx + 112, cy - 16, secondary, primary);
      break;
    case 'relationships-social':
      _drawPeople(image, cx - 84, cy + 12, primary, secondary);
      _drawMindMap(image, cx + 112, cy - 14, secondary, primary, dim);
      break;
    case 'career-mini-courses':
      _drawBookPath(image, cx - 88, cy + 14, primary, secondary);
      _drawBriefcase(image, cx + 112, cy - 4, secondary, primary);
      break;
    case 'career-manifestation':
      _drawCompass(image, cx - 84, cy + 8, primary, secondary, dim);
      _drawMountainFlag(image, cx + 108, cy + 4, secondary, primary, dim);
      break;
    case 'career-psychology':
      _drawBrain(image, cx - 84, cy - 4, primary, secondary);
      _drawTarget(image, cx + 112, cy - 8, secondary, primary, dim);
      break;
    case 'career-leadership':
      _drawPeople(image, cx - 92, cy + 18, primary, secondary);
      _drawFlag(image, cx + 112, cy - 8, secondary, primary);
      break;
    case 'career-speaking':
      _drawMicrophone(image, cx - 80, cy + 8, primary, secondary);
      _drawPulse(image, cx + 112, cy + 20, secondary, primary);
      break;
    case 'career-productivity':
      _drawClock(image, cx - 82, cy + 2, primary, secondary);
      _drawSteps(image, cx + 112, cy + 12, secondary, primary);
      break;
    case 'spiritual-mini-courses':
      _drawBookPath(image, cx - 90, cy + 16, primary, secondary);
      _drawLotus(image, cx + 112, cy - 14, secondary, primary);
      break;
    case 'spiritual-manifestation':
      _drawLotus(image, cx - 88, cy + 20, primary, secondary);
      _drawOrbit(image, cx + 112, cy - 22, secondary, primary, dim);
      break;
    case 'spiritual-psychology':
      _drawBrain(image, cx - 86, cy - 4, primary, secondary);
      _drawLotus(image, cx + 112, cy + 12, secondary, primary);
      break;
    case 'spiritual-wisdom':
      _drawScroll(image, cx - 84, cy + 12, primary, secondary);
      _drawFlame(image, cx + 112, cy - 20, secondary, primary);
      break;
    case 'spiritual-quantum':
      _drawOrbit(image, cx - 84, cy - 2, primary, secondary, dim);
      _drawCircuitNodes(image, cx + 112, cy + 8, secondary, primary, dim);
      break;
    case 'spiritual-stoicism':
      _drawShield(image, cx - 80, cy + 2, primary, secondary);
      _drawColumn(image, cx + 112, cy + 8, secondary, primary);
      break;
    case 'growth-mini-courses':
      _drawBookPath(image, cx - 90, cy + 16, primary, secondary);
      _drawSeedling(image, cx + 112, cy + 16, secondary, primary);
      break;
    case 'growth-manifestation':
      _drawMirrorFigure(image, cx - 82, cy + 18, primary, secondary);
      _drawSeedling(image, cx + 112, cy + 18, secondary, primary);
      break;
    case 'growth-psychology':
      _drawBrain(image, cx - 84, cy - 4, primary, secondary);
      _drawMirrorFigure(image, cx + 112, cy + 18, secondary, primary);
      break;
    case 'growth-discipline':
      _drawShield(image, cx - 80, cy + 4, primary, secondary);
      _drawSteps(image, cx + 112, cy + 12, secondary, primary);
      break;
    case 'growth-time-mgmt':
      _drawClock(image, cx - 84, cy + 2, primary, secondary);
      _drawCalendar(image, cx + 112, cy - 8, secondary, primary);
      break;
    case 'growth-confidence':
      _drawMountainFlag(image, cx - 86, cy + 6, primary, secondary, dim);
      _drawHeart(image, cx + 112, cy - 12, secondary, primary);
      break;
    default:
      _drawTarget(image, cx, cy, primary, secondary, dim);
  }
}

void _drawLeafCluster(
  img.Image image,
  int cx,
  int cy,
  img.Color c,
  img.Color s,
) {
  for (var i = -2; i <= 2; i++) {
    img.drawLine(
      image,
      x1: cx,
      y1: cy + 74,
      x2: cx + i * 34,
      y2: cy - 12 - (2 - i.abs()) * 18,
      color: c,
      thickness: 10,
      antialias: true,
    );
    img.fillCircle(
      image,
      x: cx + i * 34,
      y: cy - 22 - (2 - i.abs()) * 18,
      radius: 22,
      color: s,
      antialias: true,
    );
  }
  img.fillCircle(
    image,
    x: cx,
    y: cy + 74,
    radius: 26,
    color: c,
    antialias: true,
  );
}

void _drawOrbit(
  img.Image image,
  int cx,
  int cy,
  img.Color c,
  img.Color s,
  img.Color d,
) {
  for (var r in [46, 78, 112]) {
    img.drawCircle(image, x: cx, y: cy, radius: r, color: d, antialias: true);
  }
  for (var i = 0; i < 6; i++) {
    final a = i * pi / 3;
    img.fillCircle(
      image,
      x: cx + (cos(a) * 110).round(),
      y: cy + (sin(a) * 62).round(),
      radius: i == 0 ? 18 : 12,
      color: i == 0 ? s : c,
      antialias: true,
    );
  }
  img.fillCircle(image, x: cx, y: cy, radius: 38, color: c, antialias: true);
}

void _drawBridge(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  for (var i = 0; i < 4; i++) {
    final y = cy + 72 - i * 34;
    img.drawLine(
      image,
      x1: cx - 134 + i * 32,
      y1: y,
      x2: cx + 134 - i * 32,
      y2: y,
      color: c,
      thickness: 10,
      antialias: true,
    );
  }
  img.drawLine(
    image,
    x1: cx - 142,
    y1: cy + 86,
    x2: cx,
    y2: cy - 70,
    color: s,
    thickness: 9,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx + 142,
    y1: cy + 86,
    x2: cx,
    y2: cy - 70,
    color: s,
    thickness: 9,
    antialias: true,
  );
}

void _drawSteps(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  for (var i = 0; i < 5; i++) {
    img.fillRect(
      image,
      x1: cx - 130 + i * 34,
      y1: cy + 74 - i * 34,
      x2: cx - 28 + i * 34,
      y2: cy + 92 - i * 34,
      color: i.isEven ? c : s,
      radius: 8,
    );
  }
  img.fillCircle(
    image,
    x: cx + 118,
    y: cy - 84,
    radius: 28,
    color: s,
    antialias: true,
  );
}

void _drawCompass(
  img.Image image,
  int cx,
  int cy,
  img.Color c,
  img.Color s,
  img.Color d,
) {
  img.drawCircle(image, x: cx, y: cy, radius: 104, color: c, antialias: true);
  img.drawCircle(image, x: cx, y: cy, radius: 68, color: d, antialias: true);
  img.drawLine(
    image,
    x1: cx,
    y1: cy - 92,
    x2: cx + 36,
    y2: cy + 24,
    color: s,
    thickness: 12,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx,
    y1: cy + 92,
    x2: cx - 36,
    y2: cy - 24,
    color: c,
    thickness: 12,
    antialias: true,
  );
}

void _drawFlame(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  img.fillCircle(
    image,
    x: cx,
    y: cy + 40,
    radius: 72,
    color: c,
    antialias: true,
  );
  img.fillCircle(
    image,
    x: cx + 34,
    y: cy - 8,
    radius: 48,
    color: c,
    antialias: true,
  );
  img.fillCircle(
    image,
    x: cx - 24,
    y: cy - 34,
    radius: 38,
    color: s,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx,
    y1: cy + 106,
    x2: cx + 66,
    y2: cy - 94,
    color: s,
    thickness: 12,
    antialias: true,
  );
}

void _drawBookPath(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  img.fillRect(
    image,
    x1: cx - 126,
    y1: cy - 48,
    x2: cx - 8,
    y2: cy + 76,
    color: c,
    radius: 18,
  );
  img.fillRect(
    image,
    x1: cx + 8,
    y1: cy - 48,
    x2: cx + 126,
    y2: cy + 76,
    color: s,
    radius: 18,
  );
  img.drawLine(
    image,
    x1: cx,
    y1: cy - 52,
    x2: cx,
    y2: cy + 86,
    color: img.ColorRgba8(14, 21, 28, 160),
    thickness: 5,
    antialias: true,
  );
  for (var i = 0; i < 4; i++) {
    img.drawLine(
      image,
      x1: cx - 94,
      y1: cy - 16 + i * 22,
      x2: cx - 34,
      y2: cy - 16 + i * 22,
      color: img.ColorRgba8(10, 18, 24, 85),
      thickness: 4,
      antialias: true,
    );
    img.drawLine(
      image,
      x1: cx + 34,
      y1: cy - 16 + i * 22,
      x2: cx + 94,
      y2: cy - 16 + i * 22,
      color: img.ColorRgba8(10, 18, 24, 85),
      thickness: 4,
      antialias: true,
    );
  }
}

void _drawPulse(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  img.drawLine(
    image,
    x1: cx - 150,
    y1: cy,
    x2: cx - 72,
    y2: cy,
    color: c,
    thickness: 8,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx - 72,
    y1: cy,
    x2: cx - 42,
    y2: cy - 62,
    color: s,
    thickness: 8,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx - 42,
    y1: cy - 62,
    x2: cx + 4,
    y2: cy + 62,
    color: s,
    thickness: 8,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx + 4,
    y1: cy + 62,
    x2: cx + 48,
    y2: cy - 26,
    color: c,
    thickness: 8,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx + 48,
    y1: cy - 26,
    x2: cx + 150,
    y2: cy - 26,
    color: c,
    thickness: 8,
    antialias: true,
  );
}

void _drawMindMap(
  img.Image image,
  int cx,
  int cy,
  img.Color c,
  img.Color s,
  img.Color d,
) {
  final points = <img.Point>[
    img.Point(cx, cy),
    img.Point(cx - 100, cy - 54),
    img.Point(cx + 104, cy - 46),
    img.Point(cx - 82, cy + 70),
    img.Point(cx + 92, cy + 74),
  ];
  for (final p in points.skip(1)) {
    img.drawLine(
      image,
      x1: cx,
      y1: cy,
      x2: p.x.toInt(),
      y2: p.y.toInt(),
      color: d,
      thickness: 5,
      antialias: true,
    );
  }
  for (var i = 0; i < points.length; i++) {
    img.fillCircle(
      image,
      x: points[i].x.toInt(),
      y: points[i].y.toInt(),
      radius: i == 0 ? 38 : 24,
      color: i.isEven ? c : s,
      antialias: true,
    );
  }
}

void _drawBowl(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  img.fillRect(
    image,
    x1: cx - 132,
    y1: cy + 16,
    x2: cx + 132,
    y2: cy + 82,
    color: c,
    radius: 42,
  );
  img.drawLine(
    image,
    x1: cx - 106,
    y1: cy + 4,
    x2: cx + 106,
    y2: cy + 4,
    color: s,
    thickness: 10,
    antialias: true,
  );
  for (var i = 0; i < 6; i++) {
    img.fillCircle(
      image,
      x: cx - 86 + i * 34,
      y: cy - 22 - (i % 2) * 14,
      radius: 18,
      color: i.isEven ? s : c,
      antialias: true,
    );
  }
}

void _drawShield(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  final vertices = [
    img.Point(cx, cy - 108),
    img.Point(cx + 104, cy - 58),
    img.Point(cx + 72, cy + 84),
    img.Point(cx, cy + 126),
    img.Point(cx - 72, cy + 84),
    img.Point(cx - 104, cy - 58),
  ];
  img.fillPolygon(image, vertices: vertices, color: c);
  img.drawLine(
    image,
    x1: cx - 44,
    y1: cy + 4,
    x2: cx - 8,
    y2: cy + 44,
    color: s,
    thickness: 12,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx - 8,
    y1: cy + 44,
    x2: cx + 58,
    y2: cy - 42,
    color: s,
    thickness: 12,
    antialias: true,
  );
}

void _drawMountainFlag(
  img.Image image,
  int cx,
  int cy,
  img.Color c,
  img.Color s,
  img.Color d,
) {
  img.fillPolygon(
    image,
    vertices: [
      img.Point(cx - 150, cy + 100),
      img.Point(cx - 44, cy - 70),
      img.Point(cx + 24, cy + 100),
    ],
    color: d,
  );
  img.fillPolygon(
    image,
    vertices: [
      img.Point(cx - 20, cy + 100),
      img.Point(cx + 82, cy - 30),
      img.Point(cx + 150, cy + 100),
    ],
    color: c,
  );
  img.drawLine(
    image,
    x1: cx,
    y1: cy + 96,
    x2: cx,
    y2: cy - 114,
    color: s,
    thickness: 8,
    antialias: true,
  );
  img.fillPolygon(
    image,
    vertices: [
      img.Point(cx + 2, cy - 112),
      img.Point(cx + 104, cy - 82),
      img.Point(cx + 2, cy - 52),
    ],
    color: s,
  );
}

void _drawCoinStack(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  for (var i = 0; i < 5; i++) {
    final y = cy + 72 - i * 26;
    img.fillCircle(
      image,
      x: cx,
      y: y,
      radius: 56,
      color: i.isEven ? c : s,
      antialias: true,
    );
    img.drawLine(
      image,
      x1: cx - 48,
      y1: y,
      x2: cx + 48,
      y2: y,
      color: img.ColorRgba8(10, 18, 24, 80),
      thickness: 6,
      antialias: true,
    );
  }
  img.fillCircle(
    image,
    x: cx + 82,
    y: cy - 48,
    radius: 30,
    color: s,
    antialias: true,
  );
}

void _drawChartArrow(
  img.Image image,
  int cx,
  int cy,
  img.Color c,
  img.Color s,
) {
  for (var i = 0; i < 5; i++) {
    img.fillRect(
      image,
      x1: cx - 132 + i * 52,
      y1: cy + 94 - i * 28,
      x2: cx - 102 + i * 52,
      y2: cy + 112,
      color: i.isEven ? c : s,
      radius: 8,
    );
  }
  img.drawLine(
    image,
    x1: cx - 140,
    y1: cy + 74,
    x2: cx + 120,
    y2: cy - 82,
    color: s,
    thickness: 10,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx + 120,
    y1: cy - 82,
    x2: cx + 84,
    y2: cy - 78,
    color: s,
    thickness: 10,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx + 120,
    y1: cy - 82,
    x2: cx + 106,
    y2: cy - 48,
    color: s,
    thickness: 10,
    antialias: true,
  );
}

void _drawHeart(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  img.fillCircle(
    image,
    x: cx - 38,
    y: cy - 28,
    radius: 48,
    color: c,
    antialias: true,
  );
  img.fillCircle(
    image,
    x: cx + 38,
    y: cy - 28,
    radius: 48,
    color: c,
    antialias: true,
  );
  img.fillPolygon(
    image,
    vertices: [
      img.Point(cx - 86, cy - 6),
      img.Point(cx + 86, cy - 6),
      img.Point(cx, cy + 118),
    ],
    color: c,
  );
  img.drawLine(
    image,
    x1: cx - 42,
    y1: cy + 20,
    x2: cx - 4,
    y2: cy + 54,
    color: s,
    thickness: 8,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx - 4,
    y1: cy + 54,
    x2: cx + 54,
    y2: cy - 12,
    color: s,
    thickness: 8,
    antialias: true,
  );
}

void _drawPeople(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  for (final item in [
    (x: -70, r: 34, color: c),
    (x: 0, r: 42, color: s),
    (x: 72, r: 34, color: c),
  ]) {
    img.fillCircle(
      image,
      x: cx + item.x,
      y: cy - 52,
      radius: item.r,
      color: item.color,
      antialias: true,
    );
    img.fillRect(
      image,
      x1: cx + item.x - item.r - 18,
      y1: cy - 8,
      x2: cx + item.x + item.r + 18,
      y2: cy + 86,
      color: item.color,
      radius: 44,
    );
  }
}

void _drawBriefcase(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  img.fillRect(
    image,
    x1: cx - 128,
    y1: cy - 40,
    x2: cx + 128,
    y2: cy + 96,
    color: c,
    radius: 22,
  );
  img.fillRect(
    image,
    x1: cx - 54,
    y1: cy - 86,
    x2: cx + 54,
    y2: cy - 36,
    color: s,
    radius: 18,
  );
  img.drawLine(
    image,
    x1: cx - 128,
    y1: cy + 20,
    x2: cx + 128,
    y2: cy + 20,
    color: img.ColorRgba8(10, 18, 24, 100),
    thickness: 6,
    antialias: true,
  );
  img.fillRect(
    image,
    x1: cx - 18,
    y1: cy + 4,
    x2: cx + 18,
    y2: cy + 36,
    color: s,
    radius: 8,
  );
}

void _drawLotus(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  for (var i = -3; i <= 3; i++) {
    final x = cx + i * 28;
    final y = cy + 52 - (3 - i.abs()) * 26;
    img.drawLine(
      image,
      x1: cx,
      y1: cy + 92,
      x2: x,
      y2: y - 54,
      color: i.isEven ? c : s,
      thickness: 18,
      antialias: true,
    );
    img.fillCircle(
      image,
      x: x,
      y: y - 58,
      radius: 20,
      color: i.isEven ? s : c,
      antialias: true,
    );
  }
  img.drawLine(
    image,
    x1: cx - 122,
    y1: cy + 100,
    x2: cx + 122,
    y2: cy + 100,
    color: c,
    thickness: 8,
    antialias: true,
  );
}

void _drawSeedling(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  img.drawLine(
    image,
    x1: cx,
    y1: cy + 108,
    x2: cx,
    y2: cy - 50,
    color: c,
    thickness: 12,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx,
    y1: cy + 8,
    x2: cx - 82,
    y2: cy - 42,
    color: s,
    thickness: 18,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx,
    y1: cy - 12,
    x2: cx + 88,
    y2: cy - 68,
    color: s,
    thickness: 18,
    antialias: true,
  );
  img.fillCircle(
    image,
    x: cx - 88,
    y: cy - 46,
    radius: 26,
    color: s,
    antialias: true,
  );
  img.fillCircle(
    image,
    x: cx + 94,
    y: cy - 72,
    radius: 30,
    color: c,
    antialias: true,
  );
  img.fillRect(
    image,
    x1: cx - 100,
    y1: cy + 106,
    x2: cx + 100,
    y2: cy + 124,
    color: c,
    radius: 12,
  );
}

void _drawCalendar(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  img.fillRect(
    image,
    x1: cx - 108,
    y1: cy - 86,
    x2: cx + 108,
    y2: cy + 108,
    color: c,
    radius: 20,
  );
  img.fillRect(
    image,
    x1: cx - 108,
    y1: cy - 86,
    x2: cx + 108,
    y2: cy - 42,
    color: s,
    radius: 20,
  );
  for (var row = 0; row < 3; row++) {
    for (var col = 0; col < 4; col++) {
      img.fillRect(
        image,
        x1: cx - 72 + col * 44,
        y1: cy - 12 + row * 34,
        x2: cx - 48 + col * 44,
        y2: cy + 12 + row * 34,
        color: img.ColorRgba8(14, 23, 31, 110),
        radius: 5,
      );
    }
  }
}

void _drawMirrorFigure(
  img.Image image,
  int cx,
  int cy,
  img.Color c,
  img.Color s,
) {
  img.drawCircle(image, x: cx, y: cy, radius: 110, color: c, antialias: true);
  img.drawCircle(image, x: cx, y: cy, radius: 78, color: s, antialias: true);
  img.fillCircle(
    image,
    x: cx,
    y: cy - 34,
    radius: 28,
    color: s,
    antialias: true,
  );
  img.fillRect(
    image,
    x1: cx - 46,
    y1: cy + 6,
    x2: cx + 46,
    y2: cy + 86,
    color: c,
    radius: 36,
  );
}

void _drawBrain(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  for (final p in [
    (x: -72, y: -34, r: 36),
    (x: -34, y: -72, r: 38),
    (x: 22, y: -72, r: 40),
    (x: 70, y: -32, r: 38),
    (x: -48, y: 16, r: 42),
    (x: 42, y: 16, r: 46),
  ]) {
    img.fillCircle(
      image,
      x: cx + p.x,
      y: cy + p.y,
      radius: p.r,
      color: p.x.isEven ? c : s,
      antialias: true,
    );
  }
  img.drawLine(
    image,
    x1: cx - 98,
    y1: cy + 64,
    x2: cx + 96,
    y2: cy + 64,
    color: s,
    thickness: 10,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx,
    y1: cy - 102,
    x2: cx,
    y2: cy + 78,
    color: img.ColorRgba8(10, 18, 24, 70),
    thickness: 5,
    antialias: true,
  );
}

void _drawCircuitNodes(
  img.Image image,
  int cx,
  int cy,
  img.Color c,
  img.Color s,
  img.Color d,
) {
  final points = [
    img.Point(cx - 116, cy - 62),
    img.Point(cx - 36, cy - 94),
    img.Point(cx + 54, cy - 46),
    img.Point(cx + 120, cy + 28),
    img.Point(cx + 8, cy + 86),
    img.Point(cx - 102, cy + 42),
  ];
  for (var i = 0; i < points.length; i++) {
    final a = points[i];
    final b = points[(i + 1) % points.length];
    img.drawLine(
      image,
      x1: a.x.toInt(),
      y1: a.y.toInt(),
      x2: b.x.toInt(),
      y2: b.y.toInt(),
      color: d,
      thickness: 6,
      antialias: true,
    );
  }
  for (var i = 0; i < points.length; i++) {
    img.fillCircle(
      image,
      x: points[i].x.toInt(),
      y: points[i].y.toInt(),
      radius: i.isEven ? 22 : 16,
      color: i.isEven ? c : s,
      antialias: true,
    );
  }
}

void _drawHourglass(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  img.drawLine(
    image,
    x1: cx - 82,
    y1: cy - 104,
    x2: cx + 82,
    y2: cy - 104,
    color: c,
    thickness: 10,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx - 82,
    y1: cy + 104,
    x2: cx + 82,
    y2: cy + 104,
    color: c,
    thickness: 10,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx - 70,
    y1: cy - 94,
    x2: cx + 56,
    y2: cy + 94,
    color: s,
    thickness: 10,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx + 70,
    y1: cy - 94,
    x2: cx - 56,
    y2: cy + 94,
    color: s,
    thickness: 10,
    antialias: true,
  );
  img.fillCircle(
    image,
    x: cx,
    y: cy + 52,
    radius: 28,
    color: c,
    antialias: true,
  );
}

void _drawMapRoute(
  img.Image image,
  int cx,
  int cy,
  img.Color c,
  img.Color s,
  img.Color d,
) {
  final route = [
    img.Point(cx - 126, cy + 72),
    img.Point(cx - 72, cy - 42),
    img.Point(cx + 8, cy + 20),
    img.Point(cx + 72, cy - 72),
    img.Point(cx + 132, cy + 44),
  ];
  for (var i = 0; i < route.length - 1; i++) {
    img.drawLine(
      image,
      x1: route[i].x.toInt(),
      y1: route[i].y.toInt(),
      x2: route[i + 1].x.toInt(),
      y2: route[i + 1].y.toInt(),
      color: d,
      thickness: 8,
      antialias: true,
    );
    img.fillCircle(
      image,
      x: route[i].x.toInt(),
      y: route[i].y.toInt(),
      radius: 16,
      color: i.isEven ? c : s,
      antialias: true,
    );
  }
  img.fillCircle(
    image,
    x: route.last.x.toInt(),
    y: route.last.y.toInt(),
    radius: 26,
    color: s,
    antialias: true,
  );
}

void _drawOpenHands(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  img.drawLine(
    image,
    x1: cx - 138,
    y1: cy + 48,
    x2: cx - 42,
    y2: cy + 6,
    color: c,
    thickness: 22,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx + 138,
    y1: cy + 48,
    x2: cx + 42,
    y2: cy + 6,
    color: c,
    thickness: 22,
    antialias: true,
  );
  img.fillCircle(
    image,
    x: cx,
    y: cy - 34,
    radius: 42,
    color: s,
    antialias: true,
  );
  img.fillCircle(
    image,
    x: cx,
    y: cy + 36,
    radius: 58,
    color: img.ColorRgba8(10, 18, 24, 75),
    antialias: true,
  );
}

void _drawLedger(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  img.fillRect(
    image,
    x1: cx - 116,
    y1: cy - 96,
    x2: cx + 116,
    y2: cy + 104,
    color: c,
    radius: 18,
  );
  for (var i = 0; i < 5; i++) {
    img.drawLine(
      image,
      x1: cx - 84,
      y1: cy - 54 + i * 34,
      x2: cx + 84,
      y2: cy - 54 + i * 34,
      color: img.ColorRgba8(8, 15, 22, 95),
      thickness: 5,
      antialias: true,
    );
  }
  img.fillCircle(
    image,
    x: cx + 78,
    y: cy + 70,
    radius: 28,
    color: s,
    antialias: true,
  );
}

void _drawAttachmentRings(
  img.Image image,
  int cx,
  int cy,
  img.Color c,
  img.Color s,
  img.Color d,
) {
  img.drawCircle(
    image,
    x: cx - 34,
    y: cy,
    radius: 78,
    color: c,
    antialias: true,
  );
  img.drawCircle(
    image,
    x: cx + 34,
    y: cy,
    radius: 78,
    color: s,
    antialias: true,
  );
  img.fillCircle(image, x: cx, y: cy, radius: 28, color: d, antialias: true);
}

void _drawHandshake(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  img.drawLine(
    image,
    x1: cx - 142,
    y1: cy - 18,
    x2: cx - 24,
    y2: cy + 44,
    color: c,
    thickness: 24,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx + 142,
    y1: cy - 18,
    x2: cx + 24,
    y2: cy + 44,
    color: s,
    thickness: 24,
    antialias: true,
  );
  img.fillRect(
    image,
    x1: cx - 52,
    y1: cy + 16,
    x2: cx + 52,
    y2: cy + 72,
    color: img.ColorRgba8(224, 236, 238, 110),
    radius: 22,
  );
}

void _drawTarget(
  img.Image image,
  int cx,
  int cy,
  img.Color c,
  img.Color s,
  img.Color d,
) {
  for (final r in [110, 78, 46]) {
    img.drawCircle(
      image,
      x: cx,
      y: cy,
      radius: r,
      color: r.isEven ? c : d,
      antialias: true,
    );
  }
  img.fillCircle(image, x: cx, y: cy, radius: 24, color: s, antialias: true);
  img.drawLine(
    image,
    x1: cx - 140,
    y1: cy + 104,
    x2: cx + 102,
    y2: cy - 116,
    color: s,
    thickness: 8,
    antialias: true,
  );
}

void _drawFlag(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  img.drawLine(
    image,
    x1: cx - 68,
    y1: cy + 108,
    x2: cx - 68,
    y2: cy - 112,
    color: c,
    thickness: 10,
    antialias: true,
  );
  img.fillPolygon(
    image,
    vertices: [
      img.Point(cx - 58, cy - 112),
      img.Point(cx + 112, cy - 72),
      img.Point(cx - 58, cy - 22),
    ],
    color: s,
  );
  img.fillRect(
    image,
    x1: cx - 112,
    y1: cy + 104,
    x2: cx + 42,
    y2: cy + 124,
    color: c,
    radius: 10,
  );
}

void _drawMicrophone(
  img.Image image,
  int cx,
  int cy,
  img.Color c,
  img.Color s,
) {
  img.fillRect(
    image,
    x1: cx - 44,
    y1: cy - 112,
    x2: cx + 44,
    y2: cy + 24,
    color: c,
    radius: 42,
  );
  img.drawLine(
    image,
    x1: cx - 86,
    y1: cy - 8,
    x2: cx - 86,
    y2: cy + 26,
    color: s,
    thickness: 8,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx + 86,
    y1: cy - 8,
    x2: cx + 86,
    y2: cy + 26,
    color: s,
    thickness: 8,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx - 86,
    y1: cy + 26,
    x2: cx + 86,
    y2: cy + 26,
    color: s,
    thickness: 8,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx,
    y1: cy + 26,
    x2: cx,
    y2: cy + 112,
    color: c,
    thickness: 10,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx - 54,
    y1: cy + 112,
    x2: cx + 54,
    y2: cy + 112,
    color: c,
    thickness: 10,
    antialias: true,
  );
}

void _drawClock(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  img.fillCircle(image, x: cx, y: cy, radius: 112, color: c, antialias: true);
  img.fillCircle(
    image,
    x: cx,
    y: cy,
    radius: 82,
    color: img.ColorRgba8(12, 20, 28, 120),
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx,
    y1: cy,
    x2: cx,
    y2: cy - 58,
    color: s,
    thickness: 10,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: cx,
    y1: cy,
    x2: cx + 58,
    y2: cy + 34,
    color: s,
    thickness: 10,
    antialias: true,
  );
}

void _drawScroll(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  img.fillRect(
    image,
    x1: cx - 110,
    y1: cy - 92,
    x2: cx + 110,
    y2: cy + 92,
    color: c,
    radius: 24,
  );
  img.fillCircle(
    image,
    x: cx - 110,
    y: cy - 62,
    radius: 28,
    color: s,
    antialias: true,
  );
  img.fillCircle(
    image,
    x: cx + 110,
    y: cy + 62,
    radius: 28,
    color: s,
    antialias: true,
  );
  for (var i = 0; i < 4; i++) {
    img.drawLine(
      image,
      x1: cx - 58,
      y1: cy - 42 + i * 28,
      x2: cx + 58,
      y2: cy - 42 + i * 28,
      color: img.ColorRgba8(8, 15, 22, 80),
      thickness: 5,
      antialias: true,
    );
  }
}

void _drawColumn(img.Image image, int cx, int cy, img.Color c, img.Color s) {
  img.fillRect(
    image,
    x1: cx - 92,
    y1: cy - 104,
    x2: cx + 92,
    y2: cy - 74,
    color: s,
    radius: 10,
  );
  img.fillRect(
    image,
    x1: cx - 72,
    y1: cy + 86,
    x2: cx + 72,
    y2: cy + 116,
    color: s,
    radius: 10,
  );
  for (var i = -1; i <= 1; i++) {
    img.fillRect(
      image,
      x1: cx + i * 48 - 14,
      y1: cy - 72,
      x2: cx + i * 48 + 14,
      y2: cy + 86,
      color: c,
      radius: 8,
    );
  }
}

void _drawFrame(img.Image image, _Rgb accent) {
  final frame = img.ColorRgba8(accent.r, accent.g, accent.b, 42);
  img.drawLine(
    image,
    x1: 0,
    y1: 0,
    x2: _width - 1,
    y2: 0,
    color: frame,
    thickness: 4,
  );
  img.drawLine(
    image,
    x1: 0,
    y1: _height - 1,
    x2: _width - 1,
    y2: _height - 1,
    color: frame,
    thickness: 4,
  );
  img.drawLine(
    image,
    x1: 0,
    y1: 0,
    x2: 0,
    y2: _height - 1,
    color: frame,
    thickness: 4,
  );
  img.drawLine(
    image,
    x1: _width - 1,
    y1: 0,
    x2: _width - 1,
    y2: _height - 1,
    color: frame,
    thickness: 4,
  );
}

_Rgb _rgb(int value) =>
    _Rgb((value >> 16) & 0xff, (value >> 8) & 0xff, value & 0xff);

class _CoverSpec {
  final String slug;
  final String category;
  final String title;
  final int accent;
  final int seed;

  const _CoverSpec(
    this.slug,
    this.category,
    this.title,
    this.accent,
    this.seed,
  );
}

class _Rgb {
  final int r;
  final int g;
  final int b;

  const _Rgb(this.r, this.g, this.b);
}
