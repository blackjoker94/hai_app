import 'package:equatable/equatable.dart';

class ProfileState extends Equatable {
  final bool isDarkMode;
  final String userName;
  final String userRank;
  final int points;

  const ProfileState({
    this.isDarkMode = false,
    this.userName = '',
    this.userRank = '',
    this.points = 0,
  });

  ProfileState copyWith({
    bool? isDarkMode,
    String? userName,
    String? userRank,
    int? points,
  }) {
    return ProfileState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      userName: userName ?? this.userName,
      userRank: userRank ?? this.userRank,
      points: points ?? this.points,
    );
  }

  @override
  List<Object> get props => [isDarkMode, userName, userRank, points];
}