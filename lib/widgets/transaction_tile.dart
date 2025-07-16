import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart' show Share;
import 'dart:io';
import 'dart:ui'; // Added for BackdropFilter

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
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            final theme = Theme.of(context);
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Edit'),
                    onTap: () {
                      Navigator.pop(context);
                      _showEditTransactionDialog(context, widget.transaction);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Delete'),
                    onTap: () {
                      Navigator.pop(context);
                      Provider.of<TransactionProvider>(context, listen: false)
                          .deleteTransaction(widget.transaction);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.share),
                    title: const Text('Share'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement share
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.copy),
                    title: const Text('Copy Details'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement copy details
                    },
                  ),
                ],
              ),
            );
          },
        );
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
                            //Colors.grey.shade850,
                            Colors.grey.shade800,
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.40,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return AnimatedBuilder(
            animation: scrollController,
            builder: (context, child) {
              double extent = 0.55;
              try {
                extent = (scrollController.position.viewportDimension + scrollController.position.pixels) /
                    scrollController.position.maxScrollExtent;
                extent = extent.clamp(0.0, 1.0);
              } catch (_) {}
              final double radius = 28 * (1 - extent);
              return Material(
                elevation: 8,
                color: theme.colorScheme.surface,
                surfaceTintColor: theme.colorScheme.surfaceTint,
                borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.outlineVariant.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: textColor.withOpacity(0.7)),
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: categoryColor.withOpacity(0.18),
                              radius: 28,
                              child: Icon(categoryIcon, color: categoryColor, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.transaction.category,
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat.yMMMd().format(widget.transaction.date),
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    color: textColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: widget.transaction.isIncome ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                widget.transaction.isIncome ? 'Income' : 'Expense',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: widget.transaction.isIncome ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildDetailRow("Amount", "₹${widget.transaction.amount.toStringAsFixed(2)}", textColor),
                        _buildDetailRow("Note", widget.transaction.note.isNotEmpty ? widget.transaction.note : "—", textColor),
                        _buildDetailRow("Account", widget.transaction.account, textColor),
                        if (widget.transaction.imagePaths != null && widget.transaction.imagePaths!.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text("Attachments:", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 10),
                          Center(
                            child: SizedBox(
                              height: 110,
                              width: double.infinity,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: widget.transaction.imagePaths!.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 16),
                                itemBuilder: (context, idx) {
                                  final path = widget.transaction.imagePaths![idx];
                                  return GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => _FullScreenImageDialog(
                                          imagePath: path,
                                          heroTag: 'txn-img-${widget.index}-$idx',
                                          isDark: isDark,
                                        ),
                                      );
                                    },
                                    child: Hero(
                                      tag: 'txn-img-${widget.index}-$idx',
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.file(
                                          File(path),
                                          width: 110,
                                          height: 110,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Divider(
                          height: 32,
                          thickness: 1.2,
                          color: theme.colorScheme.outlineVariant.withOpacity(0.25),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _AnimatedPillButton(
                                icon: Icons.edit,
                                label: 'Edit',
                                color: theme.colorScheme.primary,
                                textColor: Colors.white,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _showEditTransactionDialog(context, widget.transaction);
                                },
                              ),
                              _AnimatedPillButton(
                                icon: Icons.delete,
                                label: 'Delete',
                                color: Colors.redAccent,
                                textColor: Colors.white,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Provider.of<TransactionProvider>(context, listen: false)
                                      .deleteTransaction(widget.transaction);
                                },
                              ),
                              _AnimatedPillButton(
                                icon: Icons.share,
                                label: 'Share',
                                color: Colors.blueAccent,
                                textColor: Colors.white,
                                onTap: () {
                                  Share.share('Amount: ₹${widget.transaction.amount.toStringAsFixed(2)}\nNote: ${widget.transaction.note}\nCategory: ${widget.transaction.category}\nAccount: ${widget.transaction.account}\nDate: ${DateFormat.yMMMd().format(widget.transaction.date)}');
                                  Navigator.of(context).pop();
                                },
                              ),
                              _AnimatedPillButton(
                                icon: Icons.copy,
                                label: 'Copy',
                                color: Colors.teal,
                                textColor: Colors.white,
                                onTap: () {
                                  Clipboard.setData(ClipboardData(
                                    text: 'Amount: ₹${widget.transaction.amount.toStringAsFixed(2)}\nNote: ${widget.transaction.note}\nCategory: ${widget.transaction.category}\nAccount: ${widget.transaction.account}\nDate: ${DateFormat.yMMMd().format(widget.transaction.date)}',
                                  ));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Transaction details copied!')),
                                  );
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              );
            }, // AnimatedBuilder
            child: null,
          );
        },
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

class _ImagePreviewWithInteraction extends StatefulWidget {
  final String imagePath;
  final String heroTag;
  final VoidCallback onTap;
  const _ImagePreviewWithInteraction({required this.imagePath, required this.heroTag, required this.onTap});
  @override
  State<_ImagePreviewWithInteraction> createState() => _ImagePreviewWithInteractionState();
}

class _ImagePreviewWithInteractionState extends State<_ImagePreviewWithInteraction> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0.96, upperBound: 1.0);
    _scaleAnim = _controller.drive(Tween(begin: 1.0, end: 0.96));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Hero(
          tag: widget.heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.18), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_loading)
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (_error)
                    const Icon(Icons.broken_image, size: 40, color: Colors.redAccent),
                  Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.cover,
                    height: 140,
                    width: double.infinity,
                    semanticLabel: 'Transaction image',
                    frameBuilder: (context, child, frame, wasSyncLoaded) {
                      if (frame == null) {
                        setState(() => _loading = true);
                        return const SizedBox();
                      } else {
                        if (_loading) setState(() => _loading = false);
                        return child;
                      }
                    },
                    errorBuilder: (context, error, stackTrace) {
                      setState(() {
                        _loading = false;
                        _error = true;
                      });
                      return const Icon(Icons.broken_image, size: 40, color: Colors.redAccent);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullScreenImageDialog extends StatelessWidget {
  final String imagePath;
  final String heroTag;
  final bool isDark;
  const _FullScreenImageDialog({required this.imagePath, required this.heroTag, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred background
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: Colors.black.withOpacity(0.7),
          ),
        ),
        Center(
          child: Hero(
            tag: heroTag,
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(40),
              minScale: 0.8,
              maxScale: 4.0,
                                child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    semanticLabel: 'Full screen transaction image',
                    filterQuality: FilterQuality.high,
                  ),
            ),
          ),
        ),
        // Animated close button
        Positioned(
          top: 32,
          right: 24,
          child: AnimatedSlide(
            offset: Offset.zero,
            duration: const Duration(milliseconds: 300),
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black26,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.close, color: Colors.white, size: 20),
                        SizedBox(width: 4),
                        Text('Close', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FullScreenGalleryDialog extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final String heroTagPrefix;
  final bool isDark;
  const _FullScreenGalleryDialog({required this.imagePaths, required this.initialIndex, required this.heroTagPrefix, required this.isDark});
  @override
  State<_FullScreenGalleryDialog> createState() => _FullScreenGalleryDialogState();
}

class _FullScreenGalleryDialogState extends State<_FullScreenGalleryDialog> {
  late PageController _pageController;
  late int _currentIndex;
  late List<String> _galleryPaths;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _galleryPaths = List<String>.from(widget.imagePaths);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _replaceImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      setState(() {
        _galleryPaths[_currentIndex] = image.path;
      });
    }
  }

  void _deleteImage() {
    if (_galleryPaths.length == 1) {
      // If only one image, close the dialog
      Navigator.pop(context);
      return;
    }
    setState(() {
      _galleryPaths.removeAt(_currentIndex);
      if (_currentIndex >= _galleryPaths.length) {
        _currentIndex = _galleryPaths.length - 1;
        _pageController.jumpToPage(_currentIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred background
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: Colors.black.withOpacity(0.7),
          ),
        ),
        PageView.builder(
          controller: _pageController,
          itemCount: _galleryPaths.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (context, idx) {
            return Center(
              child: Hero(
                tag: '${widget.heroTagPrefix}-$idx',
                child: InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(40),
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Image.file(
                    File(_galleryPaths[idx]),
                    fit: BoxFit.contain,
                    semanticLabel: 'Full screen transaction image',
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            );
          },
        ),
        // Animated close button
        Positioned(
          top: 32,
          right: 24,
          child: AnimatedSlide(
            offset: Offset.zero,
            duration: const Duration(milliseconds: 300),
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.isDark ? Colors.white10 : Colors.black26,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.close, color: Colors.white, size: 20),
                        SizedBox(width: 4),
                        Text('Close', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Gallery indicator
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_currentIndex + 1} / ${_galleryPaths.length}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
        // Edit and Delete buttons
        Positioned(
          bottom: 32,
          right: 32,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'edit-image',
                mini: true,
                backgroundColor: Colors.blueAccent.withOpacity(0.85),
                onPressed: _replaceImage,
                child: const Icon(Icons.edit, color: Colors.white),
                tooltip: 'Replace Image',
              ),
              const SizedBox(width: 16),
              FloatingActionButton(
                heroTag: 'delete-image',
                mini: true,
                backgroundColor: Colors.redAccent.withOpacity(0.85),
                onPressed: _deleteImage,
                child: const Icon(Icons.delete, color: Colors.white),
                tooltip: 'Delete Image',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedPillButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  const _AnimatedPillButton({required this.icon, required this.label, required this.color, required this.textColor, required this.onTap});
  @override
  State<_AnimatedPillButton> createState() => _AnimatedPillButtonState();
}

class _AnimatedPillButtonState extends State<_AnimatedPillButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 80), lowerBound: 0.96, upperBound: 1.0);
    _scaleAnim = _controller.drive(Tween(begin: 1.0, end: 0.96));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _controller.reverse();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _controller.forward();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _controller.forward();
      },
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_pressed ? 0.85 : 1.0),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.textColor, size: 18),
              const SizedBox(width: 8),
              Text(widget.label, style: TextStyle(color: widget.textColor, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedImagePreview extends StatefulWidget {
  final String imagePath;
  final String heroTag;
  final VoidCallback onTap;
  const _AnimatedImagePreview({required this.imagePath, required this.heroTag, required this.onTap});
  @override
  State<_AnimatedImagePreview> createState() => _AnimatedImagePreviewState();
}

class _AnimatedImagePreviewState extends State<_AnimatedImagePreview> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 80), lowerBound: 0.96, upperBound: 1.0);
    _scaleAnim = _controller.drive(Tween(begin: 1.0, end: 0.96));
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: _ImagePreviewWithInteraction(
          imagePath: widget.imagePath,
          heroTag: widget.heroTag,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}
