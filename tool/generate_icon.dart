// Генератор исходной иконки приложения (1024x1024 PNG).
// Рисует якорь в стиле splash-экрана: тёмный фон + бирюзовый якорь со свечением.
//
// Запуск: dart run tool/generate_icon.dart
// Результат: assets/icon/app_icon.png

import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  const int size = 1024;
  final image = img.Image(width: size, height: size);

  // Цвета из темы приложения
  final bg = _rgb(0x05, 0x0B, 0x14); // #050B14
  final bgTop = _rgb(0x0D, 0x1B, 0x2A); // #0D1B2A
  final accent = _rgb(0x38, 0xBD, 0xF8); // #38BDF8
  final accentDark = _rgb(0x02, 0x84, 0xC7); // #0284C7

  // 1. Радиальный градиент фона (как NauticalBackground)
  final cx = size / 2;
  final cy = size * 0.42;
  final maxR = size * 0.75;
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final dist = sqrt(dx * dx + dy * dy);
      final t = (dist / maxR).clamp(0.0, 1.0);
      final r = _lerp(bgTop[0], bg[0], t);
      final g = _lerp(bgTop[1], bg[1], t);
      final b = _lerp(bgTop[2], bg[2], t);
      image.setPixelRgb(x, y, r, g, b);
    }
  }

  // 2. Мягкое свечение за якорем (glow)
  final glowR = size * 0.34;
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist < glowR) {
        final t = 1.0 - (dist / glowR);
        final strength = pow(t, 2.2).toDouble() * 0.55;
        _blend(image, x, y, accent, strength);
      }
    }
  }

  // 3. Рисуем якорь (векторно, через линии/круги)
  final anchorColor = accent;
  final strokeW = size * 0.045;
  final ax = cx;
  final ay = cy;

  // Кольцо сверху
  final ringR = size * 0.075;
  final ringCy = ay - size * 0.24;
  _drawRing(image, ax, ringCy, ringR, strokeW, anchorColor);

  // Вертикальный шток
  _drawLine(image, ax, ringCy + ringR, ax, ay + size * 0.20, strokeW, anchorColor);

  // Горизонтальная перекладина (шток)
  final stockY = ay - size * 0.10;
  final stockHalf = size * 0.13;
  _drawLine(image, ax - stockHalf, stockY, ax + stockHalf, stockY, strokeW * 0.85, anchorColor);

  // Дуга снизу (лапы якоря)
  final arcR = size * 0.20;
  final arcCy = ay + size * 0.02;
  _drawArc(image, ax, arcCy, arcR, strokeW, anchorColor, pi * 0.15, pi * 0.85);

  // Лапы (наконечники) на концах дуги
  final leftAngle = pi * 0.15;
  final rightAngle = pi * 0.85;
  final lx = ax + arcR * cos(leftAngle);
  final ly = arcCy + arcR * sin(leftAngle);
  final rx = ax + arcR * cos(rightAngle);
  final ry = arcCy + arcR * sin(rightAngle);
  _drawTriangleTip(image, lx, ly, -1, strokeW, anchorColor);
  _drawTriangleTip(image, rx, ry, 1, strokeW, anchorColor);

  // 4. Лёгкая виньетка по краям
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = (x - cx) / (size / 2);
      final dy = (y - size / 2) / (size / 2);
      final d = sqrt(dx * dx + dy * dy);
      if (d > 0.75) {
        final t = ((d - 0.75) / 0.35).clamp(0.0, 1.0);
        _blend(image, x, y, accentDark, t * 0.15);
      }
    }
  }

  // Сохраняем
  final dir = Directory('assets/icon');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final file = File('assets/icon/app_icon.png');
  file.writeAsBytesSync(img.encodePng(image));
  stdout.writeln('Icon written to ${file.path}');
}

List<int> _rgb(int r, int g, int b) => [r, g, b];

double _lerp(num a, num b, double t) => a + (b - a) * t;

void _blend(img.Image image, int x, int y, List<int> color, double alpha) {
  if (x < 0 || y < 0 || x >= image.width || y >= image.height) return;
  final p = image.getPixel(x, y);
  final r = (p.r * (1 - alpha) + color[0] * alpha).round().clamp(0, 255);
  final g = (p.g * (1 - alpha) + color[1] * alpha).round().clamp(0, 255);
  final b = (p.b * (1 - alpha) + color[2] * alpha).round().clamp(0, 255);
  image.setPixelRgb(x, y, r, g, b);
}

void _drawLine(img.Image image, double x1, double y1, double x2, double y2, double w, List<int> color) {
  final steps = (sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2)) * 2).toInt() + 1;
  for (int i = 0; i <= steps; i++) {
    final t = i / steps;
    final x = x1 + (x2 - x1) * t;
    final y = y1 + (y2 - y1) * t;
    _drawDisc(image, x, y, w / 2, color);
  }
}

void _drawDisc(img.Image image, double cx, double cy, double r, List<int> color) {
  final r2 = r * r;
  for (int y = (cy - r).toInt(); y <= (cy + r).toInt(); y++) {
    for (int x = (cx - r).toInt(); x <= (cx + r).toInt(); x++) {
      final dx = x - cx;
      final dy = y - cy;
      final d2 = dx * dx + dy * dy;
      if (d2 <= r2) {
        final edge = sqrt(d2) / r;
        final alpha = edge > 0.85 ? (1.0 - (edge - 0.85) / 0.15) : 1.0;
        _blend(image, x, y, color, alpha.clamp(0.0, 1.0));
      }
    }
  }
}

void _drawRing(img.Image image, double cx, double cy, double r, double w, List<int> color) {
  final outer = r + w / 2;
  final inner = r - w / 2;
  for (int y = (cy - outer).toInt(); y <= (cy + outer).toInt(); y++) {
    for (int x = (cx - outer).toInt(); x <= (cx + outer).toInt(); x++) {
      final dx = x - cx;
      final dy = y - cy;
      final d = sqrt(dx * dx + dy * dy);
      if (d >= inner && d <= outer) {
        final edge = min((d - inner) / (w * 0.3), (outer - d) / (w * 0.3)).clamp(0.0, 1.0);
        _blend(image, x, y, color, edge);
      }
    }
  }
}

void _drawArc(img.Image image, double cx, double cy, double r, double w, List<int> color, double start, double end) {
  final steps = 400;
  for (int i = 0; i <= steps; i++) {
    final a = start + (end - start) * (i / steps);
    final x = cx + r * cos(a);
    final y = cy + r * sin(a);
    _drawDisc(image, x, y, w / 2, color);
  }
}

void _drawTriangleTip(img.Image image, double x, double y, int dir, double w, List<int> color) {
  // Небольшой наконечник-«лапа» на конце дуги
  final s = w * 1.1;
  for (int yy = (y - s).toInt(); yy <= (y + s).toInt(); yy++) {
    for (int xx = (x - s).toInt(); xx <= (x + s).toInt(); xx++) {
      final dx = (xx - x) * dir;
      final dy = yy - y;
      if (dx >= -s * 0.2 && dx <= s && dy.abs() <= (s - dx) * 0.9) {
        _blend(image, xx, yy, color, 1.0);
      }
    }
  }
}
