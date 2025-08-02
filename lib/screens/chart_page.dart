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
import '../utils/responsive_utils.dart';

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
            expandedHeight: ResponsiveUtils.getResponsiveAppBarHeight(context),
            floating: true,
            pinned: true,
            elevation: 1,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Analytics',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                    context,
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
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
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primaryContainer
                              ],
                            )
                          : isDark
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.colorScheme.primary.withOpacity(0.8),
                                    theme.colorScheme.primaryContainer
                                        .withOpacity(0.8)
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.colorScheme.primary.withOpacity(0.8),
                                    theme.colorScheme.primaryContainer
                                        .withOpacity(0.8)
                                  ],
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
                    padding: ResponsiveUtils.getResponsiveEdgeInsets(
                      context,
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Summary Cards
                        _buildSummaryCards(totalIncome, totalSpend, isDark),
                        SizedBox(
                            height: ResponsiveUtils.getResponsiveSpacing(
                                context,
                                mobile: 18,
                                tablet: 24,
                                desktop: 32)),
                        // Chart Tabs
                        _buildChartTabs(isDark),
                        SizedBox(
                            height: ResponsiveUtils.getResponsiveSpacing(
                                context,
                                mobile: 10,
                                tablet: 16,
                                desktop: 20)),
                        // Chart Content
                        SizedBox(
                          height:
                              ResponsiveUtils.getResponsiveChartHeight(context),
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildPieChart(totalIncome, totalSpend, isDark),
                              _buildBarChart(transactions, isDark),
                              _buildCategoryChart(transactions, isDark),
                            ],
                          ),
                        ),
                        SizedBox(
                            height: ResponsiveUtils.getResponsiveSpacing(
                                context,
                                mobile: 16,
                                tablet: 24,
                                desktop: 32)),
                      ],
                    ),
                  )
                : _buildEmptyState(isDark),
          ),
          if (hasData) ..._buildTransactionLists(spends, incomes, isDark),
          if (hasData)
            SliverToBoxAdapter(
                child: SizedBox(height: 50)), // Reduced bottom spacing
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
      double totalIncome, double totalSpend, bool isDark) {
    final netBalance = totalIncome - totalSpend;

    return ResponsiveUtils.responsiveBuilder(
      context: context,
      mobile: Row(
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
          SizedBox(
              width: ResponsiveUtils.getResponsiveSpacing(context,
                  mobile: 12, tablet: 16, desktop: 20)),
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
          SizedBox(
              width: ResponsiveUtils.getResponsiveSpacing(context,
                  mobile: 12, tablet: 16, desktop: 20)),
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
      ),
      tablet: Column(
        children: [
          Row(
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
              SizedBox(
                  width: ResponsiveUtils.getResponsiveSpacing(context,
                      mobile: 12, tablet: 16, desktop: 20)),
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
            ],
          ),
          SizedBox(
              height: ResponsiveUtils.getResponsiveSpacing(context,
                  mobile: 12, tablet: 16, desktop: 20)),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
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
      ),
      desktop: Row(
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
          SizedBox(
              width: ResponsiveUtils.getResponsiveSpacing(context,
                  mobile: 12, tablet: 16, desktop: 20)),
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
          SizedBox(
              width: ResponsiveUtils.getResponsiveSpacing(context,
                  mobile: 12, tablet: 16, desktop: 20)),
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
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, double amount, Color color, IconData icon, bool isDark) {
    final theme = Theme.of(context);
    final c = color;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context,
            mobile: 12, tablet: 16, desktop: 20)),
        child: Column(
          children: [
            Container(
              width: ResponsiveUtils.getResponsiveIconSize(context,
                  mobile: 32, tablet: 40, desktop: 48),
              height: ResponsiveUtils.getResponsiveIconSize(context,
                  mobile: 32, tablet: 40, desktop: 48),
              decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: c.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: c,
                size: ResponsiveUtils.getResponsiveIconSize(context,
                    mobile: 16, tablet: 20, desktop: 24),
              ),
            ),
            SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context,
                    mobile: 6, tablet: 8, desktop: 10)),
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                    mobile: 10, tablet: 12, desktop: 14),
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context,
                    mobile: 2, tablet: 4, desktop: 6)),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: GoogleFonts.nunito(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                    mobile: 14, tablet: 16, desktop: 18),
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
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveSpacing(context,
            mobile: 8, tablet: 12, desktop: 16),
        vertical: ResponsiveUtils.getResponsiveSpacing(context,
            mobile: 4, tablet: 6, desktop: 8),
      ),
      height: ResponsiveUtils.getResponsiveIconSize(context,
          mobile: 38, tablet: 44, desktop: 50),
      decoration: BoxDecoration(
        color: useAdaptive
            ? theme.colorScheme.surface
            : (isDark
                ? Colors.grey.shade900.withOpacity(0.3)
                : Colors.grey.shade100.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: useAdaptive
              ? theme.colorScheme.outline.withOpacity(0.2)
              : (isDark
                  ? Colors.grey.shade700.withOpacity(0.3)
                  : Colors.grey.shade300.withOpacity(0.5)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: useAdaptive
                ? theme.colorScheme.shadow.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
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
        indicatorPadding: EdgeInsets.symmetric(
          vertical: ResponsiveUtils.getResponsiveSpacing(context,
              mobile: 3, tablet: 4, desktop: 5),
          horizontal: ResponsiveUtils.getResponsiveSpacing(context,
              mobile: -6, tablet: -8, desktop: -10),
        ),
        labelColor: useAdaptive
            ? theme.colorScheme.onPrimary
            : isDark
                ? Colors.white
                : Colors.black,
        unselectedLabelColor: useAdaptive
            ? theme.colorScheme.primary.withOpacity(0.7)
            : (isDark ? Colors.white70 : Colors.black87),
        labelStyle: GoogleFonts.nunito(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context,
              mobile: 13, tablet: 14, desktop: 16),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context,
              mobile: 13, tablet: 14, desktop: 16),
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
        padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context,
            mobile: 16, tablet: 20, desktop: 24)),
        child: Column(
          children: [
            Text(
              "Income vs Expenses",
              style: GoogleFonts.nunito(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                    mobile: 16, tablet: 18, desktop: 20),
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context,
                    mobile: 12, tablet: 16, desktop: 20)),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: totalSpend,
                      title: 'Expenses\n₹${totalSpend.toStringAsFixed(2)}',
                      color: Colors.red.shade400,
                      radius: ResponsiveUtils.getResponsiveIconSize(context,
                          mobile: 70, tablet: 80, desktop: 90),
                      titleStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                            mobile: 10, tablet: 12, desktop: 14),
                      ),
                    ),
                    PieChartSectionData(
                      value: totalIncome,
                      title: 'Income\n₹${totalIncome.toStringAsFixed(2)}',
                      color: Colors.green.shade400,
                      radius: ResponsiveUtils.getResponsiveIconSize(context,
                          mobile: 70, tablet: 80, desktop: 90),
                      titleStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                            mobile: 10, tablet: 12, desktop: 14),
                      ),
                    ),
                  ],
                  sectionsSpace: 5,
                  centerSpaceRadius: ResponsiveUtils.getResponsiveIconSize(
                      context,
                      mobile: 25,
                      tablet: 30,
                      desktop: 35),
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
        padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context,
            mobile: 16, tablet: 20, desktop: 24)),
        child: Column(
          children: [
            Text(
              "Monthly Trends",
              style: GoogleFonts.nunito(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                    mobile: 16, tablet: 18, desktop: 20),
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context,
                    mobile: 12, tablet: 16, desktop: 20)),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: monthlyData.values.isEmpty
                      ? 100
                      : monthlyData.values.reduce((a, b) => a > b ? a : b) *
                          1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < monthlyData.length) {
                            String month =
                                monthlyData.keys.elementAt(value.toInt());
                            return Text(
                              month,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                    context,
                                    mobile: 8,
                                    tablet: 10,
                                    desktop: 12),
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
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  mobile: 8,
                                  tablet: 10,
                                  desktop: 12),
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
                          width: ResponsiveUtils.getResponsiveIconSize(context,
                              mobile: 16, tablet: 20, desktop: 24),
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(
                                  ResponsiveUtils.getResponsiveSpacing(context,
                                      mobile: 6, tablet: 8, desktop: 10))),
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
        padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context,
            mobile: 16, tablet: 20, desktop: 24)),
        child: Column(
          children: [
            Text(
              "Spending by Category",
              style: GoogleFonts.nunito(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                    mobile: 16, tablet: 18, desktop: 20),
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context,
                    mobile: 12, tablet: 16, desktop: 20)),
            Expanded(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categoryData.length,
                itemBuilder: (context, index) {
                  String category = categoryData.keys.elementAt(index);
                  double amount = categoryData[category]!;
                  double percentage =
                      (amount / categoryData.values.reduce((a, b) => a + b)) *
                          100;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.getResponsiveSpacing(context,
                            mobile: 4, tablet: 6, desktop: 8)),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            category,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  mobile: 12,
                                  tablet: 14,
                                  desktop: 16),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  useAdaptive
                                      ? theme.colorScheme.primary
                                      : Colors.teal),
                            ),
                          ),
                        ),
                        SizedBox(
                            width: ResponsiveUtils.getResponsiveSpacing(context,
                                mobile: 6, tablet: 8, desktop: 10)),
                        Text(
                          '₹${amount.toStringAsFixed(2)}',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                mobile: 12,
                                tablet: 14,
                                desktop: 16),
                            color: useAdaptive
                                ? theme.colorScheme.primary
                                : Colors.teal,
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

  List<Widget> _buildTransactionLists(
      List<Transaction> spends, List<Transaction> incomes, bool isDark) {
    final allTransactions = [...spends, ...incomes];
    final grouped = Provider.of<TransactionProvider>(context, listen: false)
        .groupedTransactions;

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
              padding: ResponsiveUtils.getResponsiveEdgeInsets(context,
                  horizontal: 16, vertical: 8),
              child: Text(
                dateKey,
                style: GoogleFonts.nunito(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                      mobile: 16, tablet: 18, desktop: 20),
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            ...dayIncomes
                .map((tx) => TransactionTile(transaction: tx, index: 0))
                .toList(),
            ...dayExpenses
                .map((tx) => TransactionTile(transaction: tx, index: 0))
                .toList(),
            SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context,
                    mobile: 12, tablet: 16, desktop: 20)),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      width: double.infinity,
      child: Center(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              width: ResponsiveUtils.getResponsiveIconSize(context,
                  mobile: 120, tablet: 140, desktop: 160),
              height: ResponsiveUtils.getResponsiveIconSize(context,
                  mobile: 120, tablet: 140, desktop: 160),
              decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getResponsiveIconSize(context,
                        mobile: 60, tablet: 70, desktop: 80)),
              ),
            child: Icon(
              Icons.bar_chart,
                size: ResponsiveUtils.getResponsiveIconSize(context,
                    mobile: 60, tablet: 70, desktop: 80),
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
            SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context,
                    mobile: 24, tablet: 32, desktop: 40)),
            Text(
            'No Data Available',
            style: GoogleFonts.nunito(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                    mobile: 24, tablet: 28, desktop: 32),
                fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
            SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context,
                    mobile: 8, tablet: 12, desktop: 16)),
            Padding(
              padding: ResponsiveUtils.getResponsiveEdgeInsets(context,
                  horizontal: 32, vertical: 0),
              child: Text(
                'Add some transactions to see analytics',
            style: GoogleFonts.nunito(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                      mobile: 16, tablet: 18, desktop: 20),
                  color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
              ),
            ),
        ],
        ),
      ),
    );
  }
}
