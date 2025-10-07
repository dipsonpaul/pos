import 'package:equatable/equatable.dart';
import '../../models/sale.dart';

class SalesState extends Equatable {
  final List<Sale> sales;
  final List<Sale> filteredSales;
  final bool isLoading;
  final String? error;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final String? filterStaffId;
  final double totalSales;
  final int totalTransactions;

  const SalesState({
    this.sales = const [],
    this.filteredSales = const [],
    this.isLoading = false,
    this.error,
    this.filterStartDate,
    this.filterEndDate,
    this.filterStaffId,
    this.totalSales = 0.0,
    this.totalTransactions = 0,
  });

  SalesState copyWith({
    List<Sale>? sales,
    List<Sale>? filteredSales,
    bool? isLoading,
    String? error,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    String? filterStaffId,
    double? totalSales,
    int? totalTransactions,
  }) {
    return SalesState(
      sales: sales ?? this.sales,
      filteredSales: filteredSales ?? this.filteredSales,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filterStartDate: filterStartDate ?? this.filterStartDate,
      filterEndDate: filterEndDate ?? this.filterEndDate,
      filterStaffId: filterStaffId ?? this.filterStaffId,
      totalSales: totalSales ?? this.totalSales,
      totalTransactions: totalTransactions ?? this.totalTransactions,
    );
  }

  bool get hasActiveFilters {
    return filterStartDate != null || filterEndDate != null || filterStaffId != null;
  }

  @override
  List<Object?> get props => [
        sales,
        filteredSales,
        isLoading,
        error,
        filterStartDate,
        filterEndDate,
        filterStaffId,
        totalSales,
        totalTransactions,
      ];
}
