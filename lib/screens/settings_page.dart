import 'dart:ui';

import 'package:aspends_tracker/screens/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:aspends_tracker/providers/theme_provider.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:flutter/rendering.dart';
//import 'dart:io';

import '../backup/export_csv.dart';
import '../backup/import_csv.dart';
import '../backup/person_backup_helper.dart';
//import '../models/person.dart';
import '../models/theme.dart';
import '../providers/person_provider.dart';
import '../providers/person_transaction_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/pdf_service.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<AppThemeProvider>().isDarkMode;
    final useAdaptive = context.watch<AppThemeProvider>().useAdaptiveColor;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        //controller: _scrollController,
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
                'Settings',
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
          
          // Settings Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme Section
                  _buildSectionHeader("Appearance", Icons.palette),
                  const SizedBox(height: 12),
                  _buildThemeCard(context, isDark),
                  const SizedBox(height: 16),
                  _buildAdaptiveColorSwitch(context),
                  const SizedBox(height: 24),
                  
                  // Backup & Export Section
                  _buildSectionHeader("Backup & Export", Icons.backup),
                  const SizedBox(height: 12),
                  _buildBackupSection(context, isDark),
                  const SizedBox(height: 24),
                  
                  // Data Management Section
                  _buildSectionHeader("Data Management", Icons.storage),
                  const SizedBox(height: 12),
                  _buildDataManagementSection(context, isDark),
                  const SizedBox(height: 24),
                  
                  // App Info Section
                  _buildSectionHeader("App Information", Icons.info),
                  const SizedBox(height: 12),
                  _buildAppInfoSection(context, isDark),
                  const SizedBox(height: 10 ),
                  // Add developer credit at the very bottom
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 12),
                      child: Text(
                        'Developed with ❤️ by Sthrnilshaa',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    final useAdaptive = context.watch<AppThemeProvider>().useAdaptiveColor;
    return Row(
      children: [
        Icon(
          icon,
          color: useAdaptive ? theme.colorScheme.primary : Colors.teal.shade600,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: useAdaptive ? theme.colorScheme.primary : Colors.teal.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final useAdaptive = context.watch<AppThemeProvider>().useAdaptiveColor;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.palette, size: 24, color: useAdaptive ? theme.colorScheme.primary : Colors.teal.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Theme",
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        "Choose your preferred theme",
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonHideUnderline(
              child: DropdownButton<AppTheme>(
                value: context.watch<AppThemeProvider>().appTheme,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                onChanged: (theme) {
                  HapticFeedback.lightImpact();
                  if (theme != null) {
                    context.read<AppThemeProvider>().setTheme(theme);
                  }
                },
                items: AppTheme.values.map((theme) {
                  final label = theme.toString().split('.').last.capitalize();
                  return DropdownMenuItem(
                    value: theme,
                    child: Text(label),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdaptiveColorSwitch(BuildContext context) {
    final provider = context.watch<AppThemeProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.color_lens, color: Colors.teal.shade600, size: 24),
            const SizedBox(width: 12),
            Text(
              "Adaptive Android Color",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Switch(
          value: provider.useAdaptiveColor,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            provider.setAdaptiveColor(value);
          },
        ),
      ],
    );
  }

  Widget _buildBackupSection(BuildContext context, bool isDark) {
    return Column(
      children: [
        _buildSettingsTile(
          icon: Icons.upload_file,
          title: "Export Transactions",
          subtitle: "Backup your data to CSV",
          onTap: () async {
            HapticFeedback.lightImpact();
            try {
              await DataExporter.shareBackupFile();
              _showSnackBar(context, "Export completed successfully!");
            } catch (e) {
              _showSnackBar(context, "Export failed: $e");
            }
          },
        ),
        _buildSettingsTile(
          icon: Icons.download,
          title: "Import Transactions",
          subtitle: "Restore data from backup",
          onTap: () async {
            HapticFeedback.lightImpact();
            try {
              await DataImporter.importFromJson(context);
              _showSnackBar(context, "Import completed successfully!");
            } catch (e) {
              _showSnackBar(context, "Import failed: $e");
            }
          },
        ),
        _buildSettingsTile(
          icon: Icons.picture_as_pdf,
          title: "Export as PDF",
          subtitle: "Generate PDF reports",
          onTap: () async {
            HapticFeedback.lightImpact();
            try {
              final file = await PDFService.generateHomeTransactionPDF();
              await Printing.sharePdf(
                  bytes: await file.readAsBytes(),
                  filename: 'home_transactions.pdf');
              _showSnackBar(context, "PDF exported successfully!");
            } catch (e) {
              _showSnackBar(context, "PDF export failed: $e");
            }
          },
        ),
        _buildSettingsTile(
          icon: Icons.groups,
          title: "Export People Data",
          subtitle: "Backup people transactions",
          onTap: () async {
            HapticFeedback.lightImpact();
            try {
              final file = await PDFService.generatePeopleTransactionPDF();
              await Printing.sharePdf(
                  bytes: await file.readAsBytes(),
                  filename: 'person_transactions.pdf');
              _showSnackBar(context, "People data exported!");
            } catch (e) {
              _showSnackBar(context, "People data export failed: $e");
            }
          },
        ),
      ],
    );
  }

  Widget _buildDataManagementSection(BuildContext context, bool isDark) {
    return Column(
      children: [
        _buildSettingsTile(
          icon: Icons.ios_share,
          title: "Export People Data (JSON)",
          subtitle: "Backup people and transactions",
          onTap: () async {
            HapticFeedback.lightImpact();
            try {
              await PersonBackupHelper.exportToJsonAndShare();
              _showSnackBar(context, "People data exported!");
            } catch (e) {
              _showSnackBar(context, "People data export failed: $e");
            }
          },
        ),
        _buildSettingsTile(
          icon: Icons.import_export,
          title: "Import People Data (JSON)",
          subtitle: "Restore people data from backup",
          onTap: () async {
            HapticFeedback.lightImpact();
            try {
              await PersonBackupHelper.importFromJson(context);
              _showSnackBar(context, "People data imported successfully!");
            } catch (e) {
              _showSnackBar(context, "People data import failed: $e");
            }
          },
        ),
        _buildSettingsTile(
          icon: Icons.delete_forever,
          title: "Delete All Data",
          subtitle: "⚠️ This action cannot be undone",
          isDestructive: true,
          onTap: () {
            HapticFeedback.lightImpact();
            _confirmDeleteAll(context);
          },
        ),
        _buildSettingsTile(
          icon: Icons.refresh,
          title: "Reset Intro",
          subtitle: "Show intro screens again",
          onTap: () {
            HapticFeedback.lightImpact();
            _confirmResetIntro(context);
          },
        ),

      ],
    );
  }

  Widget _buildAppInfoSection(BuildContext context, bool isDark) {
    return Column(
      children: [
        _buildSettingsTile(
          icon: Icons.info_outline,
          title: "Version",
          subtitle: "5.7.6",
          onTap: null,
        ),
        _buildSettingsTile(
          icon: Icons.description,
          title: "Privacy Policy",
          subtitle: "Read our privacy policy",
          onTap: () {
            HapticFeedback.lightImpact();
            _showSnackBar(context, "Privacy policy coming soon!");
          },
        ),
        _buildSettingsTile(
          icon: Icons.help_outline,
          title: "Help & Support",
          subtitle: "Get help and contact support",
          onTap: () {
            HapticFeedback.lightImpact();
            _showSnackBar(context, "Help section coming soon!");
          },
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final isDark = context.watch<AppThemeProvider>().isDarkMode;
    return ZoomTapAnimation(
      onTap: onTap,
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDestructive 
                  ? Colors.red.withOpacity(0.1)
                  : Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDestructive 
                    ? Colors.red.withOpacity(0.3)
                    : Colors.teal.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.teal,
              size: 18,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isDestructive ? Colors.red : null,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          trailing: onTap != null 
              ? Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context) {
    final isDark = Provider.of<AppThemeProvider>(context, listen: false).isDarkMode;
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(
              "Confirm Delete",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete all transactions and reset your balance? This action cannot be undone.",
          style: GoogleFonts.nunito(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              "Cancel",
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text("Delete All"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              HapticFeedback.lightImpact();
              try {
                final box = await Hive.openBox<double>('balanceBox');
                await box.clear();
                await Provider.of<TransactionProvider>(context, listen: false)
                    .deleteAllData();
                await Provider.of<PersonProvider>(context, listen: false)
                    .deleteAllData();
                await Provider.of<PersonTransactionProvider>(context, listen: false)
                    .deleteAllData();
                Navigator.pop(context);
                _showSnackBar(context, "All data deleted successfully!");
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar(context, "Failed to delete all data. Please try again.");
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmResetIntro(BuildContext context) async {
    final isDark = Provider.of<AppThemeProvider>(context, listen: false).isDarkMode;
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            Text(
              "Reset Intro",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          "This will show the intro screens again the next time you open the app. Your data will remain unchanged.",
          style: GoogleFonts.nunito(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              "Cancel",
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("Reset"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              HapticFeedback.lightImpact();
              try {
                final box = await Hive.openBox<double>('balanceBox');
                await box.clear();
                // Reset introCompleted flag in settings box
                final settingsBox = await Hive.openBox('settings');
                await settingsBox.put('introCompleted', false);
                Navigator.pop(context);
                _showSnackBar(context, "Intro reset successfully!");
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar(context, "Failed to reset intro. Please try again.\n$e");
              }
            },
          ),
        ],
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}
