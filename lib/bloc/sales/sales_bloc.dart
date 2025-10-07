import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/sale.dart';
import '../../services/hive_service.dart';
import '../../services/sync_service.dart';
import 'sales_event.dart';
import 'sales_state.dart';

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final SyncService _syncService = SyncService();

  SalesBloc() : super(const SalesState()) {
    on<LoadSales>(_onLoadSales);
    on<RefreshSales>(_onRefreshSales);
    on<FilterSalesByDate>(_onFilterSalesByDate);
    on<FilterSalesByStaff>(_onFilterSalesByStaff);
    on<ClearSalesFilter>(_onClearSalesFilter);
  }

  Future<void> _onLoadSales(LoadSales event, Emitter<SalesState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // First try to sync from Firebase if online
      await _syncService.syncSales();

      // Get sales from local storage
      List<Sale> sales = HiveService.getAllSales();

      // Apply filters if provided
      if (event.startDate != null || event.endDate != null || event.staffId != null) {
        sales = _applyFilters(sales, event.startDate, event.endDate, event.staffId);
      }

      // Calculate totals
      final totalSales = sales.fold(0.0, (sum, sale) => sum + sale.total);
      final totalTransactions = sales.length;

      emit(state.copyWith(
        sales: sales,
        filteredSales: sales,
        isLoading: false,
        filterStartDate: event.startDate,
        filterEndDate: event.endDate,
        filterStaffId: event.staffId,
        totalSales: totalSales,
        totalTransactions: totalTransactions,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load sales: $e',
      ));
    }
  }

  Future<void> _onRefreshSales(RefreshSales event, Emitter<SalesState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // Force sync from Firebase
      await _syncService.forceSyncAll();

      // Reload sales
      add(LoadSales(
        startDate: state.filterStartDate,
        endDate: state.filterEndDate,
        staffId: state.filterStaffId,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to refresh sales: $e',
      ));
    }
  }

  void _onFilterSalesByDate(FilterSalesByDate event, Emitter<SalesState> emit) {
    final filteredSales = _applyFilters(
      state.sales,
      event.startDate,
      event.endDate,
      state.filterStaffId,
    );

    final totalSales = filteredSales.fold(0.0, (sum, sale) => sum + sale.total);
    final totalTransactions = filteredSales.length;

    emit(state.copyWith(
      filteredSales: filteredSales,
      filterStartDate: event.startDate,
      filterEndDate: event.endDate,
      totalSales: totalSales,
      totalTransactions: totalTransactions,
    ));
  }

  void _onFilterSalesByStaff(FilterSalesByStaff event, Emitter<SalesState> emit) {
    final filteredSales = _applyFilters(
      state.sales,
      state.filterStartDate,
      state.filterEndDate,
      event.staffId,
    );

    final totalSales = filteredSales.fold(0.0, (sum, sale) => sum + sale.total);
    final totalTransactions = filteredSales.length;

    emit(state.copyWith(
      filteredSales: filteredSales,
      filterStaffId: event.staffId,
      totalSales: totalSales,
      totalTransactions: totalTransactions,
    ));
  }

  void _onClearSalesFilter(ClearSalesFilter event, Emitter<SalesState> emit) {
    final totalSales = state.sales.fold(0.0, (sum, sale) => sum + sale.total);
    final totalTransactions = state.sales.length;

    emit(state.copyWith(
      filteredSales: state.sales,
      filterStartDate: null,
      filterEndDate: null,
      filterStaffId: null,
      totalSales: totalSales,
      totalTransactions: totalTransactions,
    ));
  }

  List<Sale> _applyFilters(
    List<Sale> sales,
    DateTime? startDate,
    DateTime? endDate,
    String? staffId,
  ) {
    List<Sale> filtered = sales;

    // Filter by date range
    if (startDate != null) {
      filtered = filtered.where((sale) => sale.createdAt.isAfter(startDate) || sale.createdAt.isAtSameMomentAs(startDate)).toList();
    }

    if (endDate != null) {
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      filtered = filtered.where((sale) => sale.createdAt.isBefore(endOfDay) || sale.createdAt.isAtSameMomentAs(endOfDay)).toList();
    }

    // Filter by staff
    if (staffId != null && staffId.isNotEmpty) {
      filtered = filtered.where((sale) => sale.staffId == staffId).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }
}
