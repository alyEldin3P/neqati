import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:neqati/core/services/auth_service.dart';
import 'package:neqati/core/utils/app_theme.dart';
import 'package:neqati/features/admin/dashboard/cubit/dashboard_cubit.dart';
import 'package:neqati/features/admin/scan_history/cubit/scan_history_cubit.dart';
import 'package:neqati/features/admin/user_management/cubit/user_management_cubit.dart';
import 'package:neqati/features/admin/qr_management/cubit/qr_management_cubit.dart';
import 'package:neqati/features/admin/gift_management/cubit/gift_management_cubit.dart';
import 'package:neqati/features/admin/gift_management/cubit/gift_request_management_cubit.dart';
import 'package:neqati/features/admin/offer_management/cubit/offer_management_cubit.dart';
import 'package:neqati/features/admin/level_management/cubit/level_management_cubit.dart';
import 'package:neqati/features/gifts/cubit/gift_cubit.dart';
import 'package:neqati/features/gifts/cubit/qr_scan_cubit.dart';
import 'package:neqati/features/gifts/cubit/scan_history_cubit.dart';
import 'package:neqati/features/gifts/cubit/user_gift_request_cubit.dart';

import 'core/services/dependency_injector.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/levels/cubit/levels_cubit.dart';
import 'features/offers/cubit/offers_cubit.dart';

