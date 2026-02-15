import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';
import '../models/stock_movement.dart';
import '../models/stock_session.dart';

class StockReportScreen extends StatefulWidget {
  final int sessionId;

  const StockReportScreen({super.key, required this.sessionId});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  StockSession? _session;
  Map<String, dynamic> _report = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);

    final stockProvider = context.read<StockProvider>();
    _session = await stockProvider.getSessionById(widget.sessionId);
    _report = await stockProvider.calculateDailyStockReport(widget.sessionId);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Stock Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReport,
            tooltip: 'Share Report',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildReport(),
    );
  }

  Widget _buildReport() {
    final movements = (_report['movements'] as List<StockMovement>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildProductTable(movements),
          const SizedBox(height: 24),
          _buildVarianceAnalysis(movements),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DAILY STOCK REPORT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _session?.isClosed == true
                      ? Colors.red.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _session?.isClosed == true ? 'CLOSED' : 'OPEN',
                  style: TextStyle(
                    color: _session?.isClosed == true
                        ? Colors.red
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_session != null) ...[
            _buildInfoRow('Opened:', _formatDateTime(_session!.openTime)),
            if (_session!.closeTime != null)
              _buildInfoRow('Closed:', _formatDateTime(_session!.closeTime!)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalOpening = _report['totalOpeningGrams'] ?? 0;
    final totalSold = _report['totalSoldGrams'] ?? 0;
    final totalExpected = _report['totalExpectedClosingGrams'] ?? 0;
    final totalClosing = _report['totalClosingGrams'] ?? 0;
    final totalVariance = _report['totalVarianceGrams'] ?? 0;
    final totalVarianceValue = _report['totalVarianceValue'] ?? 0.0;

    return Column(
      children: [
        Row(
          children: [
            _buildSummaryCard(
              'Opening Stock',
              '${_formatWeight(totalOpening)}',
              Icons.inventory_2,
              Colors.blue,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              'Total Sold',
              '${_formatWeight(totalSold)}',
              Icons.shopping_cart,
              Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSummaryCard(
              'Expected Closing',
              '${_formatWeight(totalExpected)}',
              Icons.calculate,
              Colors.purple,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              'Actual Closing',
              '${_formatWeight(totalClosing)}',
              Icons.inventory,
              Colors.teal,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: totalVariance >= 0
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: totalVariance >= 0 ? Colors.green : Colors.red,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                'TOTAL VARIANCE',
                style: TextStyle(
                  color: totalVariance >= 0 ? Colors.green : Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${totalVariance >= 0 ? '+' : ''}${_formatWeight(totalVariance)}',
                style: TextStyle(
                  color: totalVariance >= 0 ? Colors.green : Colors.red,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Value: \$${totalVarianceValue.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: totalVariance >= 0 ? Colors.green : Colors.red,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                totalVariance > 0
                    ? 'Stock Gain'
                    : totalVariance < 0
                    ? 'Stock Loss'
                    : 'No Variance',
                style: TextStyle(
                  color: totalVariance >= 0 ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTable(List<StockMovement> movements) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Product Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF1A1A2E)),
              columns: const [
                DataColumn(
                  label: Text('Product', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Opening', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Sold', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text(
                    'Expected',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                DataColumn(
                  label: Text('Actual', style: TextStyle(color: Colors.white)),
                ),
                DataColumn(
                  label: Text(
                    'Variance',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                DataColumn(
                  label: Text('Value', style: TextStyle(color: Colors.white)),
                ),
              ],
              rows: movements.map((m) {
                final variance = m.varianceGrams ?? 0;
                final varianceValue = m.pricePerKg != null
                    ? m.calculateVarianceValue(m.pricePerKg!)
                    : 0.0;

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        m.productName ?? 'Unknown',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${m.openingGrams}g',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${m.soldGrams}g',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${m.expectedClosingGrams}g',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${m.closingGrams ?? '-'}g',
                        style: const TextStyle(color: Colors.teal),
                      ),
                    ),
                    DataCell(
                      Text(
                        m.varianceDisplay,
                        style: TextStyle(
                          color: variance >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '\$${varianceValue.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          color: variance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVarianceAnalysis(List<StockMovement> movements) {
    final losses = movements.where((m) => (m.varianceGrams ?? 0) < 0).toList();
    final gains = movements.where((m) => (m.varianceGrams ?? 0) > 0).toList();

    if (losses.isEmpty && gains.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Perfect! No variance detected.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Variance Analysis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (losses.isNotEmpty) ...[
            const Text(
              'Products with Loss:',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...losses.map(
              (m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      m.productName ?? 'Unknown',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      '${m.varianceGrams}g',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (gains.isNotEmpty) ...[
            const Text(
              'Products with Gain:',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...gains.map(
              (m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      m.productName ?? 'Unknown',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      '+${m.varianceGrams}g',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _shareReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report sharing will be available in future update'),
        backgroundColor: Color(0xFF0F3460),
      ),
    );
  }

  String _formatDateTime(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }

  String _formatWeight(int grams) {
    if (grams.abs() >= 1000) {
      return '${(grams / 1000).toStringAsFixed(2)}kg';
    }
    return '${grams}g';
  }
}
