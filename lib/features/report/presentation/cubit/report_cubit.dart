

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hai_app/features/report/data/remote/report_remote.dart';
import 'package:hai_app/features/report/presentation/cubit/report_state.dart';
import 'package:injectable/injectable.dart';


@injectable
class ReportsCubit extends Cubit<ReportsState> {
  final PostsRemoteDataSource _dataSource;

  ReportsCubit(this._dataSource) : super(const ReportsState()) {
    loadReports();
  }

  Future<void> loadReports() async {
    emit(state.copyWith(status: ReportsStatus.loading));
    try {
      final reports = await _dataSource.fetchUserPosts();
      emit(state.copyWith(status: ReportsStatus.success, allReports: reports));
    } catch (e) {
      emit(state.copyWith(
        status: ReportsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void setFilter(int index) {
    emit(state.copyWith(selectedFilterIndex: index));
  }
}