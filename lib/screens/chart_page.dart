import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, List<Transaction>> _groupTransactionsByDate(
      List<Transaction> transactions) {
    Map<String, List<Transaction>> grouped = {};

    for (var tx in transactions) {
      String formattedDate;
      DateTime now = DateTime.now();
      DateTime txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime yesterday = today.subtract(const Duration(days: 1));

      if (txDate == today) {
        formattedDate = "Today";
      } else if (txDate == yesterday) {
        formattedDate = "Yesterday";
      } else {
        formattedDate = DateFormat.yMMMMd().format(tx.date);
      }

      grouped.putIfAbsent(formattedDate, () => []);
      grouped[formattedDate]!.add(tx);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final transactions = Provider.of<TransactionProvider>(context).transactions;
    final spends = transactions.where((t) => !t.isIncome).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final incomes = transactions.where((t) => t.isIncome).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final totalSpend = spends.fold(0.0, (sum, tx) => sum + tx.amount);
    final totalIncome = incomes.fold(0.0, (sum, tx) => sum + tx.amount);
    final hasData = totalSpend > 0 || totalIncome > 0;
    final isDark = context.watch<AppThemeProvider>().isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar
          SliverAppBar(
            expandedHeight: 70,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "Analytics",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark 
                      ? [Colors.teal.shade900, Colors.teal.shade700]
                      : [Colors.teal.shade100, Colors.teal.shade200],
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: hasData
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Summary Cards
                        _buildSummaryCards(totalIncome, totalSpend, isDark),
                        const SizedBox(height: 24),
                        
                        // Chart Tabs
                        _buildChartTabs(isDark),
                        const SizedBox(height: 16),
                        
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
                        const SizedBox(height: 24),
                        
                        // Transaction Lists
                        _buildTransactionLists(spends, incomes, isDark),
                        const SizedBox(height: 120), // Increased bottom spacing
                      ],
                    ),
                  )
                : _buildEmptyState(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double totalIncome, double totalSpend, bool isDark) {
    final netBalance = totalIncome - totalSpend;
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            "Income",
            totalIncome,
            Colors.green,
            Icons.trending_up,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            "Expenses",
            totalSpend,
            Colors.red,
            Icons.trending_down,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            "Balance",
            netBalance,
            netBalance >= 0 ? Colors.blue : Colors.orange,
            Icons.account_balance_wallet,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon, bool isDark) {
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 16),
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
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTabs(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12), // Smaller radius for half height
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.teal,
          borderRadius: BorderRadius.circular(12), // Smaller radius for half height
        ),
        indicatorPadding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 4), // Reduced vertical padding
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white70 : Colors.black87,
        labelStyle: GoogleFonts.nunito(
          fontSize: 11, // Smaller font
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontSize: 11, // Smaller font
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: "Overview"),
          Tab(text: "Trends"),
          Tab(text: "Categories"),
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '₹${amount.toStringAsFixed(2)}',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.teal,
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

  Widget _buildTransactionLists(List<Transaction> spends, List<Transaction> incomes, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "Recent Transactions",
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        // Single column layout for better readability
        _buildTransactionsList(spends, incomes),
      ],
    );
  }

  Widget _buildTransactionsList(List<Transaction> spends, List<Transaction> incomes) {
    // Combine and sort all transactions by date
    List<Transaction> allTransactions = [...spends, ...incomes];
    allTransactions.sort((a, b) => b.date.compareTo(a.date));
    
    final grouped = _groupTransactionsByDate(allTransactions);
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        String dateKey = grouped.keys.elementAt(index);
        List<Transaction> dayTxs = grouped[dateKey]!;
        
        // Separate income and expenses for this day
        List<Transaction> dayIncomes = dayTxs.where((t) => t.isIncome).toList();
        List<Transaction> dayExpenses = dayTxs.where((t) => !t.isIncome).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.teal.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  dateKey,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ),
            ),
            
            // Income transactions
            if (dayIncomes.isNotEmpty) ...[
              _buildSectionHeader("Income", Colors.green, Icons.trending_up),
              ...dayIncomes.map((tx) => TransactionTile(
                transaction: tx,
                index: index,
              )).toList(),
            ],
            
            // Expense transactions
            if (dayExpenses.isNotEmpty) ...[
              _buildSectionHeader("Expenses", Colors.red, Icons.trending_down),
              ...dayExpenses.map((tx) => TransactionTile(
                transaction: tx,
                index: index,
              )).toList(),
            ],
            
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "No Data to Analyze",
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add some transactions to see your analytics",
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
