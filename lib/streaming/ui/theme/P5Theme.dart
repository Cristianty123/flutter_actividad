import 'package:flutter/material.dart';

// Colores exactos del repo
const kPersonaRed = Color(0xFFC41001);
const kPersonaBlack = Color(0xFF000000);
const kPersonaWhite = Color(0xFFFFFFFF);
const kPersonaGrey = Color(0xFF2E2E2E);

// Tamaños del avatar (traducidos de TranscriptSizes)
const kAvatarWidth = 110.0;
const kAvatarHeight = 90.0;
const kEntrySpacing = 16.0;

// Rangos de la línea conectora
const kMinLineWidth = 44.0;
const kMaxLineWidth = 60.0;
const kMinLineShift = 16.0;
const kMaxLineShift = 48.0;

// Factor dp → px ya viene de Flutter automáticamente con CustomPainter
// porque Size ya está en px lógicos. No necesitamos multiplicar por dp.