import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:neqati/core/utils/app_theme.dart';

import 'core/services/dependency_injector.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/verification_pending_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/levels/cubit/levels_cubit.dart';
import 'features/offers/cubit/offers_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with manual options
  await Firebase.initializeApp();
  
  // Initialize Firebase App Check with debug provider
  // This is suitable for development - for production, you'll need to configure proper providers
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  
  // Initialize dependency injector
  await DependencyInjector().initialize();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (context) => AuthCubit()..checkAuthState()),
        BlocProvider<OffersCubit>(create: (context) => OffersCubit()),
        BlocProvider<LevelsCubit>(
          create: (context) => LevelsCubit(
            authCubit: context.read<AuthCubit>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'نقاطي',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: DependencyInjector().navigationService.navigatorKey,
        // RTL support for Arabic
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('ar', ''), // Arabic
        ],
        locale: const Locale('ar', ''),
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading || state is AuthInitial) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            } else if (state is AuthAuthenticated) {
              return HomeScreen(isAdmin: state.isAdmin);
            } else if (state is AuthNotVerified) {
              return const VerificationPendingScreen();
            } else {
              return const LoginScreen();
            }
          },
        ),
      ),
    );
  }
}
