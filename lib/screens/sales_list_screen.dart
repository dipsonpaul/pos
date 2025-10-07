import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/sales/sales_bloc.dart';
import '../bloc/sales/sales_event.dart';
import '../bloc/sales/sales_state.dart';
import '../models/sale.dart';
import '../services/hive_service.dart';
import '../services/auth_service.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final user = HiveService.getCurrentUser();
    if (user != null && user.role.name == 'staff') {
      context.read<SalesBloc>().add(LoadSales(staffId: user.id));
    } else {
      context.read<SalesBloc>().add(const LoadSales());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AuthService.isAdmin() ? 'Revenue' : 'Sales History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final user = HiveService.getCurrentUser();
              if (user != null && user.role.name == 'staff') {
                context.read<SalesBloc>().add(LoadSales(staffId: user.id));
              } else {
                context.read<SalesBloc>().add(const RefreshSales());
              }
            },
          ),
          if (AuthService.isAdmin())
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(),
            ),
        ],
      ),
      body: BlocConsumer<SalesBloc, SalesState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Summary cards
              if (AuthService.isAdmin()) _buildSummaryCards(state),
              // Sales list
              Expanded(
                child: state.filteredSales.isEmpty
                    ? const Center(
                        child: Text(
                          'No sales found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : _buildSalesList(state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(SalesState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Sales',
              '₹${state.totalSales.toStringAsFixed(2)}',
              Colors.green,
              Icons.attach_money,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Transactions',
              '${state.totalTransactions}',
              Colors.blue,
              Icons.receipt,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Avg. Sale',
              state.totalTransactions > 0
                  ? '₹${(state.totalSales / state.totalTransactions).toStringAsFixed(2)}'
                  : '₹0.00',
              Colors.orange,
              Icons.trending_up,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesList(SalesState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.filteredSales.length,
      itemBuilder: (context, index) {
        final sale = state.filteredSales[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _getPaymentMethodColor(sale.paymentMethod),
              child: Icon(
                _getPaymentMethodIcon(sale.paymentMethod),
                color: Colors.white,
              ),
            ),
            title: Text(
              'Sale #${sale.id.substring(0, 8)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${sale.staffName} • ${DateFormat('MMM dd, yyyy - HH:mm').format(sale.createdAt)}'),
                Text('₹${sale.total.toStringAsFixed(2)} • ${sale.paymentMethod.name.toUpperCase()}'),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer details
                    if (sale.customerName.isNotEmpty || sale.customerPhone.isNotEmpty) ...[
                      const Text(
                        'Customer Details',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (sale.customerName.isNotEmpty)
                        Text('Name: ${sale.customerName}'),
                      if (sale.customerPhone.isNotEmpty)
                        Text('Phone: ${sale.customerPhone}'),
                      const SizedBox(height: 16),
                    ],
                    
                    // Items
                    const Text(
                      'Items',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...sale.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('${item.productName} × ${item.quantity}'),
                          ),
                          Text('₹${item.total.toStringAsFixed(2)}'),
                        ],
                      ),
                    )),
                    const Divider(),
                    
                    // Totals
                    _buildTotalRow('Subtotal', sale.subtotal),
                    _buildTotalRow('Tax', sale.tax),
                    if (sale.discount > 0)
                      _buildTotalRow('Discount', -sale.discount),
                    const Divider(),
                    _buildTotalRow('Total', sale.total, isTotal: true),
                    
                    // Notes
                    if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Notes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(sale.notes!),
                    ],
                    
                    // Sync status
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          sale.isSynced ? Icons.cloud_done : Icons.cloud_off,
                          size: 16,
                          color: sale.isSynced ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sale.isSynced ? 'Synced' : 'Pending Sync',
                          style: TextStyle(
                            color: sale.isSynced ? Colors.green : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Colors.green;
      case PaymentMethod.card:
        return Colors.blue;
      case PaymentMethod.upi:
        return Colors.purple;
      case PaymentMethod.wallet:
        return Colors.orange;
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.upi:
        return Icons.qr_code;
      case PaymentMethod.wallet:
        return Icons.account_balance_wallet;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Sales'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(_startDate != null
                  ? DateFormat('MMM dd, yyyy').format(_startDate!)
                  : 'Select start date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                  });
                }
              },
            ),
            ListTile(
              title: const Text('End Date'),
              subtitle: Text(_endDate != null
                  ? DateFormat('MMM dd, yyyy').format(_endDate!)
                  : 'Select end date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
              });
              context.read<SalesBloc>().add(const ClearSalesFilter());
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<SalesBloc>().add(LoadSales(
                startDate: _startDate,
                endDate: _endDate,
              ));
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