void main() async {
  dev.log('App: Starting application initialization');
  WidgetsFlutterBinding.ensureInitialized();
  dev.log('App: WidgetsFlutterBinding initialized');

  // Initialize Supabase
  dev.log('App: Initializing Supabase');

  final supabaseUrl = "https://avlfzbqnqcjxwcjnokcq.supabase.co";

  final supabaseKey = "sb_publishable_khNbCskMXpwpfJI27tyzSA_Z7OQ7Y7z";

  dev.log('App: Using Supabase URL: $supabaseUrl');
  await AuthService.initialize(
    supabaseUrl: supabaseUrl,
    supabaseKey: supabaseKey,
  );
  dev.log('App: Supabase initialized');

  // Initialize dependency injector
  dev.log('App: Initializing DependencyInjector');
  await DependencyInjector().initialize();
  dev.log('App: DependencyInjector initialized');

  // Force portrait orientation
  dev.log('App: Setting preferred orientations');
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  dev.log('App: Starting MyApp');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    dev.log('MyApp: Building application');
    return MultiBlocProvider(
      providers: [
        // Auth Cubit - Main authentication state management
        BlocProvider<AuthCubit>(
          create: (context) {
            dev.log('MyApp: Creating AuthCubit');
            final cubit = AuthCubit();
            dev.log('MyApp: Checking auth state');
            cubit.checkAuthState();
            return cubit;
          },
        ),

        // User features Cubits
        BlocProvider<OffersCubit>(
          create: (context) {
            dev.log('MyApp: Creating OffersCubit');
            return OffersCubit();
          },
        ),
        BlocProvider<LevelsCubit>(
          create: (context) {
            dev.log('MyApp: Creating LevelsCubit');
            final authCubit = context.read<AuthCubit>();
            dev.log('MyApp: Got AuthCubit for LevelsCubit');
            return LevelsCubit(authCubit: authCubit);
          },
        ),

        // Admin feature Cubits
        BlocProvider<DashboardCubit>(
          create: (context) {
            dev.log('MyApp: Creating DashboardCubit');
            return DashboardCubit();
          },
        ),
        BlocProvider<UserManagementCubit>(
          create: (context) {
            dev.log('MyApp: Creating UserManagementCubit');
            return UserManagementCubit(
              userService: DependencyInjector().userService,
            );
          },
        ),
        BlocProvider<QrManagementCubit>(
          create: (context) {
            dev.log('MyApp: Creating QrManagementCubit');
            return QrManagementCubit(
              qrService: DependencyInjector().qrCodeService,
            );
          },
        ),
        BlocProvider<GiftManagementCubit>(
          create: (context) {
            dev.log('MyApp: Creating GiftManagementCubit');
            return GiftManagementCubit(
              giftService: DependencyInjector().giftService,
            );
          },
        ),
        BlocProvider<GiftRequestManagementCubit>(
          create: (context) {
            dev.log('MyApp: Creating GiftRequestManagementCubit');
            return GiftRequestManagementCubit(
              giftService: DependencyInjector().giftService,
            );
          },
        ),
        BlocProvider<OfferManagementCubit>(
          create: (context) {
            dev.log('MyApp: Creating OfferManagementCubit');
            return OfferManagementCubit(
              offerService: DependencyInjector().offerService,
            );
          },
        ),
        BlocProvider<LevelManagementCubit>(
          create: (context) {
            dev.log('MyApp: Creating LevelManagementCubit');
            return LevelManagementCubit(
              levelService: DependencyInjector().levelService,
            );
          },
        ),
        BlocProvider<ScanHistoryCubit>(
          create: (context) {
            dev.log('MyApp: Creating ScanHistoryCubit');
            return ScanHistoryCubit(
              scanService: DependencyInjector().scanService,
            );
          },
        ),
        BlocProvider<UserScanHistoryCubit>(
          create: (context) {
            dev.log('MyApp: Creating ScanHistoryCubit');
            return UserScanHistoryCubit(
              scanService: DependencyInjector().scanService,
            );
          },
        ),
        // gifts , offers , levels , qr codes , users , admin dashboard
        BlocProvider<GiftCubit>(
          create: (context) {
            dev.log('MyApp: Creating GiftCubit');
            return GiftCubit(
              giftService: DependencyInjector().giftService,
              onGiftRequestSuccess: () {
                // Refresh user data after successful gift request
                final authCubit = context.read<AuthCubit>();

                // Refresh user data to update points
                authCubit.refreshUserData();

                dev.log(
                  '🔄 MyApp: Refreshed user data after successful gift request',
                );
              },
            );
          },
        ),
        BlocProvider<OffersCubit>(
          create: (context) {
            dev.log('MyApp: Creating OffersCubit');
            return OffersCubit(offerService: DependencyInjector().offerService);
          },
        ),
        BlocProvider<LevelsCubit>(
          create: (context) {
            dev.log('MyApp: Creating LevelsCubit');
            return LevelsCubit(
              levelService: DependencyInjector().levelService,
              authCubit: context.read<AuthCubit>(),
            );
          },
        ),
        BlocProvider<QRScanCubit>(
          create: (context) {
            dev.log('MyApp: Creating QRScanCubit');
            return QRScanCubit(
              qrCodeService: DependencyInjector().qrCodeService,
              onScanSuccess: () {
                // Refresh user data after successful scan
                final authCubit = context.read<AuthCubit>();
                final scanHistoryCubit = context.read<UserScanHistoryCubit>();

                // Refresh user data to update points
                authCubit.refreshUserData();

                // Refresh scan history to show latest scan
                final authState = authCubit.state;
                if (authState is AuthAuthenticated) {
                  scanHistoryCubit.loadScanHistory(authState.user.id);
                }
              },
            );
          },
        ),
        BlocProvider<UserGiftRequestCubit>(
          create: (context) {
            dev.log('MyApp: Creating UserGiftRequestCubit');
            return UserGiftRequestCubit(
              giftService: DependencyInjector().giftService,
            );
          },
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
            dev.log(
              'MyApp: Building initial screen based on auth state: ${state.runtimeType}',
            );

            // Show a loading screen while checking auth state
            if (state is AuthLoading || state is AuthInitial) {
              dev.log('MyApp: Showing loading screen');
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Check the current auth state to determine the initial screen
            if (state is AuthAuthenticated) {
              dev.log(
                'MyApp: User already authenticated, showing HomeScreen with isAdmin: ${state.isAdmin}',
              );
              return HomeScreen(isAdmin: state.isAdmin);
            } else {
              // For all other states (unauthenticated, error, etc.), show the login screen
              // The login screen will handle navigation to other screens as needed
              dev.log('MyApp: Showing login screen as default');
              return const LoginScreen();
            }
          },
        ),
      ),
    );
  }
}
