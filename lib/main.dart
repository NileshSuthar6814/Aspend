import 'dart:ui';

import 'package:aspends_tracker/screens/people_page.dart';
import 'package:aspends_tracker/providers/person_provider.dart';
import 'package:aspends_tracker/providers/person_transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart'; // Add this import
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
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

        // Fallback colors if dynamic not supported
        final lightScheme = lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.teal);
        final darkScheme = darkDynamic ?? ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark);

        ThemeData lightTheme = ThemeData(
          colorScheme: lightScheme,
          useMaterial3: true,
          fontFamily: 'NFont',
          textTheme: GoogleFonts.nunitoTextTheme(lightScheme.brightness == Brightness.dark
              ? ThemeData.dark().textTheme
              : ThemeData.light().textTheme),
        );

        ThemeData darkTheme = ThemeData(
          colorScheme: darkScheme,
          useMaterial3: true,
          fontFamily: 'NFont',
          textTheme: GoogleFonts.nunitoTextTheme(darkScheme.brightness == Brightness.dark
              ? ThemeData.dark().textTheme
              : ThemeData.light().textTheme),
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

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fade = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();

    HomeWidget.initiallyLaunchedFromHomeWidget().then((Uri? uri) {
      if (uri != null && uri.host == 'addTransaction') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) =>  HomePage()),
        );
      } else {
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RootNavigation()),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Text(
            'Aspends Tracker',
            style: GoogleFonts.nunito(
              fontSize: 36,
              color: Colors.white,
              fontWeight: FontWeight.bold,
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

class _RootNavigationState extends State<RootNavigation> {
  int _selectedIndex = 0;
  late PageController _pageController;

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
  }

  @override
  void dispose() {
    _pageController.dispose();
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
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
       // Use jumpToPage for instant switch
  }


  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final isDark = context.watch<AppThemeProvider>().isDarkMode;
    return Scaffold(
      body:Stack(
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
                border:
                Border.all(width: 1, color: theme.scaffoldBackgroundColor),
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(35),
                    topLeft: Radius.circular(35),
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40)),
               //color: isDark?Colors.black.withOpacity(1):Colors.white.withOpacity(1),
              ),
              child: ClipRRect(
            
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(35),
                    topLeft: Radius.circular(35),
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40)),
                child: ClipPath(
                  clipper: MyCustomClipper(),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaY: 8, sigmaX: 8),
                    child: Container(),
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
      )
    );
  }
  Widget _buildBNBItem(IconData icon, index,label) {
    return ZoomTapAnimation(
      
      onTap: () {
        setState(() {
          _onItemTapped(index);
        });
      },
      child: Row(
        children: [
          Icon(
            icon,
            color: _selectedIndex == index ? Colors.teal.shade800 : Colors.black54,
            size: _selectedIndex == index?35:25,
          
          ),
          Text(_selectedIndex == index?label:"")
        ],
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

          /// Custom Bottom Navigation Bar



class MyCustomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(64, size.width);
    //path.lineTo(64, size.height);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}

