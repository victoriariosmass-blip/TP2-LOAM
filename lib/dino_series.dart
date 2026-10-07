import 'dart:ui' show Color;

enum AccountType {
  basic,
  pro;

  String get label => this == AccountType.pro ? 'PRO' : 'BASIC';
}

/// Cantidad de etapas por serie: 2, 4, 8, ... 2048 = 11 etapas.
const int kStageCount = 11;

class DinoSeries {
  final String id;
  final String name;

  /// Si es true, solo la cuenta PRO puede usarla.
  final bool proOnly;
  final Color color;

  /// Nombres de archivo dentro de assets/images/, ordenados de la etapa
  /// 1 (valor 2) a la etapa 11 (valor 2048).
  final List<String> images;

  const DinoSeries({
    required this.id,
    required this.name,
    required this.proOnly,
    required this.color,
    required this.images,
  });

  bool isAllowedFor(AccountType account) =>
      !proOnly || account == AccountType.pro;

  /// Devuelve el archivo de imagen para un valor (2, 4, 8...) o null.
  String? imageForValue(int value) {
    if (value < 2 || (value & (value - 1)) != 0) return null;
    final stage = value.bitLength - 2; // 2 -> 0, 4 -> 1, ..., 2048 -> 10
    return stage < images.length ? images[stage] : null;
  }
}

// Lista explícita para la Serie 1 (Básica)
const List<String> _series1Images = [
  'dino1.png',
  'dino2.png',
  'dino3.png',
  'dino4.png',
  'dino5.png',
  'dino6.png',
  'dino7.png',
  'dino8.png',
  'dino9.png',
  'dino10.png',
  'dino11.png',
];

// Lista explícita para la Serie 2 (Pro) - Comparte los 4 primeros
const List<String> _series2Images = [
  'dino1.png',
  'dino2.png',
  'dino3.png',
  'dino4.png',
  'dino5b.png',
  'dino6b.png',
  'dino7b.png',
  'dino8b.png',
  'dino9b.png',
  'dino10b.png',
  'dino11b.png',
];

/// Lista principal de series disponibles en el juego.
final List<DinoSeries> kDinoSeries = [
  DinoSeries(
    id: 'serie_basica',
    name: 'DINO BÁSICOS',
    proOnly: false, // Disponible para BASIC y PRO
    color: const Color(0xFF2EC4B6),
    images: _series1Images,
  ),
  DinoSeries(
    id: 'serie_pro',
    name: 'DINO EVOLUCIÓN (PRO)',
    proOnly: true, // Bloqueada para BASIC, disponible para PRO
    color: const Color(0xFFFFBF69),
    images: _series2Images,
  ),
];