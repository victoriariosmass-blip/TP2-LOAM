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
        // Fondo general: Celeste claro/Hielo[cite: 18]
        scaffoldBackgroundColor: const Color(0xFFCBF3F0), 
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

  // 1. HEADER 
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFBF69), // Naranja arena[cite: 18]
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(6, 6),
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
                  color: const Color(0xFF1A535C), // Azul petróleo oscuro[cite: 18]
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

  // 2. EL TABLERO (Conecta con Flame)
  Widget _buildBoardPlaceholder() {
    return Expanded(
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: const Color(0xFF1A535C), // Fondo del tablero: Azul petróleo oscuro[cite: 18]
          border: Border.all(color: Colors.black, width: 6),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(8, 8),
            ),
          ],
        ),
        child: GameWidget(game: DinoGame()),
      ),
    );
  }

  // 3. CONTROLES EXTERNOS
  Widget _buildControls() {
    return Column(
      children: [
        Row(
          children: [
            // Botón Inicio: Verde turquesa[cite: 18]
            Expanded(child: BrutalistButton(text: 'INICIO', color: const Color(0xFF2EC4B6))),
            const SizedBox(width: 16),
            // Botón Pausa: Naranja arena[cite: 18]
            Expanded(child: BrutalistButton(text: 'PAUSA', color: const Color(0xFFFFBF69))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Botón Reiniciar: Rojo coral[cite: 18]
            Expanded(child: BrutalistButton(text: 'REINICIAR', color: const Color(0xFFFF6B6B))), 
            const SizedBox(width: 16),
            // Botón Nueva: Azul petróleo oscuro[cite: 18]
            Expanded(
              child: BrutalistButton(
                text: 'NUEVA', 
                color: const Color(0xFF1A535C),
                textColor: Colors.white, // Letra blanca para contrastar el fondo oscuro
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// WIDGET DE BOTONES ANIMADOS
class BrutalistButton extends StatefulWidget {
  final String text;
  final Color color;
  final Color textColor;

  const BrutalistButton({
    super.key, 
    required this.text, 
    required this.color,
    this.textColor = Colors.black,
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
      child: Transform.translate(
        offset: _isPressed ? const Offset(4, 4) : Offset.zero,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: widget.color,
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: _isPressed
                ? const []
                : const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(6, 6),
                    ),
                  ],
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