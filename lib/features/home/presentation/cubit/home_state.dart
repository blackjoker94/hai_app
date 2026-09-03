import 'package:hai_app/features/home/data/models/city_news.dart';
import 'package:hai_app/features/home/data/models/hero_progress.dart';
import 'package:hai_app/features/home/data/models/report_model.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState {
  final HomeStatus status;
  final HeroProgress? hero;
  final List<Report> reports;
  final List<CityNews> news;
  final String userName;
  final String userAddress;
  final bool isRefreshing;
  final String? reportsError;

  const HomeState({
    this.status = HomeStatus.initial,
    this.hero,
    this.reports = const [],
    this.news = const [],
    this.userName = '',
    this.userAddress = '',
    this.isRefreshing = false,
    this.reportsError,
  });

  HomeState copyWith({
    HomeStatus? status,
    HeroProgress? hero,
    List<Report>? reports,
    List<CityNews>? news,
    String? userName,
    String? userAddress,
    bool? isRefreshing,
    String? reportsError,
  }) {
    return HomeState(
      status: status ?? this.status,
      hero: hero ?? this.hero,
      reports: reports ?? this.reports,
      news: news ?? this.news,
      userName: userName ?? this.userName,
      userAddress: userAddress ?? this.userAddress,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      reportsError: reportsError ?? this.reportsError,
    );
  }
}