import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/properties/screens/properties_screen.dart';
import '../../features/properties/screens/property_detail_screen.dart';
import '../../features/properties/bloc/properties_bloc.dart';
import '../../features/users/screens/users_screen.dart';
import '../../features/requirements/screens/requirements_screen.dart';
import '../../features/clients/screens/clients_screen.dart';
import '../../features/owners/screens/owners_screen.dart';
import '../../features/builders/screens/builders_screen.dart';
import '../../splash.dart';
import '../design_system/widgets/app_shell.dart';
import '../design_system/widgets/placeholder_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/audit_logs_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/properties/screens/recycle_bin_screen.dart';
import '../network/sync_manager.dart';


class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => CRMAppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/properties',
            builder: (context, state) {
              final openId = state.uri.queryParameters['openId'] ?? (state.extra as String?);
              return BlocProvider(
                create: (context) => PropertiesBloc(),
                child: PropertiesScreen(openPropertyId: openId),
              );
            },
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/requirements',
            builder: (context, state) => const RequirementsScreen(),
          ),
          GoRoute(
            path: '/clients',
            builder: (context, state) => const ClientsScreen(),
          ),
          GoRoute(
            path: '/owners',
            builder: (context, state) => const OwnersScreen(),
          ),
          GoRoute(
            path: '/builders',
            builder: (context, state) => const BuildersScreen(),
          ),
          GoRoute(
            path: '/finance',
            builder: (context, state) => const CRMPlaceholderScreen(
              title: 'Finance & Invoices',
              icon: Icons.monetization_on_rounded,
              description: 'Track agency commissions, invoice ledger systems, and split transactions.',
              upcomingFeatures: [
                'Automated broker brokerage invoices generator',
                'Split fee schedules and agency payouts ledger',
                'GST tax billing audits and audit history export',
              ],
            ),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/audit-logs',
            builder: (context, state) => const AuditLogsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/bin',
            builder: (context, state) => const RecycleBinScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/properties/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PropertyDetailScreen(propertyId: id);
        },
      ),
    ],
    redirect: (context, state) {
      final authState = authBloc.state;
      final loggingIn = state.matchedLocation == '/login';
      final onSplash = state.matchedLocation == '/splash';

      if (authState is Authenticated) {
        if (loggingIn) {
          return '/dashboard';
        }
        if (onSplash) {
          if (!SyncManager().isSyncCompleted) {
            return null; // Stay on splash screen until sync completes
          }
          return '/dashboard';
        }
      } else if (authState is Unauthenticated) {
        if (!loggingIn && !onSplash) {
          return '/splash';
        }
      }
      return null;
    },
  );
}
