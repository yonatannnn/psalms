import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'services/auth_service.dart';
import 'services/reading_service.dart';
import 'services/localization_service.dart';
import 'models/user_model.dart';
import 'bloc/reading_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/theme_service.dart';
import 'services/font_size_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize localization service
  await LocalizationService.instance.initialize();

  // Initialize theme service
  await ThemeService.instance.initialize();

  // Initialize font size service
  await FontSizeService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReadingBloc(readingService: ReadingService()),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeService.instance.themeMode,
        builder: (context, mode, _) => MaterialApp(
          title: 'Mezmure Dawit',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
            textTheme: GoogleFonts.notoSerifTextTheme(),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              titleTextStyle: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
            useMaterial3: true,
            textTheme: GoogleFonts.notoSerifTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey.shade900,
              foregroundColor: Colors.white,
              titleTextStyle: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
          ),
          themeMode: mode,
          localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
          Locale('en', ''), // English
          Locale('am', ''), // Amharic
          ],
          home: const AuthWrapper(),
          routes: {
          '/login': (context) => const LoginPage(),
          },
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/md.jpg',
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          // User is signed in, get user data and show home page
          return FutureBuilder<UserModel?>(
            future: AuthService().getCurrentUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/md.jpg',
                          width: 150,
                          height: 150,
                        ),
                        const SizedBox(height: 32),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                return HomePage(user: userSnapshot.data!);
              } else {
                // User data not found, sign out and show login
                AuthService().signOut();
                return const LoginPage();
              }
            },
          );
        } else {
          // User is not signed in, show login page
          return const LoginPage();
        }
      },
    );
  }
}