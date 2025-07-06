import 'dart:ui';

import 'package:aspends_tracker/screens/people_page.dart';
import 'package:aspends_tracker/providers/person_provider.dart';
import 'package:aspends_tracker/providers/person_transaction_provider.dart';
import 'package:flutter/material.dart';
//import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart'; // Add this import
//import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import 'models/person.dart';
import 'models/person_transaction.dart';
import 'models/theme.dart';
import 'screens/settings_page.dart';
import 'screens/home_page.dart';
import 'screens/chart_page.dart';
import 'models/transaction.dart';
import 'providers/transaction_provider.dart';
import 'providers/theme_provider.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

// Background callback for home widget
@pragma('vm:entry-point')
void backgroundCallback(Uri? uri) {
  if (uri?.host == 'addTransaction') {
    // Handle widget click - this will be processed when app opens
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(AppThemeAdapter());
  Hive.registerAdapter(PersonAdapter());
  Hive.registerAdapter(PersonTransactionAdapter());

  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<double>('balanceBox');
  await Hive.openBox('settings');
  await Hive.openBox<Person>('people');
  await Hive.openBox<PersonTransaction>('personTransactions');

  await FlutterDisplayMode.setHighRefreshRate();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppThemeProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => PersonTransactionProvider()),
        ChangeNotifierProvider(create: (_) => PersonProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final themeProvider = context.watch<AppThemeProvider>();

        // Enhanced color schemes with better contrast and accessibility
        final lightScheme = lightDynamic ?? ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        );
        final darkScheme = darkDynamic ?? ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        );

        ThemeData lightTheme = ThemeData(
          colorScheme: lightScheme,
          useMaterial3: true,
          fontFamily: 'NFont',
          textTheme: GoogleFonts.nunitoTextTheme(lightScheme.brightness == Brightness.dark
              ? ThemeData.dark().textTheme
              : ThemeData.light().textTheme),
          // Enhanced card theme
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: lightScheme.surface,
          ),
          // Enhanced input decoration theme
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: lightScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: lightScheme.outline.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: lightScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: lightScheme.surface,
          ),
          // Enhanced elevated button theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        );

        ThemeData darkTheme = ThemeData(
          colorScheme: darkScheme,
          useMaterial3: true,
          fontFamily: 'NFont',
          textTheme: GoogleFonts.nunitoTextTheme(darkScheme.brightness == Brightness.dark
              ? ThemeData.dark().textTheme
              : ThemeData.light().textTheme),
          // Enhanced card theme for dark mode
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: darkScheme.surface,
          ),
          // Enhanced input decoration theme for dark mode
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: darkScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: darkScheme.outline.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: darkScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: darkScheme.surface,
          ),
          // Enhanced elevated button theme for dark mode
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Aspends Tracker',
          themeMode: themeProvider.themeMode,
          theme: lightTheme,
          darkTheme: darkTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1500)
    );
    
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut)
    );
    
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut)
    );
    
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)
    );
    
    _controller.forward();

    HomeWidget.initiallyLaunchedFromHomeWidget().then((Uri? uri) {
      if (uri != null && uri.host == 'addTransaction') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      } else {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RootNavigation()),
          );
        });
      }
    });
    
    // Set up home widget click handler
    HomeWidget.setAppGroupId('your_app_group_id');
    HomeWidget.registerBackgroundCallback(backgroundCallback);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade400,
              Colors.teal.shade700,
              Colors.teal.shade900,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Icon/Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // App Name
                    Text(
                      'Aspends Tracker',
                      style: GoogleFonts.nunito(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tagline
                    Text(
                      'Smart Money Management',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class RootNavigation extends StatefulWidget {
  const RootNavigation({super.key});

  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _screens = [
    HomePage(),
    PeopleTab(),
    ChartPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
    HapticFeedback.selectionClick();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // HapticFeedback.lightImpact();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
       // Use jumpToPage for instant switch
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    //final isDark = context.watch<AppThemeProvider>().isDarkMode;
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          fit: StackFit.loose,
          children: [
            PageView(
              controller: _pageController,
              children: _screens,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(), // disable swipe if desired
            ),
            Positioned(
              bottom: 18,
              left: 18,
              right: 18,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: theme.scaffoldBackgroundColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaY: 8, sigmaX: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor.withOpacity(0.1),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /// Bottom Navigation bar items
            Positioned(
              bottom: 18,
              left: 22,
              right: 22,
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: [
                  _buildBNBItem(Icons.home_outlined, 0,"Home"),
                  _buildBNBItem(Icons.person, 1,"Person"),
                  _buildBNBItem(Icons.auto_graph, 2,"Chart"),
                  _buildBNBItem(Icons.settings_outlined, 3,"Setting"),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }
  Widget _buildBNBItem(IconData icon, index, label) {
    final isSelected = _selectedIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: ZoomTapAnimation(
        onTap: () {
          setState(() {
            _onItemTapped(index);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1.5), // Reduced vertical padding
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12), // Smaller radius for half height
            color: isSelected ? Colors.teal.withOpacity(0.18) : Colors.transparent,
            border: isSelected ? Border.all(
              color: Colors.teal.withOpacity(0.5),
              width: 1,
            ) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey(isSelected),
                  color: isSelected ? Colors.teal.shade700 : Colors.grey.shade600,
                  size: isSelected ? 20 : 18, // Slightly smaller icons
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: Colors.teal.shade700,
                    fontSize: 10, // Smaller font
                    fontWeight: FontWeight.w600,
                  ),
                  child: Text(label),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// class RootNavigation extends StatefulWidget {
//   const RootNavigation({super.key});
//
//   @override
//   State<RootNavigation> createState() => _RootNavigationState();
// }
//
// class _RootNavigationState extends State<RootNavigation> {
//   int _selectedIndex = 0;
//   late PageController _pageController;
//
//   final List<Widget> _screens = [
//     HomePage(),
//     PeopleTab(),
//     ChartPage(),
//     SettingsPage(),
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController(initialPage: _selectedIndex);
//   }
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }
//
//   void _onPageChanged(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//     HapticFeedback.selectionClick();
//   }
//
//   void _onItemTapped(int index) {
//     HapticFeedback.lightImpact();
//     _pageController.animateToPage(
//       index,
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: PageView(
//         controller: _pageController,
//         children: _screens,
//         onPageChanged: _onPageChanged,
//         physics:  CarouselScrollPhysics(),
//       ),
//       bottomNavigationBar: NavigationBar(
//         selectedIndex: _selectedIndex,
//         onDestinationSelected: _onItemTapped,
//         destinations: const [
//           NavigationDestination(
//             icon: Icon(Icons.home_outlined),
//             selectedIcon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.groups_outlined),
//             selectedIcon: Icon(Icons.groups),
//             label: 'People',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.pie_chart_outline),
//             selectedIcon: Icon(Icons.pie_chart),
//             label: 'Charts',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.settings_outlined),
//             selectedIcon: Icon(Icons.settings),
//             label: 'Settings',
//           ),
//         ],
//       ),
//     );
//   }
// }
// class RootNavigation extends StatefulWidget {
//   const RootNavigation({super.key});
//
//   @override
//   State<RootNavigation> createState() => _RootNavigationState();
// }
//
// class _RootNavigationState extends State<RootNavigation> {
//   int _selectedIndex = 0;
//   late PageController _pageController;
//
//   final List<Widget> _screens = [
//     HomePage(),
//     ChartPage(),
//     PeopleTab(),
//     SettingsPage(),
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController(initialPage: _selectedIndex);
//   }
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }
//
//   void _onPageChanged(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   void _onItemTapped(int index) {
//     _pageController.jumpToPage(index);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: **PageView(
//       controller: _pageController,
//       onPageChanged: _onPageChanged,
//       children: _screens,
//       physics: const NeverScrollableScrollPhysics(), // Optional
//     )**,
//     bottomNavigationBar: NavigationBar(
//     selectedIndex: _selectedIndex,
//     onDestinationSelected: _onItemTapped,
//     destinations: const [
//     NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
//     NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Charts'),
//     NavigationDestination(icon: Icon(Icons.groups), label: 'People'),
//     NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
//     ],
//     ),
//     );
//   }
// }
// import 'dart:ui';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter/material.dart';
// import 'package:flex_color_scheme/flex_color_scheme.dart';

//
// Created by CodeWithFlexZ
// Tutorials on my YouTube
//
//! Instagram
//! @CodeWithFlexZ
//
//? GitHub
//? AmirBayat0
//
//* YouTube
//* Programming with FlexZ
//




