import 'package:flutter/material.dart';
import 'package:aspends_tracker/providers/theme_provider.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../backup/export_csv.dart';
import '../backup/import_csv.dart';
import '../models/theme.dart';
import '../providers/transaction_provider.dart';

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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DropdownButton<AppTheme>(
            value: context.watch<AppThemeProvider>().appTheme,
            onChanged: (theme) {
              if (theme != null) {
                context.read<AppThemeProvider>().setTheme(theme);
              }
            },
            dropdownColor: Theme.of(context).cardColor, // Adjusts dropdown background
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge!.color, // Text color adapts
              fontWeight: FontWeight.w500,
            ),
            iconEnabledColor: Theme.of(context).iconTheme.color, // Dropdown arrow color
            items: AppTheme.values.map((theme) {
              final label = theme.toString().split('.').last;
              return DropdownMenuItem(
                value: theme,
                child: Text(
                  label[0].toUpperCase() + label.substring(1), // Capitalize
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const ListTile(
          title: Text("Version"),
          subtitle: Text("3.0.5"),
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
        title: Text("Confirm Delete",style: TextStyle(color:isDark ? Colors.white : Colors.black),),
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
