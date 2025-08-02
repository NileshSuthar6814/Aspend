import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../main.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/transaction_detection_service.dart';
import '../services/native_bridge.dart';
import '../utils/responsive_utils.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentPage = 0;
  String _selectedTheme = 'Default';

  final List<IntroSlide> _slides = [
    IntroSlide(
      title: "Welcome to Aspends Tracker",
      subtitle: "Your personal finance companion",
      description:
          "Track your income, expenses, and manage your money with ease. Stay on top of your financial goals.",
      icon: Icons.account_balance_wallet,
      color: Colors.teal,
    ),
    IntroSlide(
      title: "Smart Transaction Tracking",
      subtitle: "Organize your finances",
      description:
          "Categorize transactions, add notes, and get detailed insights into your spending patterns.",
      icon: Icons.analytics,
      color: Colors.blue,
    ),
    IntroSlide(
      title: "Person-to-Person Tracking",
      subtitle: "Manage shared expenses",
      description:
          "Track money you owe or are owed by others. Perfect for roommates, friends, and family.",
      icon: Icons.people,
      color: Colors.green,
    ),
    IntroSlide(
      title: "Beautiful Analytics",
      subtitle: "Visualize your data",
      description:
          "Charts and graphs help you understand your spending habits and financial trends.",
      icon: Icons.pie_chart,
      color: Colors.orange,
    ),
    IntroSlide(
      title: "Fully Offline",
      subtitle: "Your data stays private",
      description:
          "All your financial data is stored locally on your device. No internet required, complete privacy.",
      icon: Icons.security,
      color: Colors.purple,
    ),
    IntroSlide(
      title: "Auto Transaction Detection",
      subtitle: "Smart & Automated",
      description:
          "Automatically detect transactions from banking notifications. No more manual entry - your transactions are captured instantly!",
      icon: Icons.auto_awesome,
      color: Colors.amber,
    ),
    IntroSlide(
      title: "Ready to Start?",
      subtitle: "Let's begin your journey",
      description:
          "You're all set! Start tracking your finances and take control of your money today.",
      icon: Icons.rocket_launch,
      color: Colors.indigo,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentPage = page;
    });
  }

  void _completeIntro() async {
    HapticFeedback.lightImpact();
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Setting up your app...',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      // Use Hive to mark intro as completed
      final box = await Hive.openBox('settings');
      await box.put('introCompleted', true);
      await box.put('introCompletedAt', DateTime.now().millisecondsSinceEpoch);

      // Show auto-detection setup dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        await _showAutoDetectionSetup(context);
      }

      // Navigation will be handled by _showAutoDetectionSetup or _navigateToMainApp
    } catch (e) {
      // Close loading dialog if there's an error
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Error',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Failed to complete setup. Please try again.',
                style: GoogleFonts.nunito(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _completeIntro(); // Retry
                  },
                  child: Text(
                    'Retry',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> _showAutoDetectionSetup(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = context.watch<AppThemeProvider>().isDarkMode;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            Text(
              "Enable Auto Detection?",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Would you like to enable automatic transaction detection?",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem("🔔 Monitor notifications",
                "Detects banking transactions automatically"),
            _buildFeatureItem("💰 Smart categorization",
                "Categorizes transactions based on bank keywords"),
            _buildFeatureItem("⚡ Real-time detection",
                "Captures transactions as they happen"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Text(
                "💡 You can enable this later in Settings if you skip now.",
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: Colors.amber.shade700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              "Skip for now",
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              _navigateToMainApp();
            },
          ),
          ElevatedButton(
            child: const Text("Enable"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              HapticFeedback.lightImpact();
              try {
                // Request permissions
                await NativeBridge.requestNotificationPermission();
                await NativeBridge.requestBatteryOptimization();

                // Enable auto-detection
                await TransactionDetectionService.setEnabled(true);

                Navigator.pop(context);
                _navigateToMainApp();
              } catch (e) {
                // If there's an error, still proceed to main app
                Navigator.pop(context);
                _navigateToMainApp();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
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
    );
  }

  void _navigateToMainApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RootNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final useAdaptive = context.watch<AppThemeProvider>().useAdaptiveColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 50, right: 20),
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _completeIntro();
                  },
                  child: Text(
                    'Skip',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _buildSlide(slide, theme, isDark);
                },
              ),
            ),

            // Page indicator and buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Page indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _slides[index].color
                              : theme.colorScheme.outline.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      if (_currentPage > 0)
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Text(
                            'Back',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 80),

                      // Next/Get Started button
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          if (_currentPage < _slides.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _completeIntro();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _slides[_currentPage].color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          _currentPage < _slides.length - 1
                              ? 'Next'
                              : 'Get Started',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(IntroSlide slide, ThemeData theme, bool isDark) {
    final useAdaptive = context.watch<AppThemeProvider>().useAdaptiveColor;
    final primary = theme.colorScheme.primary;
    final primaryContainer = theme.colorScheme.primaryContainer;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with glass effect
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: useAdaptive
                  ? primary.withOpacity(0.1)
                  : slide.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: useAdaptive
                    ? primary.withOpacity(0.3)
                    : slide.color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(58),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: useAdaptive
                        ? primary.withOpacity(0.1)
                        : slide.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(58),
                  ),
                  child: Icon(
                    slide.icon,
                    size: 60,
                    color: useAdaptive ? primary : slide.color,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            slide.title,
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            slide.subtitle,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: slide.color,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            slide.description,
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class IntroSlide {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  IntroSlide({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}
