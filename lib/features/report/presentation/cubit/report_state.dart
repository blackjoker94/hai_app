// lib/features/home/presentation/my_reports/cubit/reports_state.dart

import 'package:hai_app/features/home/data/models/report_model.dart';

enum ReportsStatus { initial, loading, success, failure }

class ReportsState {
  final ReportsStatus status;
  final List<Report> allReports;
  final int selectedFilterIndex; // 0 = all  |  1 = ongoing  |  2 = completed
  final String? errorMessage;

  const ReportsState({
    this.status = ReportsStatus.initial,
    this.allReports = const [],
    this.selectedFilterIndex = 0,
    this.errorMessage,
  });

  // Report.isCompleted is now defined on the unified model — no more error
  List<Report> get filteredReports {
    switch (selectedFilterIndex) {
      case 1:
        return allReports.where((r) => !r.isCompleted).toList();
      case 2:
        return allReports.where((r) => r.isCompleted).toList();
      default:
        return allReports;
    }
  }

  ReportsState copyWith({
    ReportsStatus? status,
    List<Report>? allReports,
    int? selectedFilterIndex,
    String? errorMessage,
  }) {
    return ReportsState(
      status: status ?? this.status,
      allReports: allReports ?? this.allReports,
      selectedFilterIndex: selectedFilterIndex ?? this.selectedFilterIndex,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}