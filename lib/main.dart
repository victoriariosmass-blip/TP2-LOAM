import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flame/game.dart' hide Matrix4;

void main() {
  runApp(const Dino2048App());
}

class AppColors {
  final bool isDark;

  const AppColors(this.isDark);

  Color get background =>
      isDark ? const Color(0xFF17172E) : const Color(0xFFCBF3F0);
  Color get header =>
      isDark ? const Color(0xFF34345B) : const Color(0xFFFFBF69);
  Color get panel => isDark ? const Color(0xFF292943) : const Color(0xFFFFF3B0);
  Color get foreground => isDark ? Colors.white : Colors.black;
  Color get outline => isDark ? const Color(0xFF090912) : Colors.black;
  Color get shadow => isDark ? const Color(0xFF080811) : Colors.black;
  Color get startButton =>
      isDark ? const Color(0xFF45E0C0) : const Color(0xFF2EC4B6);
  Color get pauseButton =>
      isDark ? const Color(0xFFFFD27A) : const Color(0xFFFFBF69);
  Color get restartButton =>
      isDark ? const Color(0xFFFF8994) : const Color(0xFFFF6B6B);
  Color get newButton =>
      isDark ? const Color(0xFFC29AFF) : const Color(0xFF9B5DE5);
}

class DinoGame extends FlameGame {}

