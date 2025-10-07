import 'package:equatable/equatable.dart';

abstract class SalesEvent extends Equatable {
  const SalesEvent();

  @override
  List<Object?> get props => [];
}

class LoadSales extends SalesEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? staffId;

  const LoadSales({
    this.startDate,
    this.endDate,
    this.staffId,
  });

  @override
  List<Object?> get props => [startDate, endDate, staffId];
}

class RefreshSales extends SalesEvent {
  const RefreshSales();
}

class FilterSalesByDate extends SalesEvent {
  final DateTime startDate;
  final DateTime endDate;

  const FilterSalesByDate({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

class FilterSalesByStaff extends SalesEvent {
  final String staffId;

  const FilterSalesByStaff(this.staffId);

  @override
  List<Object?> get props => [staffId];
}

class ClearSalesFilter extends SalesEvent {
  const ClearSalesFilter();
}
