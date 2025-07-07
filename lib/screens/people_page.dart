import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import 'dart:io';
import '../providers/person_provider.dart';
import '../person/person_details_page.dart';
import '../providers/theme_provider.dart';

class PeopleTab extends StatefulWidget {
  const PeopleTab({super.key});

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _showFab = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _fabVisibilityController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabOpacity;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

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

    // FAB visibility animation
    _fabVisibilityController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fabVisibilityController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final people = context.read<PersonProvider>().people;
      final isEmpty = people.isEmpty;
      if (isEmpty) {
        if (!_showFab) setState(() => _showFab = true);
      } else {
        final atTop = _scrollController.position.pixels <= 0;
        if (atTop) {
          if (!_showFab) setState(() => _showFab = true);
        } else {
          if (_showFab) setState(() => _showFab = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _fabVisibilityController.dispose();
    super.dispose();
  }

  void _showAddPersonDialog(BuildContext context) {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    String? selectedPhotoPath;
    
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Add New Person',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                              // Photo Selection
                GestureDetector(
                  onTap: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 300,
                      maxHeight: 300,
                      imageQuality: 80,
                    );
                    
                    if (image != null) {
                      setState(() {
                        selectedPhotoPath = image.path;
                      });
                    }
                  },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: selectedPhotoPath != null 
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: selectedPhotoPath != null 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: selectedPhotoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(48),
                          child: Image.file(
                            File(selectedPhotoPath!),
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 30,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add Photo',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Enter the name of the person you want to track transactions with',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Person Name',
                  labelStyle: GoogleFonts.nunito(fontSize: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                ),
                style: GoogleFonts.nunito(fontSize: 16),
                autofocus: true,
              ),
            ],
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
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  context.read<PersonProvider>().addPerson(name, photoPath: selectedPhotoPath);
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Add Person',
                style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final personProvider = context.watch<PersonProvider>();
    final people = personProvider.people;
    final theme = Theme.of(context);
    final isDark = context.watch<AppThemeProvider>().isDarkMode;
    final useAdaptive = context.watch<AppThemeProvider>().useAdaptiveColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            elevation: 1,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'People',
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
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: useAdaptive
                          ? [theme.colorScheme.primary, theme.colorScheme.primaryContainer]
                          : isDark 
                            ? [Colors.teal.shade900.withOpacity(0.8), Colors.teal.shade700.withOpacity(0.8)]
                            : [Colors.teal.shade100.withOpacity(0.8), Colors.teal.shade200.withOpacity(0.8)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            centerTitle: true,
          ),
          SliverFillRemaining(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: people.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(60),
                              ),
                              child: Icon(
                                Icons.people_outline,
                                size: 60,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "No people added yet",
                              style: GoogleFonts.nunito(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Add people to track transactions with them",
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: people.length + 1, // +1 for bottom padding
                        itemBuilder: (_, idx) {
                          // Add bottom padding as last item
                          if (idx == people.length) {
                            return const SizedBox(height: 80);
                          }
                          
                          final person = people[idx];
                          final total = personProvider.totalFor(person.name);
                          final isPositive = total >= 0;

                          return AnimatedBuilder(
                            animation: _fadeController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - _fadeController.value)),
                                child: Opacity(
                                  opacity: _fadeController.value,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ZoomTapAnimation(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PersonDetailPage(person: person),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: useAdaptive
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
                                          padding: const EdgeInsets.all(20),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  gradient: person.photoPath != null
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
                                                                theme.colorScheme.primary,
                                                                theme.colorScheme.primary.withOpacity(0.8),
                                                              ],
                                                            ),
                                                  color: person.photoPath != null
                                                      ? Colors.transparent
                                                      : null,
                                                  borderRadius: BorderRadius.circular(30),
                                                  border: person.photoPath != null
                                                      ? Border.all(
                                                          color: theme.colorScheme.primary.withOpacity(0.3),
                                                          width: 2,
                                                        )
                                                      : null,
                                                ),
                                                child: person.photoPath != null
                                                    ? ClipRRect(
                                                        borderRadius: BorderRadius.circular(28),
                                                        child: Image.file(
                                                          File(person.photoPath!),
                                                          width: 56,
                                                          height: 56,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      )
                                                    : Icon(
                                                        Icons.person,
                                                        color: useAdaptive ? theme.colorScheme.onPrimaryContainer : Colors.white,
                                                        size: 30,
                                                      ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      person.name,
                                                      style: GoogleFonts.nunito(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                        color: theme.colorScheme.onSurface,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "Tap to view transactions",
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
                                                    '₹${total.toStringAsFixed(2)}',
                                                    style: GoogleFonts.nunito(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: isPositive ? Colors.green : Colors.red,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: isPositive 
                                                          ? Colors.green.withOpacity(0.1)
                                                          : Colors.red.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      isPositive ? 'Credit' : 'Debit',
                                                      style: GoogleFonts.nunito(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: isPositive ? Colors.green : Colors.red,
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
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: people.isEmpty
        ? _buildAddPersonFab(context)
        : (_showFab ? _buildAddPersonFab(context) : null),
    );
  }

  Widget _buildAddPersonFab(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 60),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: FloatingActionButton.extended(
              onPressed: () {
                _showAddPersonDialog(context);
                HapticFeedback.lightImpact();
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: const Icon(Icons.person_add, size: 24),
              label: Text(
                'Add Person',
                style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
