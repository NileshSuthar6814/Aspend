import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models/transaction.dart';
import '../models/person_transaction.dart';
import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/person_provider.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/balance_card.dart';
import 'package:hive/hive.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  double _currentBalance = 0;
  late AnimationController _fabController;
  late Animation<double> _fabScale;
  late AnimationController _fabVisibilityController;
  late ScrollController _scrollController;
  bool _showFab = true;

  // Add search state
  String? _searchQuery;
  List<Transaction>? _filteredTransactions;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
    
    // New FAB visibility animation controller
    _fabVisibilityController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scrollController = ScrollController();
    
    // Optimized scroll listener with debouncing
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      
      final atTop = _scrollController.position.pixels <= 0;
      final txns = context.read<TransactionProvider>().transactions;
      final isEmpty = txns.isEmpty;
      final shouldShowFab = atTop || isEmpty;
      
      // Only update state if there's an actual change
      if (shouldShowFab != _showFab) {
        setState(() => _showFab = shouldShowFab);
      }
    });
    
    _currentBalance; // ✅ Load from Hive
  }

  @override
  void dispose() {
    _fabController.dispose();
    _fabVisibilityController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void balance() {
    final box = Hive.box<double>('_currentBalance');
    setState(() {
      _currentBalance = box.get('_currentBalance', defaultValue: 0.0)!;
    });
  }

  void onBalanceUpdate(double newBalance) {
    final box = Hive.box<double>('_currentBalance');
    box.put('_currentBalance', newBalance); // ✅ Save to Hive
    setState(() {
      _currentBalance = newBalance;
    });
  }

  Future<void> _handleRefresh() async {
    Provider.of<TransactionProvider>(context, listen: false).loadTransactions();
    // Optionally, you can also reload balance or other data here
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<AppThemeProvider>().isDarkMode;
    final useAdaptive = context.watch<AppThemeProvider>().useAdaptiveColor;
    final transactionProvider = context.watch<TransactionProvider>();
    final txns =
        _filteredTransactions ?? transactionProvider.sortedTransactions;
    final balance = transactionProvider.totalBalance;
    final grouped = _groupTransactionsByDate(txns);
    final hasTransactions = txns.isNotEmpty;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LiquidPullToRefresh(
        onRefresh: _handleRefresh,
        showChildOpacityTransition: false,
        color: theme.colorScheme.primary,
        backgroundColor: theme.scaffoldBackgroundColor,
        animSpeedFactor: 2.0,
        child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Enhanced App Bar with Glass Effect
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            elevation: 1,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "Aspends Tracker",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
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
                                      theme.colorScheme.primary
                                          .withOpacity(0.8),
                                      theme.colorScheme.primaryContainer
                                          .withOpacity(0.8)
                                    ],
                                  )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                    colors: [
                                      theme.colorScheme.primary
                                          .withOpacity(0.8),
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
              actions: [
              IconButton(
                icon: Icon(
                  Icons.analytics_outlined,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                    _showAnalyticsDialog(context);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showSearchDialog(context);
                },
              ),
            ],
          ),
          // Balance Card and Header
          SliverToBoxAdapter(
            child: Column(
              children: [
                BalanceCard(
                  balance: balance,
                  onBalanceUpdate: (newBalance) async {
                    final box = Hive.box<double>('balanceBox');
                    await box.put('startingBalance', newBalance);
                    Provider.of<TransactionProvider>(context, listen: false)
                        .updateBalance(newBalance);
                  },
                ),
                Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: Colors.teal.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Recent Transactions",
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      const Spacer(),
                      Builder(
                        builder: (context) {
                            final sortByNewest = context
                                .watch<TransactionProvider>()
                                .sortByNewestFirst;
                            return IconButton(
                              tooltip: sortByNewest
                                  ? 'Sort by Oldest'
                                  : 'Sort by Newest',
                              icon: Icon(
                                sortByNewest
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: Colors.teal.shade700,
                              size: 20,
                            ),
                            onPressed: () {
                                context
                                    .read<TransactionProvider>()
                                    .toggleSortOrder();
                              },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Transaction List
          if (hasTransactions)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  String dateKey = grouped.entries.elementAt(index).key;
                  List<Transaction> dayTxs = grouped[dateKey]!;
                  final sortByNewest = transactionProvider.sortByNewestFirst;
                    List<Transaction> dayIncomes = dayTxs
                        .where((t) => t.isIncome)
                        .toList()
                      ..sort((a, b) => sortByNewest
                          ? b.date.compareTo(a.date)
                          : a.date.compareTo(b.date));
                    List<Transaction> dayExpenses = dayTxs
                        .where((t) => !t.isIncome)
                        .toList()
                      ..sort((a, b) => sortByNewest
                          ? b.date.compareTo(a.date)
                          : a.date.compareTo(b.date));
                    int transactionIndex = 0;

                  // Parse the dateKey to DateTime for formatting
                  DateTime? parsedDate;
                  try {
                    parsedDate = DateTime.parse(dateKey);
                  } catch (_) {
                    parsedDate = null;
                  }
                  String formattedDate = dateKey;
                  if (parsedDate != null) {
                      formattedDate =
                          DateFormat('EEEE, d MMMM').format(parsedDate);
                    }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Combined Date and Transaction Type Header
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Row(
                          children: [
                            // Date Badge
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: useAdaptive
                                      ? theme.colorScheme.primary
                                          .withOpacity(0.1)
                                      : Colors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: useAdaptive
                                        ? theme.colorScheme.primary
                                            .withOpacity(0.3)
                                        : Colors.teal.withOpacity(0.3),
                                    width: 1,
                                ),
                              ),
                              child: Text(
                                formattedDate,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                    color: useAdaptive
                                        ? theme.colorScheme.primary
                                        : Colors.teal.shade700,
                                  ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Income Badge
                            if (dayIncomes.isNotEmpty)
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                      Icon(Icons.trending_up,
                                          color: Colors.green, size: 12),
                                      const SizedBox(width: 4),
                                    Text(
                                      "Income",
                                      style: GoogleFonts.nunito(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(width: 6),
                            // Expense Badge
                            if (dayExpenses.isNotEmpty)
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                      Icon(Icons.trending_down,
                                          color: Colors.red, size: 12),
                                      const SizedBox(width: 4),
                                    Text(
                                      "Expenses",
                                      style: GoogleFonts.nunito(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                        ...dayIncomes
                            .map((tx) => TransactionTile(
                                transaction: tx, index: transactionIndex++))
                            .toList(),
                        ...dayExpenses
                            .map((tx) => TransactionTile(
                                transaction: tx, index: transactionIndex++))
                            .toList(),
                        const SizedBox(height: 12),
                    ],
                  );
                },
                childCount: grouped.length,
              ),
            )
          else
            SliverToBoxAdapter(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 72,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "No Transactions Yet",
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Add your first transaction to get started",
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          // Bottom padding for better readability
          SliverToBoxAdapter(
              child:
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 70),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 21),
        child: AnimatedSlide(
        offset: _showFab ? Offset.zero : const Offset(0, 1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: _showFab ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Income FAB
                          ZoomTapAnimation(
                                    onTap: () {
                              _fabController
                                  .forward()
                                  .then((_) => _fabController.reverse());
                              _showAddTransactionDialog(context,
                                  isIncome: true);
                              HapticFeedback.heavyImpact();
                                    },
                            child: ScaleTransition(
                              scale: _fabScale,
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                    colors: [
                                      Colors.green,
                                      Colors.green.shade600
                                    ],
                                  ),
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Expense FAB
                          ZoomTapAnimation(
                                    onTap: () {
                              _fabController
                                  .forward()
                                  .then((_) => _fabController.reverse());
                              _showAddTransactionDialog(context,
                                  isIncome: false);
                              HapticFeedback.heavyImpact();
                                    },
                            child: ScaleTransition(
                              scale: _fabScale,
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.red, Colors.red.shade600],
                                        ),
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.remove,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ),
            ),
      ),
    );
  }

  // Helper to group transactions by date for filtered results
  Map<String, List<Transaction>> _groupTransactionsByDate(
      List<Transaction> txns) {
    final Map<String, List<Transaction>> grouped = {};
    for (final tx in txns) {
      final dateKey =
          "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}";
      grouped.putIfAbsent(dateKey, () => []).add(tx);
    }
    return grouped;
  }

  void _showSearchDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark =
        Provider.of<AppThemeProvider>(context, listen: false).isDarkMode;
    final searchController = TextEditingController(text: _searchQuery ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.dialogBackgroundColor,
        title: Row(
          children: [
            Icon(Icons.search, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(
          "Search Transactions",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
              ),
          ),
          ],
        ),
        content: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: "Enter transaction note, category, or account...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Text(
              "Cancel",
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text("Search"),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              final query = searchController.text.trim().toLowerCase();
              if (query.isEmpty) {
                setState(() {
                  _searchQuery = null;
                  _filteredTransactions = null;
                });
                Navigator.pop(context);
                return;
              }
              final allTxns =
                  Provider.of<TransactionProvider>(context, listen: false)
                      .sortedTransactions;
              final filtered = allTxns
                  .where((tx) =>
                      tx.note.toLowerCase().contains(query) ||
                tx.category.toLowerCase().contains(query) ||
                      tx.account.toLowerCase().contains(query))
                  .toList();
              setState(() {
                _searchQuery = query;
                _filteredTransactions = filtered;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(filtered.isEmpty
                      ? "No transactions found."
                      : "Showing results for '$query'"),
                  backgroundColor: filtered.isEmpty ? Colors.red : Colors.blue,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          if (_searchQuery != null && _searchQuery!.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = null;
                  _filteredTransactions = null;
                });
                Navigator.pop(context);
              },
              child: Text("Clear Search", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context,
      {required bool isIncome}) {
    final _formKey = GlobalKey<FormState>();
    final _amountController = TextEditingController();
    final _noteController = TextEditingController();
    String _category = isIncome ? "Salary" : "Food";
    String _account = "Cash";
    bool _isIncome = isIncome;
    List<String> _imagePaths = [];
    final theme = Theme.of(context);
    final isDark =
        Provider.of<AppThemeProvider>(context, listen: false).isDarkMode;
    // final overlayKey = GlobalKey<SuccessOverlayState>();
    Transaction? _lastAddedTx;

    // Predefined categories
    final List<String> incomeCategories = [
      "Salary",
      "Freelance",
      "Investment",
      "Gift",
      "Refund",
      "Other"
    ];
    final List<String> expenseCategories = [
      "Food",
      "Transport",
      "Shopping",
      "Bills",
      "Entertainment",
      "Health",
      "Education",
      "Other"
    ];
    final List<String> accounts = [
      "Cash", "Online", "Credit Card", "Bank"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              minWidth: 320,
            ),
            child: Material(
              color: theme.dialogBackgroundColor,
              borderRadius: const BorderRadius.all(Radius.circular(28)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                children: [
                  Icon(
                    isIncome ? Icons.add_circle : Icons.remove_circle,
                    color: isIncome ? Colors.green : Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isIncome ? "Add Income" : "Add Expense",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.close,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7)),
                              onPressed: () => Navigator.pop(context),
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: "Amount",
                            prefixText: "₹ ",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (val) => val == null || val.isEmpty
                              ? "Enter amount"
                              : null,
                        ),
                        const SizedBox(height: 16),
                        StatefulBuilder(
                          builder: (context, setState) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 70,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: _imagePaths.length + 1,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 12),
                                          itemBuilder: (context, idx) {
                                            if (idx < _imagePaths.length) {
                                              final path = _imagePaths[idx];
                                              return Stack(
                                                alignment: Alignment.topRight,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (_) => Dialog(
                                                          backgroundColor:
                                                              Colors.black,
                                                          insetPadding:
                                                              EdgeInsets.zero,
                                                          child:
                                                              InteractiveViewer(
                                                            child: Image.file(
                                                              File(path),
                                                              fit: BoxFit
                                                                  .contain,
                                                              filterQuality:
                                                                  FilterQuality
                                                                      .high,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                              color: Colors.grey
                                                                  .withOpacity(
                                                                      0.18),
                                                              width: 1),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.08),
                                                              blurRadius: 8,
                                                              offset:
                                                                  const Offset(
                                                                      0, 4),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Image.file(
                                                          File(path),
                                                          fit: BoxFit.cover,
                                                          width: 80,
                                                          height: 80,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 2,
                                                    right: 2,
                                                    child: Row(
                                                      children: [
                                                        GestureDetector(
                                                          onTap: () async {
                                                            final ImagePicker
                                                                picker =
                                                                ImagePicker();
                                                            final XFile? image =
                                                                await picker.pickImage(
                                                                    source: ImageSource
                                                                        .gallery);
                                                            if (image != null) {
                                                              setState(() {
                                                                _imagePaths[
                                                                        idx] =
                                                                    image.path;
                                                              });
                                                            }
                                                          },
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.6),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(2),
                                                            child: const Icon(
                                                                Icons.edit,
                                                                color: Colors
                                                                    .white,
                                                                size: 16),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        GestureDetector(
                                                          onTap: () {
                                                            setState(() {
                                                              _imagePaths
                                                                  .removeAt(
                                                                      idx);
                                                            });
                                                          },
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.6),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(2),
                                                            child: const Icon(
                                                                Icons.close,
                                                                color: Colors
                                                                    .white,
                                                                size: 16),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            } else {
                                              // Add Image button
                                              return GestureDetector(
                                                onTap: () async {
                                                  final ImagePicker picker =
                                                      ImagePicker();
                                                  final XFile? image =
                                                      await picker.pickImage(
                                                          source: ImageSource
                                                              .gallery);
                                                  if (image != null) {
                                                    setState(() {
                                                      _imagePaths
                                                          .add(image.path);
                                                    });
                                                  }
                                                },
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      alignment:
                                                          Alignment.center,
                                                      width: 110,
                                                      height: 50,
                                                      decoration: BoxDecoration(
                                                        color: theme.colorScheme
                                                            .surface,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        border: Border.all(
                                                          color: theme
                                                              .colorScheme
                                                              .primary
                                                              .withOpacity(0.3),
                                                          width: 1,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.04),
                                                            blurRadius: 4,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          const SizedBox(
                                                              width: 10),
                                                          Icon(
                                                              Icons
                                                                  .camera_alt_outlined,
                                                              color: theme
                                                                  .colorScheme
                                                                  .primary,
                                                              size: 18),
                                                          const SizedBox(
                                                              width: 6),
                                                          Text("Add Image",
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: theme
                                                                      .colorScheme
                                                                      .primary)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          },
                        ),
                        TextFormField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            labelText: "Note (Optional)",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _category,
                          decoration: InputDecoration(
                            labelText: "Category",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                          items:
                              (isIncome ? incomeCategories : expenseCategories)
                                  .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            HapticFeedback.lightImpact();
                            _category = val!;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _account,
                          decoration: InputDecoration(
                            labelText: "Account",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                          items: accounts
                              .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            HapticFeedback.lightImpact();
                            _account = val!;
                          },
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                                style:
                                    TextStyle(color: theme.colorScheme.primary),
                              ),
                ),
                            const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: Icon(isIncome ? Icons.add : Icons.remove),
                              label:
                                  Text(isIncome ? "Add Income" : "Add Expense"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isIncome ? Colors.green : Colors.red,
                                foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (_formKey.currentState!.validate()) {
                      final tx = Transaction(
                                    amount:
                                        double.parse(_amountController.text),
                                    note: _noteController.text,
                        category: _category,
                        account: _account,
                        date: DateTime.now(),
                        isIncome: _isIncome,
                                    imagePaths: _imagePaths.isNotEmpty
                                        ? List<String>.from(_imagePaths)
                                        : null,
                                  );
                                  Provider.of<TransactionProvider>(context,
                                          listen: false)
                                      .addTransaction(tx);
                                  _lastAddedTx = tx;
                      _checkAndAddPersonTransactions(tx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                                        isIncome
                                            ? "Income added successfully!"
                                            : "Expense added successfully!",
                                      ),
                                      backgroundColor:
                                          isIncome ? Colors.green : Colors.red,
                                      behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(
                            label: 'Undo',
                            textColor: Colors.white,
                            onPressed: () {
                                          Provider.of<TransactionProvider>(
                                                  context,
                                                  listen: false)
                                              .deleteTransaction(_lastAddedTx!);
                            },
                          ),
                        ),
                      );
                                  if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                                  }
                    }
                  },
                ),
              ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _checkAndAddPersonTransactions(Transaction tx) {
    // Get all people from the person provider
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    final people = personProvider.people;
    
    // Check if any person name appears in the transaction note
    for (final person in people) {
      final personName = person.name.toLowerCase();
      final note = tx.note.toLowerCase();
      
      // Check if person name is mentioned in the note
      if (note.contains(personName)) {
        // Create a person transaction
        final personTx = PersonTransaction(
          personName: person.name,
          amount: tx.amount,
          note: tx.note,
          date: tx.date,
          isIncome: tx.isIncome,
        );
        
        // Add the person transaction
        personProvider.addTransaction(personTx);
        
        // Show a subtle notification that person transaction was added
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Transaction also added to ${person.name}'s record",
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showAnalyticsDialog(BuildContext context) {
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    final totalIncome = transactionProvider.totalIncome;
    final totalSpend = transactionProvider.totalSpend;
    final count = transactionProvider.transactions.length;
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.dialogBackgroundColor,
        title: Row(
          children: [
            Icon(Icons.analytics, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text("Analytics", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Total Transactions: $count", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Total Income: ₹${totalIncome.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 16, color: Colors.green)),
            const SizedBox(height: 8),
            Text("Total Expenses: ₹${totalSpend.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 16, color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close",
                style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}
