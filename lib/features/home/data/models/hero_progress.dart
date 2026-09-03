// lib/features/home/data/models/hero_progress.dart

import 'package:equatable/equatable.dart';

class HeroProgress extends Equatable {
  final int points;
  final String currentRank;
  final String nextRank;
  final int pointsToNextRank;
  final int activeStepIndex;

  const HeroProgress({
    required this.points,
    required this.currentRank,
    required this.nextRank,
    required this.pointsToNextRank,
    required this.activeStepIndex,
  });


  factory HeroProgress.fromPoints(int points) {
    if (points <= 100) {
      return HeroProgress(
        points: points,
        currentRank: 'مبتدئ',
        nextRank: 'مساعد',
        pointsToNextRank: 101 - points,
        activeStepIndex: 0,
      );
    } else if (points <= 200) {
      return HeroProgress(
        points: points,
        currentRank: 'مساعد',
        nextRank: 'بطل',
        pointsToNextRank: 201 - points,
        activeStepIndex: 1,
      );
    } else if (points <= 300) {
      return HeroProgress(
        points: points,
        currentRank: 'بطل',
        nextRank: 'الكبير',
        pointsToNextRank: 301 - points,
        activeStepIndex: 2,
      );
    } else {
      return HeroProgress(
        points: points,
        currentRank: 'الكبير',
        nextRank: 'الكبير',
        pointsToNextRank: 0,
        activeStepIndex: 3,
      );
    }
  }

  @override
  List<Object?> get props =>
      [points, currentRank, nextRank, pointsToNextRank, activeStepIndex];
}