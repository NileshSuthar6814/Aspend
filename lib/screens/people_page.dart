import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/person_provider.dart';
import '../person/person_details_page.dart';
import '../providers/theme_provider.dart';

class PeopleTab extends StatelessWidget {
  const PeopleTab({super.key});

  @override
  Widget build(BuildContext context) {
    final personProvider = context.watch<PersonProvider>();
    final people = personProvider.people;
    final isDark = context.watch<AppThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        backgroundColor: isDark ? Colors.teal[900] : Colors.teal[100],
      ),
      body: people.isEmpty
          ? const Center(
              child: Text(
              "No people added yet",
              style: TextStyle(fontWeight: FontWeight.bold),
            ))
          : ListView.builder(
              itemCount: people.length,
              itemBuilder: (_, idx) {
                final person = people[idx];
                final total = personProvider.totalFor(person.name);
                final isPositive = total >= 0;

                return Card(
                  //dynamic color
                  color: isDark ? Colors.teal[900] : Colors.teal[50],
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    title: Text(
                      person.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      'Total: ₹${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: const Text("Tap to view transactions"),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PersonDetailPage(person: person),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.person_add),
          onPressed: () {
            _showAddPersonDialog(context);
            HapticFeedback.lightImpact();
          }),
    );
  }

  void _showAddPersonDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Person'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<PersonProvider>().addPerson(name);
                Navigator.pop(context);
                HapticFeedback.lightImpact();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
