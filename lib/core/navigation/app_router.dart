import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/properties/screens/properties_screen.dart';
import '../../features/properties/bloc/properties_bloc.dart';
import '../../features/users/screens/users_screen.dart';
import '../../features/requirements/screens/requirements_screen.dart';
import '../../features/clients/screens/clients_screen.dart';
import '../../splash.dart';
import '../design_system/widgets/app_shell.dart';
import '../design_system/widgets/placeholder_screen.dart';

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
            builder: (context, state) => BlocProvider(
              create: (context) => PropertiesBloc(),
              child: const PropertiesScreen(),
            ),
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
            builder: (context, state) => const CRMPlaceholderScreen(
              title: 'Owners Directory',
              icon: Icons.person_pin_rounded,
              description: 'Direct landlord registry database and supply channel management.',
              upcomingFeatures: [
                'Direct-to-owner contact lookup logs',
                'Verification audit trails for owner listings',
                'Exclusive supply tagging & commission split templates',
              ],
            ),
          ),
          GoRoute(
            path: '/builders',
            builder: (context, state) => const CRMPlaceholderScreen(
              title: 'Builders & Projects',
              icon: Icons.business_rounded,
              description: 'Track developer projects, tower progress, and master layout schemes.',
              upcomingFeatures: [
                'Project-wise tower unit inventory boards',
                'Builder profiles & past delivery metrics',
                'Bulk pricing adjustment utility',
              ],
            ),
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
            builder: (context, state) => const CRMPlaceholderScreen(
              title: 'Reports & Analytics',
              icon: Icons.analytics_rounded,
              description: 'Analyze broker productivity, property demand trends, and transaction history.',
              upcomingFeatures: [
                'PDF executive summary report builder',
                'Property type market trend dashboards',
                'Audit logs & modification timelines explorer',
              ],
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const CRMPlaceholderScreen(
              title: 'Settings & Configs',
              icon: Icons.settings_rounded,
              description: 'Configure corporate metadata, custom fields, and API access tokens.',
              upcomingFeatures: [
                'Custom drop-down options builder',
                'System API keys & webhook integration console',
                'Branded invoice layouts & email templates designer',
              ],
            ),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final authState = authBloc.state;
      final loggingIn = state.matchedLocation == '/login';
      final onSplash = state.matchedLocation == '/splash';

      if (authState is Authenticated) {
        if (loggingIn || onSplash) {
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