class Dino2048App extends StatelessWidget {
  const Dino2048App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dino 2048',
      theme: ThemeData(
        // Fondo general: Celeste claro/Hielo[cite: 18]
        scaffoldBackgroundColor: const Color(0xFFCBF3F0),
        fontFamily: 'sans-serif-rounded',
        brightness: Brightness.light,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _diamonds = 50;
  bool _isDarkMode = false;

  void _setDarkMode(bool isDarkMode) {
    setState(() => _isDarkMode = isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(_isDarkMode);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildHeader(colors),
              const SizedBox(height: 24),
              _buildBoardPlaceholder(),
              const SizedBox(height: 24),
              _buildControls(colors),
            ],
          ),
        ),
      ),
    );
  }

  // 1. HEADER
  Widget _buildHeader(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.header,
        border: Border.all(color: colors.outline, width: 4),
        boxShadow: [
          BoxShadow(color: colors.shadow, offset: const Offset(6, 6)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'USUARIO: JUGADOR1',
                style: TextStyle(
                  color: colors.foreground,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      border: Border.all(color: colors.outline, width: 3),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SCORE: 0',
                style: TextStyle(
                  color: colors.foreground,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ThemeToggleButton(
                    isDarkMode: _isDarkMode,
                    onPressed: () => _setDarkMode(!_isDarkMode),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: const Color(0xFF2EC4B6),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _openDiamondShop,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 3),
                        ),
                        child: const Icon(Icons.add, size: 28, weight: 900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      const SizedBox(
                        width: 27,
                        height: 27,
                        child: CustomPaint(painter: DiamondIconPainter()),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$_diamonds',
                        style: TextStyle(
                          color: colors.foreground,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openDiamondShop() async {
    final purchasedDiamonds = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => DiamondShopScreen(
          isDarkMode: _isDarkMode,
          onThemeChanged: _setDarkMode,
        ),
      ),
    );

    if (!mounted || purchasedDiamonds == null) return;

    setState(() => _diamonds += purchasedDiamonds);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Genial! Sumaste $purchasedDiamonds diamantes.'),
        backgroundColor: _isDarkMode
            ? const Color(0xFF34345B)
            : const Color(0xFF1A535C),
      ),
    );
  }

  Future<void> _showAdvertisement() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DinoBitesAdvertisement(),
    );
  }

  // 2. EL TABLERO (Conecta con Flame)
  Widget _buildBoardPlaceholder() {
    return Expanded(
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: const Color(
            0xFF1A535C,
          ), // Fondo del tablero: Azul petróleo oscuro[cite: 18]
          border: Border.all(color: Colors.black, width: 6),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(8, 8)),
          ],
        ),
        child: GameWidget(game: DinoGame()),
      ),
    );
  }

  // 3. CONTROLES EXTERNOS
  Widget _buildControls(AppColors colors) {
    return Column(
      children: [
        Row(
          children: [
            // Botón Inicio: Verde turquesa[cite: 18]
            Expanded(
              child: BrutalistButton(text: 'INICIO', color: colors.startButton),
            ),
            const SizedBox(width: 16),
            // Botón Pausa: Naranja arena[cite: 18]
            Expanded(
              child: BrutalistButton(text: 'PAUSA', color: colors.pauseButton),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Botón Reiniciar: Rojo coral[cite: 18]
            Expanded(
              child: BrutalistButton(
                text: 'REINICIAR',
                color: colors.restartButton,
                onPressed: _showAdvertisement,
              ),
            ),
            const SizedBox(width: 16),
            // Botón Nueva: Azul petróleo oscuro[cite: 18]
            Expanded(
              child: BrutalistButton(
                text: 'NUEVA',
                color: colors.newButton,
                textColor: _isDarkMode ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DinoBitesAdvertisement extends StatefulWidget {
  const _DinoBitesAdvertisement();

  @override
  State<_DinoBitesAdvertisement> createState() =>
      _DinoBitesAdvertisementState();
}

class _DinoBitesAdvertisementState extends State<_DinoBitesAdvertisement> {
  static const _adDuration = 8;
  late final Timer _countdownTimer;
  int _secondsRemaining = _adDuration;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  void _close() {
    if (_secondsRemaining != 0) return;

    final route = ModalRoute.of(context);
    if (route != null) {
      Navigator.of(context, rootNavigator: true).removeRoute(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _secondsRemaining == 0;

    return PopScope(
      canPop: canContinue,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE45E),
            border: Border.all(color: Colors.black, width: 4),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(7, 7)),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: canContinue ? 'Cerrar anuncio' : null,
                    onPressed: canContinue ? _close : null,
                    icon: const Icon(Icons.close, size: 30),
                  ),
                ),
                Container(
                  width: 112,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 4),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: CustomPaint(painter: _DinosaurCookiePainter()),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'DINO BITES',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '¡DINO BITES A TAN SOLO \$1200 ARS!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Conseguí tus galletitas de dinosaurios favoritas en la tienda más cercana',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canContinue ? _close : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2EC4B6),
                      disabledBackgroundColor: const Color(0xFF9DDDD7),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(0, 54),
                      side: const BorderSide(color: Colors.black, width: 3),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text(
                      canContinue
                          ? '¡A JUGAR!'
                          : 'ESPERÁ $_secondsRemaining SEG.',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DinosaurCookiePainter extends CustomPainter {
  const _DinosaurCookiePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 100);

    final cookie = Paint()..color = const Color(0xFFC87935);
    final outline = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round;

    final silhouette = Path()
      ..moveTo(8, 59)
      ..lineTo(27, 52)
      ..cubicTo(31, 39, 46, 36, 58, 42)
      ..lineTo(62, 25)
      ..cubicTo(63, 17, 72, 14, 78, 20)
      ..lineTo(83, 27)
      ..lineTo(96, 28)
      ..cubicTo(103, 29, 104, 37, 96, 39)
      ..lineTo(83, 39)
      ..lineTo(79, 51)
      ..cubicTo(95, 56, 97, 68, 86, 73)
      ..lineTo(82, 84)
      ..lineTo(68, 84)
      ..lineTo(65, 72)
      ..lineTo(48, 70)
      ..lineTo(45, 84)
      ..lineTo(31, 84)
      ..lineTo(30, 72)
      ..lineTo(20, 72)
      ..close();
    canvas.drawPath(silhouette, cookie);
    canvas.drawPath(silhouette, outline);

    final spikes = Path()
      ..moveTo(43, 40)
      ..lineTo(47, 29)
      ..lineTo(54, 41)
      ..lineTo(59, 30)
      ..lineTo(64, 43)
      ..close();
    canvas.drawPath(spikes, Paint()..color = const Color(0xFFE8A34A));
    canvas.drawPath(spikes, outline);

    final chips = Paint()..color = const Color(0xFF75421F);
    for (final chip in [
      const Offset(33, 58),
      const Offset(48, 52),
      const Offset(73, 47),
      const Offset(59, 62),
      const Offset(77, 64),
      const Offset(40, 67),
    ]) {
      canvas.drawCircle(chip, 2.4, chips);
    }
    canvas.drawCircle(const Offset(88, 32), 2, Paint()..color = Colors.black);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ThemeToggleButton extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onPressed;

  const _ThemeToggleButton({required this.isDarkMode, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final label = isDarkMode ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro';

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: const Color(0xFFFFE45E),
          shape: const CircleBorder(
            side: BorderSide(color: Colors.black, width: 3),
          ),
          elevation: 3,
          shadowColor: Colors.black,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Colors.black,
                size: 23,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DiamondPack {
  final String name;
  final int amount;
  final String price;
  final PackIllustrationType illustration;
  final Color color;

  const DiamondPack({
    required this.name,
    required this.amount,
    required this.price,
    required this.illustration,
    required this.color,
  });
}

const _diamondPacks = [
  DiamondPack(
    name: 'PUÑADO',
    amount: 10,
    price: r'$500',
    illustration: PackIllustrationType.handful,
    color: Color(0xFFFF6B6B),
  ),
  DiamondPack(
    name: 'BOLSA',
    amount: 25,
    price: r'$1.200',
    illustration: PackIllustrationType.backpack,
    color: Color(0xFFFFBF69),
  ),
  DiamondPack(
    name: 'CAJA',
    amount: 50,
    price: r'$2.500',
    illustration: PackIllustrationType.box,
    color: Color(0xFF2EC4B6),
  ),
  DiamondPack(
    name: 'CAJÓN',
    amount: 100,
    price: r'$5.200',
    illustration: PackIllustrationType.crate,
    color: Color(0xFF9B5DE5),
  ),
  DiamondPack(
    name: 'CARRETILLA',
    amount: 200,
    price: r'$10.500',
    illustration: PackIllustrationType.wheelbarrow,
    color: Color(0xFF00BBF9),
  ),
  DiamondPack(
    name: 'LLUVIA',
    amount: 500,
    price: r'$25.000',
    illustration: PackIllustrationType.diamondRain,
    color: Color(0xFFF15BB5),
  ),
];

enum PackIllustrationType {
  handful,
  backpack,
  box,
  crate,
  wheelbarrow,
  diamondRain,
}

class DiamondIconPainter extends CustomPainter {
  const DiamondIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final outline = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeJoin = StrokeJoin.round;
    final gem = Path()
      ..moveTo(17, 34)
      ..lineTo(34, 13)
      ..lineTo(68, 13)
      ..lineTo(85, 34)
      ..lineTo(51, 88)
      ..close();
    canvas.drawPath(gem, Paint()..color = const Color(0xFF52D7F2));
    canvas.drawPath(gem, outline);
    final facets = Paint()
      ..color = const Color(0xFF1A535C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawLine(const Offset(17, 34), const Offset(85, 34), facets);
    canvas.drawLine(const Offset(34, 13), const Offset(42, 34), facets);
    canvas.drawLine(const Offset(68, 13), const Offset(60, 34), facets);
    canvas.drawLine(const Offset(42, 34), const Offset(51, 88), facets);
    canvas.drawLine(const Offset(60, 34), const Offset(51, 88), facets);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PackIllustration extends StatelessWidget {
  final PackIllustrationType type;

  const PackIllustration({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PackIllustrationPainter(type),
      child: const SizedBox.expand(),
    );
  }
}

class _PackIllustrationPainter extends CustomPainter {
  final PackIllustrationType type;

  const _PackIllustrationPainter(this.type);

  final Color _ink = Colors.black;
  final Color _gemBlue = const Color(0xFF52D7F2);
  final Color _gemPink = const Color(0xFFF15BB5);
  final Color _gemYellow = const Color(0xFFFFE45E);

  Paint _paint(Color color, {bool stroke = false, double width = 3}) => Paint()
    ..color = color
    ..style = stroke ? PaintingStyle.stroke : PaintingStyle.fill
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _line(Canvas canvas, Offset a, Offset b, {double width = 4}) {
    canvas.drawLine(a, b, _paint(_ink, stroke: true, width: width));
  }

  void _gem(Canvas canvas, double x, double y, double scale, Color color) {
    final gem = Path()
      ..moveTo(x - 12 * scale, y - 5 * scale)
      ..lineTo(x - 6 * scale, y - 13 * scale)
      ..lineTo(x + 6 * scale, y - 13 * scale)
      ..lineTo(x + 12 * scale, y - 5 * scale)
      ..lineTo(x, y + 13 * scale)
      ..close();
    canvas.drawPath(gem, _paint(color));
    canvas.drawPath(gem, _paint(_ink, stroke: true, width: 2.5 * scale));
    _line(
      canvas,
      Offset(x - 12 * scale, y - 5 * scale),
      Offset(x + 12 * scale, y - 5 * scale),
      width: 1.8 * scale,
    );
    _line(
      canvas,
      Offset(x - 6 * scale, y - 13 * scale),
      Offset(x - 3 * scale, y - 5 * scale),
      width: 1.5 * scale,
    );
    _line(
      canvas,
      Offset(x + 6 * scale, y - 13 * scale),
      Offset(x + 3 * scale, y - 5 * scale),
      width: 1.5 * scale,
    );
  }

  void _drawHandful(Canvas canvas) {
    final skinColor = const Color(0xFFFFC18C);
    final skin = _paint(skinColor);
    final outline = _paint(_ink, stroke: true, width: 4);

    // Rounded fingers and palm form an open hand presented upward.
    for (final finger in [
      const Rect.fromLTWH(37, 31, 14, 37),
      const Rect.fromLTWH(51, 22, 14, 42),
      const Rect.fromLTWH(65, 24, 14, 40),
      const Rect.fromLTWH(79, 32, 14, 34),
    ]) {
      final shape = RRect.fromRectAndRadius(finger, const Radius.circular(8));
      canvas.drawRRect(shape, skin);
      canvas.drawRRect(shape, outline);
    }

    final palm = Path()
      ..moveTo(34, 55)
      ..quadraticBezierTo(35, 43, 46, 43)
      ..lineTo(84, 43)
      ..quadraticBezierTo(94, 44, 95, 54)
      ..lineTo(89, 72)
      ..quadraticBezierTo(85, 83, 72, 84)
      ..lineTo(48, 80)
      ..quadraticBezierTo(35, 77, 34, 66)
      ..close();
    canvas.drawPath(palm, skin);
    canvas.drawPath(palm, outline);

    final thumb = Path()
      ..moveTo(38, 58)
      ..quadraticBezierTo(29, 53, 23, 61)
      ..quadraticBezierTo(20, 67, 28, 72)
      ..lineTo(43, 78)
      ..lineTo(50, 67)
      ..close();
    canvas.drawPath(thumb, skin);
    canvas.drawPath(thumb, outline);

    _gem(canvas, 63, 50, 1.22, _gemBlue);
    _line(canvas, const Offset(43, 72), const Offset(53, 74), width: 2.5);
    _line(canvas, const Offset(73, 75), const Offset(83, 72), width: 2.5);
  }

  void _drawBackpack(Canvas canvas) {
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(27, 29, 66, 64),
      const Radius.circular(17),
    );
    canvas.drawRRect(body, _paint(const Color(0xFFEF476F)));
    canvas.drawRRect(body, _paint(_ink, stroke: true, width: 4));
    final straps = _paint(const Color(0xFFFFBF69), stroke: true, width: 7);
    canvas.drawArc(
      const Rect.fromLTWH(20, 38, 22, 48),
      1.2,
      3.9,
      false,
      straps,
    );
    canvas.drawArc(
      const Rect.fromLTWH(78, 38, 22, 48),
      4.3,
      3.9,
      false,
      straps,
    );
    canvas.drawArc(
      const Rect.fromLTWH(43, 12, 34, 31),
      3.15,
      3.0,
      false,
      _paint(_ink, stroke: true, width: 5),
    );
    final pocket = RRect.fromRectAndRadius(
      const Rect.fromLTWH(37, 58, 46, 27),
      const Radius.circular(9),
    );
    canvas.drawRRect(pocket, _paint(const Color(0xFFFFBF69)));
    canvas.drawRRect(pocket, _paint(_ink, stroke: true, width: 3));
    _gem(canvas, 49, 70, 0.65, _gemBlue);
    _gem(canvas, 68, 70, 0.65, _gemYellow);
    _gem(canvas, 53, 43, 0.7, _gemPink);
    _gem(canvas, 70, 43, 0.7, _gemBlue);
  }

  void _drawBox(Canvas canvas) {
    final left = 28.0;
    final right = 92.0;
    final top = 45.0;
    final bottom = 91.0;
    final box = Path()
      ..moveTo(left, top)
      ..lineTo(right, top)
      ..lineTo(right - 5, bottom)
      ..lineTo(left + 5, bottom)
      ..close();
    final lid = Path()
      ..moveTo(left - 4, top)
      ..lineTo(left + 9, top - 18)
      ..lineTo(right - 9, top - 18)
      ..lineTo(right + 4, top)
      ..close();
    canvas.drawPath(box, _paint(const Color(0xFFFFBF69)));
    canvas.drawPath(box, _paint(_ink, stroke: true, width: 4));
    canvas.drawPath(lid, _paint(const Color(0xFFFFD166)));
    canvas.drawPath(lid, _paint(_ink, stroke: true, width: 4));
    _line(
      canvas,
      Offset(left + 11, top + 4),
      Offset(left + 15, bottom - 2),
      width: 3,
    );
    _line(
      canvas,
      Offset(right - 11, top + 4),
      Offset(right - 15, bottom - 2),
      width: 3,
    );
    const scale = 0.62;
    _gem(canvas, 44, top + 12, scale, _gemBlue);
    _gem(canvas, 62, top + 10, scale, _gemPink);
    _gem(canvas, 79, top + 12, scale, _gemYellow);
    _gem(canvas, 50, top - 10, scale * 0.75, _gemYellow);
    _gem(canvas, 71, top - 10, scale * 0.75, _gemBlue);
  }

  void _drawCrate(Canvas canvas) {
    final wood = const Color(0xFFB56536);
    final lightWood = const Color(0xFFFFBF69);
    final top = Path()
      ..moveTo(23, 35)
      ..lineTo(43, 22)
      ..lineTo(101, 31)
      ..lineTo(82, 44)
      ..close();
    final front = Path()
      ..moveTo(23, 35)
      ..lineTo(82, 44)
      ..lineTo(82, 88)
      ..lineTo(23, 77)
      ..close();
    final side = Path()
      ..moveTo(82, 44)
      ..lineTo(101, 31)
      ..lineTo(101, 75)
      ..lineTo(82, 88)
      ..close();

    canvas.drawPath(top, _paint(const Color(0xFFFFD166)));
    canvas.drawPath(top, _paint(_ink, stroke: true, width: 4));
    canvas.drawPath(front, _paint(wood));
    canvas.drawPath(front, _paint(_ink, stroke: true, width: 4));
    canvas.drawPath(side, _paint(const Color(0xFF8D4E2F)));
    canvas.drawPath(side, _paint(_ink, stroke: true, width: 4));

    for (var x = 39.0; x <= 67; x += 14) {
      _line(
        canvas,
        Offset(x, 39 + (x - 23) * 0.15),
        Offset(x, 80 + (x - 23) * 0.15),
        width: 3,
      );
    }
    _line(canvas, const Offset(86, 43), const Offset(86, 85), width: 3);
    _line(canvas, const Offset(97, 35), const Offset(97, 78), width: 3);

    final rim = Path()
      ..moveTo(20, 34)
      ..lineTo(43, 19)
      ..lineTo(104, 29)
      ..lineTo(82, 46)
      ..close();
    canvas.drawPath(rim, _paint(lightWood, stroke: true, width: 4));
    _gem(canvas, 52, 31, 0.7, _gemBlue);
    _gem(canvas, 69, 34, 0.7, _gemPink);
    _gem(canvas, 85, 33, 0.7, _gemYellow);
  }

  void _drawWheelbarrow(Canvas canvas) {
    final tray = Path()
      ..moveTo(30, 36)
      ..lineTo(102, 43)
      ..lineTo(87, 68)
      ..lineTo(45, 63)
      ..close();
    canvas.drawPath(tray, _paint(const Color(0xFFFF6B6B)));
    canvas.drawPath(tray, _paint(_ink, stroke: true, width: 4));
    _line(canvas, const Offset(40, 42), const Offset(91, 47), width: 2.5);

    _line(canvas, const Offset(49, 63), const Offset(39, 80), width: 5);
    _line(canvas, const Offset(72, 66), const Offset(64, 83), width: 5);
    _line(canvas, const Offset(71, 65), const Offset(107, 83), width: 5);
    _line(canvas, const Offset(78, 59), const Offset(114, 76), width: 5);

    canvas.drawCircle(
      const Offset(34, 78),
      12,
      _paint(const Color(0xFF455A64)),
    );
    canvas.drawCircle(
      const Offset(34, 78),
      12,
      _paint(_ink, stroke: true, width: 3.5),
    );
    canvas.drawCircle(const Offset(34, 78), 5, _paint(const Color(0xFFFFE45E)));
    canvas.drawCircle(const Offset(34, 78), 2, _paint(const Color(0xFF455A64)));

    _gem(canvas, 49, 42, 0.68, _gemBlue);
    _gem(canvas, 67, 44, 0.68, _gemYellow);
    _gem(canvas, 85, 46, 0.68, _gemPink);
    _gem(canvas, 100, 41, 0.58, _gemBlue);
  }

  void _drawDiamondRain(Canvas canvas) {
    final cloud = _paint(Colors.white);
    final cloudStroke = _paint(_ink, stroke: true, width: 4);
    final cloudPath = Path()
      ..moveTo(28, 43)
      ..cubicTo(13, 43, 12, 25, 26, 21)
      ..cubicTo(31, 7, 51, 8, 58, 21)
      ..cubicTo(73, 11, 91, 20, 89, 35)
      ..cubicTo(105, 35, 105, 52, 90, 53)
      ..lineTo(29, 53)
      ..close();
    canvas.drawPath(cloudPath, cloud);
    canvas.drawPath(cloudPath, cloudStroke);
    final colors = [
      _gemBlue,
      _gemPink,
      _gemYellow,
      _gemBlue,
      _gemPink,
      _gemYellow,
    ];
    final drops = [
      const Offset(25, 70),
      const Offset(43, 83),
      const Offset(59, 68),
      const Offset(76, 86),
      const Offset(94, 69),
      const Offset(38, 56),
    ];
    for (var i = 0; i < drops.length; i++) {
      _gem(canvas, drops[i].dx, drops[i].dy, 0.7, colors[i]);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 100);
    switch (type) {
      case PackIllustrationType.handful:
        _drawHandful(canvas);
      case PackIllustrationType.backpack:
        _drawBackpack(canvas);
      case PackIllustrationType.box:
        _drawBox(canvas);
      case PackIllustrationType.crate:
        _drawCrate(canvas);
      case PackIllustrationType.wheelbarrow:
        _drawWheelbarrow(canvas);
      case PackIllustrationType.diamondRain:
        _drawDiamondRain(canvas);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PackIllustrationPainter oldDelegate) =>
      oldDelegate.type != type;
}

class DiamondShopScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const DiamondShopScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<DiamondShopScreen> createState() => _DiamondShopScreenState();
}

class _DiamondShopScreenState extends State<DiamondShopScreen> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  void _toggleTheme() {
    setState(() => _isDarkMode = !_isDarkMode);
    widget.onThemeChanged(_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(_isDarkMode);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.header,
        foregroundColor: colors.foreground,
        elevation: 0,
        title: const Text(
          'TIENDA DE DIAMANTES',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        leading: IconButton(
          tooltip: 'Volver al juego',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _ThemeToggleButton(
              isDarkMode: _isDarkMode,
              onPressed: _toggleTheme,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 10.0 : 16.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                24,
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.panel,
                      border: Border.all(color: colors.outline, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow,
                          offset: const Offset(4, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      '¡ELEGÍ TU TESORO!\n¡Consigue más diamantes y diviértete!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.foreground,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _diamondPacks.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 26,
                          mainAxisExtent: 250,
                        ),
                    itemBuilder: (context, index) => _DiamondPackCard(
                      pack: _diamondPacks[index],
                      colors: colors,
                      onTap: () =>
                          Navigator.of(context)
                              .pop(_diamondPacks[index].amount),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DiamondPackCard extends StatelessWidget {
  final DiamondPack pack;
  final AppColors colors;
  final VoidCallback onTap;

  const _DiamondPackCard({
    required this.pack,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: pack.color,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: PackIllustration(type: pack.illustration),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                pack.name,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 19,
                  height: 19,
                  child: CustomPaint(painter: DiamondIconPainter()),
                ),
                const SizedBox(width: 4),
                Text(
                  '${pack.amount}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.panel,
                  foregroundColor: colors.foreground,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  minimumSize: const Size(0, 48),
                  side: BorderSide(color: colors.outline, width: 3),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${pack.price} ARS',
                    maxLines: 1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// WIDGET DE BOTONES ANIMADOS
class BrutalistButton extends StatefulWidget {
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;

  const BrutalistButton({
    super.key,
    required this.text,
    required this.color,
    this.textColor = Colors.black,
    this.onPressed,
  });

  @override
  State<BrutalistButton> createState() => _BrutalistButtonState();
}

class _BrutalistButtonState extends State<BrutalistButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: Transform.translate(
        offset: _isPressed ? const Offset(4, 4) : Offset.zero,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: widget.color,
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: _isPressed
                ? const []
                : const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
          ),
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(
                color: widget.textColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
