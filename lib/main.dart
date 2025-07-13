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
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart'; // Add this import
//import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import 'models/person.dart';
import 'models/person_transaction.dart';
import 'models/theme.dart';
import 'screens/settings_page.dart';
import 'screens/home_page.dart';
import 'screens/chart_page.dart';
import 'screens/intro_page.dart';
import 'models/transaction.dart';
import 'providers/transaction_provider.dart';
import 'providers/theme_provider.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';
//import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

// 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(AppThemeAdapter());
  Hive.registerAdapter(PersonAdapter());
  Hive.registerAdapter(PersonTransactionAdapter());

  // Ensure all Hive boxes are opened before running the app
  try {
    await Future.wait([
      if (!Hive.isBoxOpen('transactions')) Hive.openBox<Transaction>('transactions'),
      if (!Hive.isBoxOpen('balanceBox')) Hive.openBox<double>('balanceBox'),
      if (!Hive.isBoxOpen('settings')) Hive.openBox('settings'),
      if (!Hive.isBoxOpen('people')) Hive.openBox<Person>('people'),
      if (!Hive.isBoxOpen('personTransactions')) Hive.openBox<PersonTransaction>('personTransactions'),
    ]);
    
    print('All Hive boxes initialized successfully');
  } catch (e) {
    print('Error initializing Hive boxes: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Failed to initialize local storage: \n\n$e',
            style: TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ));
    return;
  }

  await FlutterDisplayMode.setHighRefreshRate();

  // Register background callback for widget events
  HomeWidget.registerBackgroundCallback(backgroundCallback);

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

// Background callback for widget events (required by home_widget)
void backgroundCallback(Uri? uri) async {
  if (uri != null && uri.host == 'addTransaction') {
    // You can handle background widget actions here if needed
    // For example, schedule a notification or update data
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen for widget click actions while app is running
    HomeWidget.widgetClicked.listen((Uri? uri) {
      if (uri != null && uri.host == 'addTransaction') {
        // You can use a navigator key or other logic to open the add transaction screen
        // For now, just print for debug
        print('Widget action: addTransaction');
      }
    });
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final themeProvider = context.watch<AppThemeProvider>();

        final useAdaptive = themeProvider.useAdaptiveColor;
        final lightSchemeFinal = useAdaptive ? (lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light)) : ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light);
        final darkSchemeFinal = useAdaptive ? (darkDynamic ?? ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark)) : ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark);

        ThemeData lightTheme = ThemeData(
          colorScheme: lightSchemeFinal,
          useMaterial3: true,
          fontFamily: 'NFont',
          textTheme: GoogleFonts.nunitoTextTheme(lightSchemeFinal.brightness == Brightness.dark
              ? ThemeData.dark().textTheme
              : ThemeData.light().textTheme),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: lightSchemeFinal.surface,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: lightSchemeFinal.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: lightSchemeFinal.outline.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: lightSchemeFinal.primary, width: 2),
            ),
            filled: true,
            fillColor: lightSchemeFinal.surface,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        );

        ThemeData darkTheme = ThemeData(
          colorScheme: darkSchemeFinal,
          useMaterial3: true,
          fontFamily: 'NFont',
          textTheme: GoogleFonts.nunitoTextTheme(darkSchemeFinal.brightness == Brightness.dark
              ? ThemeData.dark().textTheme
              : ThemeData.light().textTheme),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: darkSchemeFinal.surface,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: darkSchemeFinal.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: darkSchemeFinal.outline.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: darkSchemeFinal.primary, width: 2),
            ),
            filled: true,
            fillColor: darkSchemeFinal.surface,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        );

        return MaterialApp(
          scrollBehavior: MaterialScrollBehavior(),
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
    print('SplashScreen: initState start');
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    print('SplashScreen: Animation started');
    HomeWidget.initiallyLaunchedFromHomeWidget().then((Uri? uri) async {
      print('SplashScreen: HomeWidget callback');
      if (uri != null && uri.host == 'addTransaction') {
        print('SplashScreen: Launched from widget');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      } else {
        print('SplashScreen: Not launched from widget, checking intro');
        final box = await Hive.openBox('settings');
        final introCompleted = box.get('introCompleted', defaultValue: false);
        print('SplashScreen: introCompleted = '
            + introCompleted.toString());
        Future.delayed(const Duration(seconds: 2), () {
          print('SplashScreen: Navigating to next screen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => introCompleted
                  ? const RootNavigation()
                  : const IntroPage(),
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final useAdaptive = Provider.of<AppThemeProvider>(context).useAdaptiveColor;
    return Scaffold(
      backgroundColor: useAdaptive ? theme.colorScheme.primary : Colors.teal,
      body: Container(
        decoration: BoxDecoration(
          gradient: useAdaptive
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer, theme.colorScheme.secondary],
              )
            : LinearGradient(
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
                        color: Colors.white.withOpacity(0.1),
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
                      child:LoadingAnimationWidget.halfTriangleDot(
                        color: Colors.white.withOpacity(0.8),
                        size: 40,

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
    if (_selectedIndex != index) {
    setState(() {
      _selectedIndex = index;
    });
    HapticFeedback.selectionClick();
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
    setState(() {
      _selectedIndex = index;
    });
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final isDark = context.watch<AppThemeProvider>().isDarkMode;
    final List<Widget> _screens = [
      HomePage(),
      PeopleTab(),
      ChartPage(),
      SettingsPage(),
    ];
    return Scaffold(
      body:
      FadeTransition(
        opacity: _fadeAnimation,
       child:
      Stack(
          //fit: StackFit.passthrough,
          children: [
            PageView(
              controller: _pageController,
              children: _screens,
              onPageChanged: _onPageChanged,
               // disable swipe if desired
              physics: BouncingScrollPhysics(),
              scrollBehavior: MaterialScrollBehavior(),
            ),
            Positioned(
              bottom: 18,
              left: 18,
              right: 18,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
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
    final theme = Theme.of(context);
    final isDark = context.watch<AppThemeProvider>().isDarkMode;
    return AnimatedContainer(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: isSelected ? 10 : 15),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: ZoomTapAnimation(
        onTap: () => _onItemTapped(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isSelected ? theme.colorScheme.primary.withOpacity(0.2) : Colors.transparent,
            border: isSelected ? Border.all(
              color: theme.colorScheme.primary,
              width: 0.5,
            ) : null,
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.teal.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 5),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey(isSelected),
                  color: isSelected ? isDark ? Colors.white: Colors.black : Colors.grey.shade600,
                  size: isSelected ? 22 : 20,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color:isSelected ?isDark ? Colors.white: Colors.black : Colors.grey.shade600,
                    fontSize: 12,
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




