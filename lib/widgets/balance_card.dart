import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/responsive_utils.dart';

class BalanceCard extends StatefulWidget {
  final double balance;
  final Function(double) onBalanceUpdate;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.onBalanceUpdate,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.balance >= 0;
    final theme = Theme.of(context);
    final isDark = context.watch<AppThemeProvider>().isDarkMode;
    final useAdaptive = context.watch<AppThemeProvider>().useAdaptiveColor;

    // Get transaction statistics
    final transactionProvider = context.watch<TransactionProvider>();
    final totalIncome = transactionProvider.transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = transactionProvider.transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.lightImpact();
        _showEditBalanceDialog(context, isDark);
      },
      onTap: () {
        HapticFeedback.selectionClick();
        _showBalanceDetails(context, isDark);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: ResponsiveUtils.getResponsiveEdgeInsets(context,
                horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.primaryContainer
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: ResponsiveUtils.getResponsiveEdgeInsets(context,
                  horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Current Balance',
                        style: GoogleFonts.nunito(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20),
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Icon(
                        Icons.account_balance_wallet,
                        color: isDark ? Colors.white70 : Colors.black54,
                        size: ResponsiveUtils.getResponsiveIconSize(context,
                            mobile: 20, tablet: 24, desktop: 28),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: ResponsiveUtils.getResponsiveSpacing(context,
                          mobile: 10, tablet: 12, desktop: 16)),

                  // Balance Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '₹${widget.balance.toStringAsFixed(2)}',
                          style: GoogleFonts.nunito(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                mobile: 28,
                                tablet: 32,
                                desktop: 36),
                            fontWeight: FontWeight.bold,
                            color: isPositive
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.getResponsiveSpacing(
                              context,
                              mobile: 10,
                              tablet: 12,
                              desktop: 14),
                          vertical: ResponsiveUtils.getResponsiveSpacing(
                              context,
                              mobile: 4,
                              tablet: 6,
                              desktop: 8),
                        ),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isPositive ? 'Positive' : 'Negative',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                mobile: 10,
                                tablet: 12,
                                desktop: 14),
                            fontWeight: FontWeight.w600,
                            color: isPositive
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Quick Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Income',
                          totalIncome,
                          Colors.green,
                          Icons.trending_up,
                          isDark,
                        ),
                      ),
                      SizedBox(
                          width: ResponsiveUtils.getResponsiveSpacing(context,
                              mobile: 8, tablet: 12, desktop: 16)),
                      Expanded(
                        child: _buildStatItem(
                          'Expenses',
                          totalExpenses,
                          Colors.red,
                          Icons.trending_down,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, double amount, Color color, IconData icon, bool isDark) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context,
          mobile: 8, tablet: 10, desktop: 12)),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.2)
            : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ResponsiveUtils.getResponsiveIconSize(context,
                    mobile: 20, tablet: 24, desktop: 28),
                height: ResponsiveUtils.getResponsiveIconSize(context,
                    mobile: 20, tablet: 24, desktop: 28),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: ResponsiveUtils.getResponsiveIconSize(context,
                      mobile: 12, tablet: 14, desktop: 16),
                  color: color,
                ),
              ),
              SizedBox(
                  width: ResponsiveUtils.getResponsiveSpacing(context,
                      mobile: 6, tablet: 8, desktop: 10)),
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                      mobile: 10, tablet: 12, desktop: 14),
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(
              height: ResponsiveUtils.getResponsiveSpacing(context,
                  mobile: 4, tablet: 6, desktop: 8)),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 12, tablet: 14, desktop: 16),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showBalanceDetails(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.dialogBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Balance Details',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            // Add more detailed balance information here
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Tap and hold to edit balance'),
              subtitle: const Text('Long press the balance card'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBalanceDialog(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    final controller =
        TextEditingController(text: widget.balance.toStringAsFixed(2));
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              "Edit Balance",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "New Balance",
            prefixText: "₹ ",
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
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Save"),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newBalance = double.tryParse(controller.text);
              if (newBalance != null) {
                widget.onBalanceUpdate(newBalance);
                Navigator.pop(context);

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Balance updated successfully!"),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please enter a valid number"),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
