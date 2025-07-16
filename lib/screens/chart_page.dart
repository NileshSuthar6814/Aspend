import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';
import 'dart:ui';
import '../models/transaction.dart';
import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';

class ChartPage extends StatefulWidget {
  ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedChartIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticFeedback.selectionClick();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final transactions = transactionProvider.sortedTransactions;
    final spends = transactionProvider.spends;
    final incomes = transactionProvider.incomes;
    final totalSpend = transactionProvider.totalSpend;
    final totalIncome = transactionProvider.totalIncome;
    final hasData = totalSpend > 0 || totalIncome > 0;
    final theme = Theme.of(context);
    final isDark = context.watch<AppThemeProvider>().isDarkMode;
    final useAdaptive = context.watch<AppThemeProvider>().useAdaptiveColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Enhanced App Bar
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            elevation: 1,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Analytics',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              background: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: useAdaptive
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
                          )
                        : isDark
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.teal.shade900.withOpacity(0.8), Colors.teal.shade700.withOpacity(0.8)],
                            )
                          : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                              colors: [Colors.teal.shade100.withOpacity(0.8), Colors.teal.shade200.withOpacity(0.8)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            centerTitle: true,
          ),
          
          // Content
          SliverToBoxAdapter(
            child: hasData
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Summary Cards
                        _buildSummaryCards(totalIncome, totalSpend, isDark),
                        const SizedBox(height: 20),
                        
                        // Chart Tabs
                        _buildChartTabs(isDark),
                        const SizedBox(height: 12),
                        
                        // Chart Content
                        SizedBox(
                          height: 300,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildPieChart(totalIncome, totalSpend, isDark),
                              _buildBarChart(transactions, isDark),
                              _buildCategoryChart(transactions, isDark),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  )
                : _buildEmptyState(isDark),
          ),
          if (hasData) ..._buildTransactionLists(spends, incomes, isDark),
          if (hasData)
            SliverToBoxAdapter(child: SizedBox(height: 50)), // Reduced bottom spacing
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double totalIncome, double totalSpend, bool isDark) {
    final netBalance = totalIncome - totalSpend;
    
    return Row(
      children: [
        Expanded(
          child: ZoomTapAnimation(
          child: _buildSummaryCard(
            "Income",
            totalIncome,
            Colors.green,
            Icons.trending_up,
            isDark,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ZoomTapAnimation(
          child: _buildSummaryCard(
            "Expenses",
            totalSpend,
            Colors.red,
            Icons.trending_down,
            isDark,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ZoomTapAnimation(
          child: _buildSummaryCard(
            "Balance",
            netBalance,
            netBalance >= 0 ? Colors.blue : Colors.orange,
            Icons.account_balance_wallet,
            isDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon, bool isDark) {
    final theme = Theme.of(context);
    final c = color;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: c.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: c, size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTabs(bool isDark) {
    final theme = Theme.of(context);
    final useAdaptive = context.watch<AppThemeProvider>().useAdaptiveColor;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      height: 38,
      decoration: BoxDecoration(
        color: useAdaptive ? theme.colorScheme.surface : (isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade100.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: useAdaptive ? theme.colorScheme.outline.withOpacity(0.2) : (isDark ? Colors.grey.shade700.withOpacity(0.3) : Colors.grey.shade300.withOpacity(0.5)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: useAdaptive ? theme.colorScheme.shadow.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: useAdaptive ? theme.colorScheme.primary : Colors.teal.shade400,
          borderRadius: BorderRadius.circular(18),
        ),
        indicatorPadding: const EdgeInsets.symmetric(vertical: 3, horizontal: -6),
        labelColor: useAdaptive ? theme.colorScheme.onPrimary : isDark ? Colors.white : Colors.black,
        unselectedLabelColor: useAdaptive ? theme.colorScheme.primary.withOpacity(0.7) : (isDark ? Colors.white70 : Colors.black87),
        labelStyle: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        tabs: [
          ZoomTapAnimation(child: const Tab(text: "Overview")),
          ZoomTapAnimation(child: const Tab(text: "Trends")),
          ZoomTapAnimation(child: const Tab(text: "Categories")),
        ],
      ),
    );
  }

  Widget _buildPieChart(double totalIncome, double totalSpend, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Income vs Expenses",
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: totalSpend,
                      title: 'Expenses\n₹${totalSpend.toStringAsFixed(2)}',
                      color: Colors.red.shade400,
                      radius: 70,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    PieChartSectionData(
                      value: totalIncome,
                      title: 'Income\n₹${totalIncome.toStringAsFixed(2)}',
                      color: Colors.green.shade400,
                      radius: 70,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                  sectionsSpace: 5,
                  centerSpaceRadius: 25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<Transaction> transactions, bool isDark) {
    // Group transactions by month
    Map<String, double> monthlyData = {};
    for (var tx in transactions) {
      String month = DateFormat.yMMM().format(tx.date);
      if (!monthlyData.containsKey(month)) {
        monthlyData[month] = 0;
      }
      monthlyData[month] = monthlyData[month]! + tx.amount;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Monthly Trends",
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: monthlyData.values.isEmpty ? 100 : monthlyData.values.reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                            String month = monthlyData.keys.elementAt(value.toInt());
                            return Text(
                              month,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: 8,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${value.toInt()}',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 8,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: monthlyData.entries.map((entry) {
                    int index = monthlyData.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: Colors.teal,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(List<Transaction> transactions, bool isDark) {
    final theme = Theme.of(context);
    final useAdaptive = context.watch<AppThemeProvider>().useAdaptiveColor;
    // Group by category
    Map<String, double> categoryData = {};
    for (var tx in transactions) {
      if (!categoryData.containsKey(tx.category)) {
        categoryData[tx.category] = 0;
      }
      categoryData[tx.category] = categoryData[tx.category]! + tx.amount;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Spending by Category",
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categoryData.length,
                itemBuilder: (context, index) {
                  String category = categoryData.keys.elementAt(index);
                  double amount = categoryData[category]!;
                  double percentage = (amount / categoryData.values.reduce((a, b) => a + b)) * 100;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            category,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(useAdaptive ? theme.colorScheme.primary : Colors.teal),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '₹${amount.toStringAsFixed(2)}',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: useAdaptive ? theme.colorScheme.primary : Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTransactionLists(List<Transaction> spends, List<Transaction> incomes, bool isDark) {
    final allTransactions = [...spends, ...incomes];
    final grouped = Provider.of<TransactionProvider>(context, listen: false).groupedTransactions;
    
    return grouped.entries.map((entry) {
      final dateKey = entry.key;
      final dayTxs = entry.value;
      final dayIncomes = dayTxs.where((t) => t.isIncome).toList();
      final dayExpenses = dayTxs.where((t) => !t.isIncome).toList();
      
      return SliverToBoxAdapter(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    dateKey,
                    style: GoogleFonts.nunito(
                  fontSize: 16,
                      fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            ...dayIncomes.map((tx) => TransactionTile(transaction: tx, index: 0)).toList(),
            ...dayExpenses.map((tx) => TransactionTile(transaction: tx, index: 0)).toList(),
            const SizedBox(height: 12),
        ],
      ),
    );
    }).toList();
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.bar_chart,
              size: 60,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Data Available',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some transactions to see analytics',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

