import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:namer_app/theme/theme.dart';
import '../services/insight.dart';

class InsightGraphsPage extends StatefulWidget {
  @override
  _InsightGraphsPageState createState() => _InsightGraphsPageState();
}

class _InsightGraphsPageState extends State<InsightGraphsPage> {
  final InsightService _insightService = InsightService();
  List<ProfitData> _profitData = [];
  List<SalesData> _salesData = [];
  List<PurchaseData> _purchaseData = [];

  @override
  void initState() {
    super.initState();
    _fetchInsights();
  }

  Future<void> _fetchInsights() async {
    final profitData = await _insightService.getProfitData();
    final salesData = await _insightService.getSalesData();
    final purchaseData = await _insightService.getPurchaseData();

    setState(() {
      _profitData = profitData;
      _salesData = salesData;
      _purchaseData = purchaseData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('3.4 Graphs and Reports', style: AppTheme.headline6),
                SizedBox(height: 24),
                _buildProfitGraph(),
                SizedBox(height: 24),
                _buildSalesGraph(),
                SizedBox(height: 24),
                _buildPurchaseGraph(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfitGraph() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('3.4.1 Profit Graph', style: AppTheme.headline6),
        SizedBox(height: 12),
        Text(
          'Visualize Profit: Display graphical representations of profit trends over time for easy analysis and decision-making.',
          style: AppTheme.bodyText1,
        ),
        SizedBox(height: 16),
        Container(
          height: 300,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: _profitData
                      .map((data) => FlSpot(
                      data.date.millisecondsSinceEpoch.toDouble(),
                      data.profit))
                      .toList(),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 4,
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withOpacity(0.3),
                  ),
                  dotData: FlDotData(
                    show: true,
                    /*dotSize: 3,
                    dotColor: Colors.greenAccent,*/
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 5000,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date =
                      DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text("${date.month}/${date.year}"),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey, width: 1),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  //tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                ),
                handleBuiltInTouches: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesGraph() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('3.4.2 Sales Graph', style: AppTheme.headline6),
        SizedBox(height: 12),
        Text(
          'Sales Trends: Provide graphs that show sales trends, helping to identify patterns and plan future strategies.',
          style: AppTheme.bodyText1,
        ),
        SizedBox(height: 16),
        Container(
          height: 300,
          child: BarChart(
            BarChartData(
              barGroups: _salesData
                  .map((data) => BarChartGroupData(
                x: data.date.millisecondsSinceEpoch,
                barRods: [
                  BarChartRodData(
                    fromY: 0,
                    toY: data.sales,
                    color: Colors.blue,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                  )
                ],
              ))
                  .toList(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 5000,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date =
                      DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text("${date.month}/${date.year}"),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 5000,
                checkToShowHorizontalLine: (value) => value % 5000 == 0,
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey, width: 1),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  //tooltipBgColor: Colors.blueAccent.withOpacity(0.8),
                ),
                /*touchCallback: () {
                  // Handle touch interaction
                },*/
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseGraph() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('3.4.3 Purchase Graph', style: AppTheme.headline6),
        SizedBox(height: 12),
        Text(
          'Purchasing Patterns: Display purchase trends through graphs to analyze spending and inventory needs.',
          style: AppTheme.bodyText1,
        ),
        SizedBox(height: 16),
        Container(
          height: 300,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: _purchaseData
                      .map((data) => FlSpot(
                      data.date.millisecondsSinceEpoch.toDouble(),
                      data.purchase))
                      .toList(),
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 4,
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.red.withOpacity(0.3),
                  ),
                  dotData: FlDotData(
                    show: true,
                    //dotSize: 3,
                    //dotColor: Colors.redAccent,
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 5000,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date =
                      DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text("${date.month}/${date.year}"),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey, width: 1),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                 // gettooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                ),
                handleBuiltInTouches: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
