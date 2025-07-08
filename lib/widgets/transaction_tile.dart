import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';

class TransactionTile extends StatefulWidget {
  final Transaction transaction;
  final int index;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.index,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<AppThemeProvider>().isDarkMode;
    final isIncome = widget.transaction.isIncome;
    final amountText = "${isIncome ? '+' : '-'}₹${widget.transaction.amount.toStringAsFixed(2)}";
    
    // Get category icon and color - memoized
    final categoryIcon = _getCategoryIcon(widget.transaction.category);
    final categoryColor = _getCategoryColor(widget.transaction.category);

    return GestureDetector(
      onTapDown: (_) {
        if (!_isPressed) {
          setState(() => _isPressed = true);
          _animationController.forward();
          HapticFeedback.selectionClick();
        }
      },
      onTapUp: (_) {
        if (_isPressed) {
          setState(() => _isPressed = false);
          _animationController.reverse();
        }
      },
      onTapCancel: () {
        if (_isPressed) {
          setState(() => _isPressed = false);
          _animationController.reverse();
        }
      },
      onTap: () {
        HapticFeedback.lightImpact();
        _showDetailsSheet(context, isDark);
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.grey.shade900,
                            Colors.grey.shade800,
                            Colors.grey.shade700,
                          ]
                        : [
                            Colors.white,
                            Colors.grey.shade100,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: isIncome 
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Category Icon
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: categoryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          categoryIcon,
                          color: categoryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Transaction Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Note/Category
                            Text(
                              widget.transaction.note.isNotEmpty 
                                  ? widget.transaction.note 
                                  : widget.transaction.category,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            
                            // Account and Category
                            Row(
                              children: [
                                Icon(
                                  _getAccountIcon(widget.transaction.account),
                                  size: 12,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "${widget.transaction.account} • ${widget.transaction.category}",
                                    style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            
                            // Time
                            Text(
                              DateFormat.jm().format(widget.transaction.date),
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                color: isDark ? Colors.white60 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Amount
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            amountText,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isIncome ? Colors.green.shade600 : Colors.red.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isIncome 
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isIncome ? 'Income' : 'Expense',
                              style: GoogleFonts.nunito(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: isIncome 
                                    ? Colors.green.shade600 
                                    : Colors.red.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'bills':
        return Icons.receipt;
      case 'salary':
        return Icons.work;
      case 'freelance':
        return Icons.computer;
      case 'investment':
        return Icons.trending_up;
      case 'gift':
        return Icons.card_giftcard;
      default:
        return Icons.attach_money;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'shopping':
        return Colors.purple;
      case 'entertainment':
        return Colors.pink;
      case 'health':
        return Colors.red;
      case 'education':
        return Colors.indigo;
      case 'bills':
        return Colors.amber;
      case 'salary':
        return Colors.green;
      case 'freelance':
        return Colors.teal;
      case 'investment':
        return Colors.cyan;
      case 'gift':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  IconData _getAccountIcon(String account) {
    switch (account.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'bank':
        return Icons.account_balance;
      case 'credit card':
        return Icons.credit_card;
      case 'debit card':
        return Icons.payment;
      case 'upi':
        return Icons.phone_android;
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.account_balance_wallet;
    }
  }

  void _showDetailsSheet(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final textColor = isDark ? Colors.white : Colors.black;
    final categoryIcon = _getCategoryIcon(widget.transaction.category);
    final categoryColor = _getCategoryColor(widget.transaction.category);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: theme.dialogBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and amount
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: categoryColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.transaction.isIncome ? 'Income' : 'Expense',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.transaction.isIncome 
                              ? Colors.green.shade600 
                              : Colors.red.shade600,
                        ),
                      ),
                      Text(
                        '₹${widget.transaction.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.nunito(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Details
            _buildDetailRow("Note", widget.transaction.note.isNotEmpty ? widget.transaction.note : "—", textColor),
            _buildDetailRow("Category", widget.transaction.category, textColor),
            _buildDetailRow("Account", widget.transaction.account, textColor),
            _buildDetailRow("Date", DateFormat.yMMMMEEEEd().format(widget.transaction.date), textColor),
            _buildDetailRow("Time", DateFormat.jm().format(widget.transaction.date), textColor),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit"),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      _showEditTransactionDialog(context, widget.transaction);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text("Delete"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      Provider.of<TransactionProvider>(context, listen: false)
                          .deleteTransaction(widget.transaction);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTransactionDialog(BuildContext context, Transaction tx) {
    final theme = Theme.of(context);
    final isDark = Provider.of<AppThemeProvider>(context, listen: false).isDarkMode;
    final _formKey = GlobalKey<FormState>();
    final _amountController = TextEditingController(text: tx.amount.toStringAsFixed(2));
    final _noteController = TextEditingController(text: tx.note);
    String _category = tx.category;
    String _account = tx.account;
    bool _isIncome = tx.isIncome;

    final List<String> incomeCategories = [
      "Salary", "Freelance", "Investment", "Gift", "Refund", "Other"
    ];
    final List<String> expenseCategories = [
      "Food", "Transport", "Shopping", "Bills", "Entertainment", "Health", "Education", "Other"
    ];
    final List<String> accounts = ["Cash", "Bank", "Credit Card", "Digital Wallet"];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Ensure _category is always valid for the current type
          final currentCategories = _isIncome ? incomeCategories : expenseCategories;
          if (!currentCategories.contains(_category)) {
            _category = currentCategories.first;
          }
          // Ensure _account is always valid
          if (!accounts.contains(_account)) {
            _account = accounts.first;
          }
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: theme.dialogBackgroundColor,
            title: Row(
              children: [
                Icon(_isIncome ? Icons.add_circle : Icons.remove_circle, color: _isIncome ? Colors.green : Colors.red, size: 28),
                const SizedBox(width: 12),
                Text(
                  "Edit Transaction",
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Form(
              key: _formKey,
              child: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                        validator: (val) => val == null || val.isEmpty ? "Enter amount" : null,
                      ),
                      const SizedBox(height: 16),
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
                        items: currentCategories
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _category = val!;
                          });
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
                          setState(() {
                            _account = val!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text('Is Income', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600)),
                        subtitle: Text(_isIncome ? 'You received money' : 'You gave money', style: GoogleFonts.nunito(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.7))),
                        value: _isIncome,
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _isIncome = v;
                          });
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Text("Cancel", style: TextStyle(color: theme.colorScheme.primary)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (_formKey.currentState!.validate()) {
                    final newTx = Transaction(
                      amount: double.parse(_amountController.text),
                      note: _noteController.text,
                      category: _category,
                      account: _account,
                      date: tx.date,
                      isIncome: _isIncome,
                    );
                    Provider.of<TransactionProvider>(context, listen: false).updateTransaction(tx, newTx);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Transaction updated successfully!"),
                        backgroundColor: Colors.blue,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
