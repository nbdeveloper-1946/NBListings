import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/dashboard/repository/dashboard_repository.dart';
import 'features/users/repository/users_repository.dart';
import 'features/dashboard/bloc/dashboard_bloc.dart';
import 'features/users/bloc/users_bloc.dart';
import 'core/navigation/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final authRepository = AuthRepository();

  runApp(MyApp(authRepository: authRepository));
}

class MyApp extends StatefulWidget {
  final AuthRepository authRepository;

  const MyApp({super.key, required this.authRepository});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _appRouter;
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(authRepository: widget.authRepository)..add(AuthCheckStatus());
    _appRouter = AppRouter(_authBloc);
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.authRepository),
        RepositoryProvider(create: (context) => DashboardRepository()),
        RepositoryProvider(create: (context) => UsersRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authBloc),
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
        child: MaterialApp.router(
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
          routerConfig: _appRouter.router,
        ),
      ),
    );
  }
}