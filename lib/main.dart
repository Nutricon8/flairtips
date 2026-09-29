import 'package:flairtips/screens/forgot_password_screen.dart.dart';
import 'package:flairtips/screens/new_password_screen.dart';
import 'package:flairtips/screens/reset_code_screen.dart';
import 'package:flairtips/utils/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flairtips/screens/bottom_nav.dart';
import 'package:flairtips/screens/onboarding_screen.dart';
import 'package:flairtips/screens/sign_in_screen.dart';
import 'package:flairtips/screens/sign_up_screen.dart';
import 'package:flairtips/utils/colors.dart';
import 'package:flairtips/utils/theme_provider.dart'; 
import 'package:provider/provider.dart';

const String taskKey = "fetch_shared_prefs_task";
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool isServiceRunning = false; // Flag to track if the service is running

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final userProvider = UserProvider();
  await userProvider.loadUser();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => userProvider),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const MyApp({super.key});
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flair Tips',
      themeMode:
          Provider.of<ThemeProvider>(context).isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
      navigatorKey: MyApp.navigatorKey,
      // 👇 Apply SafeArea globally using the builder
      builder: (context, child) {
        return SafeArea(child: child ?? const SizedBox.shrink());
      },
      // Light Theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: lightColorScheme.surface,

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: lightColorScheme.primary,
            foregroundColor: lightColorScheme.surface,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: Size(double.infinity, 48),
            //textStyle: TextStyle(color: lightColorScheme.surface, fontSize: 16),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: lightColorScheme.primary,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: Size(double.infinity, 48),
            side: BorderSide(color: lightColorScheme.primary),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: lightColorScheme.onSurface,
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: lightColorScheme.onSurface),
          filled: true,
          fillColor: lightColorScheme.onSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: lightColorScheme.surface),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: lightColorScheme.onSurface),
          ),
        ),

        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 57,
            fontWeight: FontWeight.bold,
            color: lightColorScheme.onSurface,
          ),
          displayMedium: TextStyle(
            fontSize: 45,
            fontWeight: FontWeight.bold,
            color: lightColorScheme.onSurface,
          ),
          displaySmall: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: lightColorScheme.onSurface,
          ),
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: lightColorScheme.onSurface,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: lightColorScheme.onSurface,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: lightColorScheme.onSurface,
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: lightColorScheme.onSurface,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: lightColorScheme.onSurface,
          ),
          titleSmall: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: lightColorScheme.onSurface,
          ),
          bodyLarge: TextStyle(fontSize: 18, color: lightColorScheme.onSurface),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: lightColorScheme.onSurface,
          ),
          bodySmall: TextStyle(fontSize: 14, color: lightColorScheme.onSurface),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: lightColorScheme.onSurface,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: lightColorScheme.onSurface,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: lightColorScheme.onSurface,
          ),
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: lightColorScheme.surface,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: lightColorScheme.onSurface,
            fontSize: 20,
          ),
          iconTheme: IconThemeData(color: lightColorScheme.onSurface, size: 24),
        ),

        cardTheme: CardThemeData(
          color: lightColorScheme.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          shadowColor: lightColorScheme.onSecondary,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: lightColorScheme.surface,
          selectedItemColor: lightColorScheme.primary,
          unselectedItemColor: lightColorScheme.onSurface,
          elevation: 10,
          type: BottomNavigationBarType.fixed,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),

      // Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkColorScheme.surface,

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkColorScheme.primary,
            foregroundColor: lightColorScheme.surface,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: Size(double.infinity, 48),
            textStyle: TextStyle(color: darkColorScheme.surface, fontSize: 16),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: darkColorScheme.primary,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: Size(double.infinity, 48),
            side: BorderSide(color: darkColorScheme.primary),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: darkColorScheme.onSurface,
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: darkColorScheme.onSurface),
          filled: true,
          fillColor: darkColorScheme.onSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkColorScheme.surface),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkColorScheme.onSurface),
          ),
        ),

        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 57,
            fontWeight: FontWeight.bold,
            color: darkColorScheme.onSurface,
          ),
          displayMedium: TextStyle(
            fontSize: 45,
            fontWeight: FontWeight.bold,
            color: darkColorScheme.onSurface,
          ),
          displaySmall: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: darkColorScheme.onSurface,
          ),
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: darkColorScheme.onSurface,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkColorScheme.onSurface,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: darkColorScheme.onSurface,
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: darkColorScheme.onSurface,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: darkColorScheme.onSurface,
          ),
          titleSmall: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkColorScheme.onSurface,
          ),
          bodyLarge: TextStyle(fontSize: 18, color: darkColorScheme.onSurface),
          bodyMedium: TextStyle(fontSize: 16, color: darkColorScheme.onSurface),
          bodySmall: TextStyle(fontSize: 14, color: darkColorScheme.onSurface),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: darkColorScheme.onSurface,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: darkColorScheme.onSurface,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: darkColorScheme.onSurface,
          ),
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.surface,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: darkColorScheme.onSurface,
            fontSize: 20,
          ),
          iconTheme: IconThemeData(color: darkColorScheme.onSurface),
        ),

        cardTheme: CardThemeData(
          color: darkColorScheme.onSecondary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          shadowColor: darkColorScheme.onSecondary,
        ),

        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: darkColorScheme.surface,
          selectedItemColor: darkColorScheme.secondary,
          unselectedItemColor: darkColorScheme.onSurface,
          elevation: 10,
          type: BottomNavigationBarType.fixed,
        ),

        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Colors.white, // Background color of the sheet
          elevation: 8.0, // Shadow effect
          modalBackgroundColor:
              Colors.grey[200], // Background color for modal bottom sheets
          modalElevation: 10.0, // Elevation for modal sheets
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ), // Rounded corners
          ),
          clipBehavior: Clip.antiAlias, // Ensures smooth clipping
          shadowColor: Colors.black54, // Shadow color
        ),

        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),

      initialRoute: '/main',

      onGenerateRoute: (settings) {
        Widget page;

        switch (settings.name) {
          case '/':
            page = OnboardingScreen();
            break;
          case '/login':
            page = SignInScreen();
            break;
          case '/register':
            page = SignUpScreen();
            break;
          case '/forgot-password':
            page = ForgotPasswordScreen();
            break;
          case '/reset-code':
            final args = settings.arguments as Map<String, dynamic>;
            page = ResetCodeScreen(email: args['email']);
            break;
          case '/new-password':
            final args = settings.arguments as Map<String, dynamic>;
            page = NewPasswordScreen(
              resetCode: args['resetCode'],
              email: args['email'],
            );
            break;
          case '/main':
            page = BottomNavScreen();
            break;
          default:
            page = OnboardingScreen();
        }

        return MaterialPageRoute(builder: (context) => page);
      },
    );
  }
}
