import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';
import 'dart:io';
import '../models/person.dart';
import '../models/person_transaction.dart';
import '../providers/person_provider.dart';
import '../providers/theme_provider.dart';
//import 'dart:async';
import 'package:flutter/rendering.dart';

class PersonDetailPage extends StatefulWidget {
  final Person person;

  const PersonDetailPage({super.key, required this.person});

  @override
  State<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _PersonDetailPageState extends State<PersonDetailPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late ScrollController _scrollController;
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final atTop = _scrollController.position.pixels <= 0;
      final txs = context.read<PersonProvider>().transactionsFor(widget.person.name);
      final isEmpty = txs.isEmpty;
      final shouldShowFab = atTop || isEmpty;
      
      // Only update state if there's an actual change
      if (shouldShowFab != _showFab) {
        setState(() => _showFab = shouldShowFab);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonProvider>();
    final txs = provider.transactionsFor(widget.person.name);
    final total = provider.totalFor(widget.person.name);
    final isPositive = total >= 0;
    final theme = Theme.of(context);
    final isDark = context.watch<AppThemeProvider>().isDarkMode;
    final useAdaptive = context.watch<AppThemeProvider>().useAdaptiveColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          flexibleSpace: ClipRRect(
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
          title: Text(
            widget.person.name,
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 24,
              ),
              onPressed: () {
                HapticFeedback.heavyImpact();
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedSlide(
        offset: _showFab ? Offset.zero : const Offset(0, 2),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: _showFab ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: FloatingActionButton.extended(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: const Icon(Icons.add, size: 24),
            label: Text(
              'Add Transaction',
              style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              _showAddTxDialog(context);
              HapticFeedback.lightImpact();
            },
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Balance Card
              Container(
                margin: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: useAdaptive
                        ? [ theme.colorScheme.surface,
                        theme.colorScheme.surface.withOpacity(0.8),]
                        : [
                            theme.colorScheme.surface,
                            theme.colorScheme.surface.withOpacity(0.8),
                          ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: widget.person.photoPath != null
                                ? null
                                : useAdaptive
                                    ? LinearGradient(
                                        colors: [
                                          theme.colorScheme.primaryContainer,
                                          theme.colorScheme.secondaryContainer,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : LinearGradient(
                                        colors: [
                                          isPositive ? Colors.green : Colors.red,
                                          isPositive ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8),
                                        ],
                                      ),
                            color: widget.person.photoPath != null
                                ? Colors.transparent
                                : null,
                            borderRadius: BorderRadius.circular(30),
                            border: widget.person.photoPath != null
                                ? Border.all(
                                    color: isPositive ? Colors.green : Colors.red,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: widget.person.photoPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.file(
                                    File(widget.person.photoPath!),
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  isPositive ? Icons.trending_up : Icons.trending_down,
                                  color: useAdaptive ? theme.colorScheme.onPrimaryContainer : Colors.white,
                                  size: 30,
                                ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Balance',
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${total.toStringAsFixed(2)}',
                                style: GoogleFonts.nunito(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: isPositive ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isPositive 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            isPositive ? 'Credit' : 'Debit',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isPositive ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Transactions Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Transactions',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${txs.length}',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Transactions List
              Expanded(
                child: txs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                size: 50,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No transactions yet',
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first transaction with ${widget.person.name}',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                                            : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: txs.length + 1, // +1 for bottom padding
                        itemBuilder: (c, i) {
                          // Add bottom padding as last item
                          if (i == txs.length) {
                            return const SizedBox(height: 80);
                          }
                          
                          final tx = txs[i];
                          final sign = tx.amount >= 0 ? '+' : '';
                          final isPositiveTx = tx.amount >= 0;
                          
                          return AnimatedBuilder(
                            animation: _fadeController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - _fadeController.value)),
                                child: Opacity(
                                  opacity: _fadeController.value,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: GestureDetector(
                                      onLongPress: () {
                                        HapticFeedback.lightImpact();
                                        _showDeleteTransactionDialog(context, tx);
                                      },
                                      child: ZoomTapAnimation(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: useAdaptive
                                                ? [ theme.colorScheme.surface,
                                                theme.colorScheme.surface.withOpacity(0.8),]
                                                : [
                                                    theme.colorScheme.surface,
                                                    theme.colorScheme.surface.withOpacity(0.8),
                                                  ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isDark ? Colors.teal.shade900.withOpacity(0.3) : Colors.teal.withOpacity(0.3),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: theme.colorScheme.shadow.withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: useAdaptive
                                                        ? [ isPositiveTx ? Colors.green : Colors.red,
                                                        isPositiveTx ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8),]
                                                        : [
                                                            isPositiveTx ? Colors.green : Colors.red,
                                                            isPositiveTx ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8),
                                                          ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(25),
                                                  ),
                                                  child: Icon(
                                                    isPositiveTx ? Icons.add : Icons.remove,
                                                    color: Colors.white,
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        tx.note.isEmpty ? 'No note' : tx.note,
                                                        style: GoogleFonts.nunito(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                          color: theme.colorScheme.onSurface,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        DateFormat.yMMMd().add_jm().format(tx.date),
                                                        style: GoogleFonts.nunito(
                                                          fontSize: 14,
                                                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      '$sign₹${tx.amount.abs().toStringAsFixed(2)}',
                                                      style: GoogleFonts.nunito(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: isPositiveTx ? Colors.green : Colors.red,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: isPositiveTx 
                                                            ? Colors.green.withOpacity(0.1)
                                                            : Colors.red.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        isPositiveTx ? 'Credit' : 'Debit',
                                                        style: GoogleFonts.nunito(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: isPositiveTx ? Colors.green : Colors.red,
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
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Person',
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${widget.person.name}? This action cannot be undone.',
          style: GoogleFonts.nunito(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PersonProvider>().deletePerson(widget.person);
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteTransactionDialog(BuildContext context, PersonTransaction tx) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Transaction',
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this transaction?',
          style: GoogleFonts.nunito(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PersonProvider>().deleteTransaction(tx);
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTxDialog(BuildContext context) {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    bool isIncome = true;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Add Transaction',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add a transaction with ${widget.person.name}',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amtCtrl,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: GoogleFonts.nunito(fontSize: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  prefixIcon: Icon(Icons.currency_rupee, color: theme.colorScheme.primary),
                ),
                style: GoogleFonts.nunito(fontSize: 16),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
                  labelStyle: GoogleFonts.nunito(fontSize: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  prefixIcon: Icon(Icons.note_outlined, color: theme.colorScheme.primary),
                ),
                style: GoogleFonts.nunito(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Is Income',
                    style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    isIncome ? 'You received money' : 'You gave money',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  value: isIncome,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    setSt(() => isIncome = v);
                  },
                  activeColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                if (amtCtrl.text.isNotEmpty) {
                  final transaction = PersonTransaction(
                    personName: widget.person.name,
                    amount: double.parse(amtCtrl.text),
                    note: noteCtrl.text,
                    date: DateTime.now(),
                  );
                  
                  context.read<PersonProvider>().addTransaction(transaction);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Add Transaction',
                style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
