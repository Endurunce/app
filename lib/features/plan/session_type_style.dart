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
  'easy':     SessionStyle(label: 'Rustige duurloop', emoji: '🌿', color: AppColors.easy,     bg: AppColors.easyDim,  paceNote: 'Praattempo · Z1–Z2'),
  'tempo':    SessionStyle(label: 'Tempoloop',        emoji: '🔥', color: AppColors.tempo,    bg: AppColors.tempoDim, paceNote: 'Comfortabel hard · Z3'),
  'long':     SessionStyle(label: 'Lange duurloop',   emoji: '🏞️', color: AppColors.longRun,  bg: AppColors.longDim,  paceNote: 'Rustig & consistent · Z2'),
  'interval': SessionStyle(label: 'Interval',         emoji: '⚡', color: AppColors.interval, bg: AppColors.intDim,   paceNote: 'Hoog intensiteit · Z4–Z5'),
  'hike':     SessionStyle(label: 'Trail / Wandel',   emoji: '🥾', color: AppColors.hike,     bg: AppColors.hikeDim,  paceNote: 'Inclusief wandelpauzes'),
  'rest':     SessionStyle(label: 'Rustdag',          emoji: '☁️', color: AppColors.rest,     bg: AppColors.restDim,  paceNote: ''),
  'cross':    SessionStyle(label: 'Crosstraining',    emoji: '🚴', color: AppColors.cross,    bg: AppColors.crossDim, paceNote: 'Fietsen · zwemmen · yoga'),
  'race':     SessionStyle(label: 'Race Day!',        emoji: '🏆', color: AppColors.race,     bg: AppColors.raceDim,  paceNote: 'Jouw grote dag!'),
};

SessionStyle styleFor(String type) =>
    sessionStyles[type] ?? const SessionStyle(
      label: 'Training', emoji: '🏃', color: AppColors.brand, bg: AppColors.successDim, paceNote: '');

const dayNames = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];
