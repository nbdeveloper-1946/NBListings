import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/bloc/dashboard_bloc.dart';
import 'features/dashboard/repository/dashboard_repository.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/users/bloc/users_bloc.dart';
import 'features/users/repository/users_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authRepository = AuthRepository();

  runApp(MyApp(authRepository: authRepository));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;

  const MyApp({super.key, required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider(create: (context) => DashboardRepository()),
        RepositoryProvider(create: (context) => UsersRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(authRepository: authRepository)..add(AuthCheckStatus()),
          ),
          BlocProvider(
            create: (context) => DashboardBloc(
              dashboardRepository: context.read<DashboardRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => UsersBloc(
              usersRepository: context.read<UsersRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'NB Listings',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1), // Indigo 500
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
          ),
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthInitial || (state is AuthLoading && state is! Authenticated)) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (state is Authenticated) {
                return const DashboardScreen();
              }
              return const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}
