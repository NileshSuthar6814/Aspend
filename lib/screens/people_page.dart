import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/person_provider.dart';
import '../person/person_details_page.dart';
import '../providers/theme_provider.dart';

class PeopleTab extends StatefulWidget {
  const PeopleTab({super.key});

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  late ScrollController _scrollController;
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      final direction = _scrollController.position.userScrollDirection;
      if (direction == ScrollDirection.reverse && _showFab) {
        setState(() => _showFab = false);
      } else if (direction == ScrollDirection.forward && !_showFab) {
        setState(() => _showFab = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            child: const Text('Cancel'),
          ),
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
        ),
      )
          : ListView.builder(
        controller: _scrollController,
        itemCount: people.length,
        itemBuilder: (_, idx) {
          final person = people[idx];
          final total = personProvider.totalFor(person.name);
          final isPositive = total >= 0;

          return Card(
            color: isDark ? Colors.teal[900] : Colors.teal[50],
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 4,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              title: Text(
                person.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text("Tap to view transactions"),
              trailing: Text(
                '₹${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
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
      floatingActionButton: _showFab
          ?Column(
            mainAxisAlignment:MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              _showAddPersonDialog(context);
              HapticFeedback.lightImpact();
            },
            child: const Icon(Icons.person_add),
          ),
          SizedBox(
            height: 50,
          )
        ],
      )
          : null,
    );
  }
}
