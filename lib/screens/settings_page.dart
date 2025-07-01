import 'package:flutter/material.dart';
import 'package:aspends_tracker/providers/theme_provider.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../backup/export_csv.dart';
import '../backup/import_csv.dart';
import '../backup/person_backup_helper.dart';
import '../models/theme.dart';
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
    return ListView(
      children: [
        ListTile(
            title: const Text("Export Transactions (Backup)"),
            leading: const Icon(Icons.upload_file),
            onTap: () {
              DataExporter.shareBackupFile();
              HapticFeedback.lightImpact();
            }),
        ListTile(
          title: const Text("Import Transactions"),
          leading: const Icon(Icons.download),
          onTap: () async {
            HapticFeedback.lightImpact();
            await DataImporter.importFromJson();
            Provider.of<TransactionProvider>(context, listen: false)
                .loadTransactions();
          },
        ),
        ListTile(
          leading: Icon(Icons.picture_as_pdf),
          title: Text("Export Home Transactions as PDF"),
          onTap: () async {
            final file = await PDFService.generateHomeTransactionPDF();
            await Printing.sharePdf(
                bytes: await file.readAsBytes(),
                filename: 'home_transactions.pdf');
          },
        ),
        ListTile(
          leading: Icon(Icons.groups),
          title: Text("Export People Transactions as PDF"),
          onTap: () async {
            HapticFeedback.lightImpact();
            final file = await PDFService.generatePeopleTransactionPDF();
            await Printing.sharePdf(
                bytes: await file.readAsBytes(),
                filename: 'person_transactions.pdf');
          },
        ),
        ListTile(
            leading: Icon(Icons.ios_share),
            title: Text("Export People Data (JSON)"),
            onTap: () async {
              HapticFeedback.lightImpact();
              await PersonBackupHelper.exportToJsonAndShare();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Exported')),
              );
            }),
        ListTile(
          onTap: () async {
            HapticFeedback.lightImpact();
            await PersonBackupHelper.importFromJson();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Import completed')),
            );
          },
          title: const Text('Import People Data (JSON)'),
          leading: Icon(Icons.import_export),
        ),
        Container(
          //padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.palette, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Theme",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<AppTheme>(
                              value: context.watch<AppThemeProvider>().appTheme,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down),
                              onChanged: (theme) {
                                HapticFeedback.lightImpact();
                                if (theme != null) {
                                  context
                                      .read<AppThemeProvider>()
                                      .setTheme(theme);
                                }
                              },
                              items: AppTheme.values.map((theme) {
                                final label = theme
                                    .toString()
                                    .split('.')
                                    .last
                                    .capitalize();
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
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const ListTile(
          title: Text("Version"),
          subtitle: Text("4.0.5"),
        ),
        ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              "Delete All Data",
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text("Erase all transactions and reset balance"),
            onTap: () {
              HapticFeedback.lightImpact();
              _confirmDeleteAll(context);
            }),
      ],
    );
  }

  void _confirmDeleteAll(BuildContext context) {
    final isDark = context.watch<AppThemeProvider>().isDarkMode;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Confirm Delete",
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          "Are you sure you want to delete all transactions and reset your balance?",
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        actions: [
          TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);

                HapticFeedback.lightImpact();
              }),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text("Delete All"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              HapticFeedback.lightImpact();
              await Provider.of<TransactionProvider>(context, listen: false)
                  .deleteAllData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All data deleted")),
              );
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
