import 'package:aspends_tracker/screens/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:aspends_tracker/providers/theme_provider.dart';
import 'package:flutter/services.dart';
//import 'package:hive/hive.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../backup/export_csv.dart';
import '../backup/import_csv.dart';
import '../backup/person_backup_helper.dart';
//import '../models/person.dart';
//import '../models/person_transaction.dart';
import '../models/theme.dart';
import '../providers/person_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/pdf_service.dart';

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
                "Settings",
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
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.teal.shade600,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCard(BuildContext context, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.palette, size: 24, color: Colors.teal.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Theme",
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Choose your preferred theme",
                        style: GoogleFonts.nunito(
                          fontSize: 12,
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

  Widget _buildBackupSection(BuildContext context, bool isDark) {
    return Column(
      children: [
        _buildSettingsTile(
          icon: Icons.upload_file,
          title: "Export Transactions",
          subtitle: "Backup your data to CSV",
          onTap: () {
            DataExporter.shareBackupFile();
            HapticFeedback.lightImpact();
            _showSnackBar(context, "Export completed successfully!");
          },
        ),
        _buildSettingsTile(
          icon: Icons.download,
          title: "Import Transactions",
          subtitle: "Restore data from backup",
          onTap: () async {
            HapticFeedback.lightImpact();
            await DataImporter.importFromJson();
            Provider.of<TransactionProvider>(context, listen: false)
                .loadTransactions();
            _showSnackBar(context, "Import completed successfully!");
          },
        ),
        _buildSettingsTile(
          icon: Icons.picture_as_pdf,
          title: "Export as PDF",
          subtitle: "Generate PDF reports",
          onTap: () async {
            final file = await PDFService.generateHomeTransactionPDF();
            await Printing.sharePdf(
                bytes: await file.readAsBytes(),
                filename: 'home_transactions.pdf');
            _showSnackBar(context, "PDF exported successfully!");
          },
        ),
        _buildSettingsTile(
          icon: Icons.groups,
          title: "Export People Data",
          subtitle: "Backup people transactions",
          onTap: () async {
            HapticFeedback.lightImpact();
            final file = await PDFService.generatePeopleTransactionPDF();
            await Printing.sharePdf(
                bytes: await file.readAsBytes(),
                filename: 'person_transactions.pdf');
            _showSnackBar(context, "People data exported!");
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
            await PersonBackupHelper.exportToJsonAndShare();
            _showSnackBar(context, "People data exported!");
          },
        ),
        _buildSettingsTile(
          icon: Icons.import_export,
          title: "Import People Data (JSON)",
          subtitle: "Restore people data from backup",
          onTap: () async {
            HapticFeedback.lightImpact();
            await PersonBackupHelper.importFromJson();
            _showSnackBar(context, "People data imported successfully!");
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
      ],
    );
  }

  Widget _buildAppInfoSection(BuildContext context, bool isDark) {
    return Column(
      children: [
        _buildSettingsTile(
          icon: Icons.info_outline,
          title: "Version",
          subtitle: "4.1.0",
          onTap: null,
        ),
        _buildSettingsTile(
          icon: Icons.description,
          title: "Privacy Policy",
          subtitle: "Read our privacy policy",
          onTap: () {
            // TODO: Implement privacy policy
            _showSnackBar(context, "Privacy policy coming soon!");
          },
        ),
        _buildSettingsTile(
          icon: Icons.help_outline,
          title: "Help & Support",
          subtitle: "Get help and contact support",
          onTap: () {
            // TODO: Implement help section
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
    
    return Card(
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
            fontSize: 14,
            color: isDestructive ? Colors.red : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.nunito(
            fontSize: 11,
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
    final isDark = context.watch<AppThemeProvider>().isDarkMode;
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
              Navigator.pop(context);
              HapticFeedback.lightImpact();
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
              await Provider.of<TransactionProvider>(context, listen: false)
                  .deleteAllData();
              await Provider.of<PersonProvider>(context, listen: false)
                  .deleteAllPeopleAndTransactions();
              Navigator.pop(context);
              _showSnackBar(context, "All data deleted successfully!");
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
