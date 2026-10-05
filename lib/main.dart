import 'package:flutter/material.dart';
import 'package:flame/game.dart' hide Matrix4;
import 'package:flame/components.dart' hide Matrix4;
import 'package:flame/events.dart';

void main() {
  runApp(const Dino2048App());
}

class Dino2048App extends StatelessWidget {
  const Dino2048App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dino 2048',
      theme: ThemeData(
        // Fondo color arena claro típico de la temática fósil/brutalista
        scaffoldBackgroundColor: const Color(0xFFF3E5D8), 
        // Tipografía por defecto pesada (se recomienda integrar Google Fonts 'Space Mono' luego)
        fontFamily: 'Courier', 
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBoardPlaceholder(),
              const SizedBox(height: 24),
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  // 1. HEADER (Usuario, Score, Cuenta, Diamantes)
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9C46A), // Ocre/Arena oscuro
        border: Border.all(color: Colors.black, width: 4), // Borde grueso
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(6, 6), // Sombra sólida y desplazada
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'USUARIO: JUGADOR1',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A9D8F), // Verde oscuro
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SCORE: 0',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
              ),
              Text(
                '💎 50',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. EL TABLERO (Espacio reservado para Flame)
// 2. EL TABLERO (Motor Flame inyectado)
  Widget _buildBoardPlaceholder() {
    return Expanded(
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge, // Evita que el juego se salga de los bordes
        decoration: BoxDecoration(
          color: const Color(0xFFE76F51),
          border: Border.all(color: Colors.black, width: 6),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(8, 8),
            ),
          ],
        ),
        child: GameWidget(game: DinoGame()), // <-- Aquí arranca Flame
      ),
    );
  }

  // 3. CONTROLES EXTERNOS
  Widget _buildControls() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: BrutalistButton(text: 'INICIO', color: const Color(0xFF2A9D8F))),
            const SizedBox(width: 16),
            Expanded(child: BrutalistButton(text: 'PAUSA', color: const Color(0xFFE9C46A))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: BrutalistButton(text: 'REINICIAR', color: const Color(0xFFF4A261))), // Naranja suave
            const SizedBox(width: 16),
            Expanded(child: BrutalistButton(text: 'NUEVA', color: const Color(0xFFE76F51))), // Terracota
          ],
        ),
      ],
    );
  }
}

// WIDGET REUTILIZABLE PARA BOTONES BRUTALISTAS
// WIDGET REUTILIZABLE PARA BOTONES BRUTALISTAS ANIMADOS
class BrutalistButton extends StatefulWidget {
  final String text;
  final Color color;

  const BrutalistButton({super.key, required this.text, required this.color});

  @override
  State<BrutalistButton> createState() => _BrutalistButtonState();
}

class _BrutalistButtonState extends State<BrutalistButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Detecta cuando el dedo toca la pantalla
      onTapDown: (_) => setState(() => _isPressed = true),
      // Detecta cuando el dedo se levanta (se completa el clic)
      onTapUp: (_) {
        setState(() => _isPressed = false);
        // Aquí conectaremos la lógica del juego más adelante
        print('Botón presionado: ${widget.text}');
      },
      // Detecta si el dedo se desliza fuera del botón antes de soltar
      onTapCancel: () => setState(() => _isPressed = false),
      
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100), // Animación rápida y brusca
        transform: Matrix4.translationValues(
          _isPressed ? 4.0 : 0.0, // Desplazamiento en X
          _isPressed ? 4.0 : 0.0, // Desplazamiento en Y
          0.0,
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: widget.color,
          border: Border.all(color: Colors.black, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              // La sombra desaparece cuando el botón se hunde
              offset: _isPressed ? const Offset(0, 0) : const Offset(4, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.text,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// LÓGICA DEL JUEGO FLAME
class DinoGame extends FlameGame with PanDetector {
  late SpriteComponent ficha;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    // Carga la imagen desde assets/images/
    // Asegúrate de que el nombre coincida exactamente con tu archivo
    final spriteDino = await loadSprite('dino1.png');

    ficha = SpriteComponent(
      sprite: spriteDino,
      size: Vector2(80, 80),
      anchor: Anchor.center,
    );

    ficha.position = size / 2;
    add(ficha);
  }

  @override
  void onPanEnd(DragEndInfo info) {
    final velocity = info.velocity;

    if (velocity.length < 100) return;

    if (velocity.x.abs() > velocity.y.abs()) {
      if (velocity.x > 0) {
        print('Swipe: DERECHA');
        ficha.position.x += 80;
      } else {
        print('Swipe: IZQUIERDA');
        ficha.position.x -= 80;
      }
    } else {
      if (velocity.y > 0) {
        print('Swipe: ABAJO');
        ficha.position.y += 80;
      } else {
        print('Swipe: ARRIBA');
        ficha.position.y -= 80;
      }
    }
  }
}