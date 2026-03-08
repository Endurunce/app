import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';

class SessionStyle {
  final String label;
  final String emoji;
  final Color color;
  final Color bg;
  final String paceNote;

  const SessionStyle({
    required this.label,
    required this.emoji,
    required this.color,
    required this.bg,
    required this.paceNote,
  });
}

const sessionStyles = <String, SessionStyle>{
  'easy':     SessionStyle(label: 'Rustige duurloop', emoji: '🌿', color: AppColors.moss,     bg: AppColors.mossDim,  paceNote: 'Praattempo, Z1-Z2'),
  'tempo':    SessionStyle(label: 'Tempoloop',        emoji: '🔥', color: AppColors.terra,    bg: AppColors.terraDim, paceNote: 'Comfortabel hard, Z3'),
  'long':     SessionStyle(label: 'Lange duurloop',   emoji: '🏞️', color: AppColors.sky,      bg: AppColors.skyDim,   paceNote: 'Rustig & consistent, Z2'),
  'interval': SessionStyle(label: 'Interval',         emoji: '⚡', color: AppColors.terra,    bg: AppColors.terraDim, paceNote: 'Hoog intensiteit, Z4-Z5'),
  'hike':     SessionStyle(label: 'Trail/Wandel mix', emoji: '🥾', color: AppColors.lavender, bg: AppColors.lavDim,   paceNote: 'Inclusief wandelpauzes'),
  'rest':     SessionStyle(label: 'Rustdag',          emoji: '☁️', color: AppColors.stone,    bg: AppColors.stoneDim, paceNote: ''),
  'cross':    SessionStyle(label: 'Crosstraining',    emoji: '🚴', color: AppColors.sand,     bg: AppColors.sandDim,  paceNote: 'Fietsen, zwemmen, yoga'),
  'race':     SessionStyle(label: 'Race Day!',        emoji: '🏆', color: AppColors.gold,     bg: AppColors.goldDim,  paceNote: 'Jouw grote dag!'),
};

SessionStyle styleFor(String type) =>
    sessionStyles[type] ?? const SessionStyle(
      label: 'Training', emoji: '🏃', color: AppColors.ink, bg: AppColors.surface2, paceNote: '');

const dayNames = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];
