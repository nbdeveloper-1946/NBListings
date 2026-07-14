import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/dashboard/repository/dashboard_repository.dart';
import 'features/users/repository/users_repository.dart';
import 'features/requirements/repository/requirements_repository.dart';
import 'features/clients/repository/clients_repository.dart';
import 'features/dashboard/bloc/dashboard_bloc.dart';
import 'features/users/bloc/users_bloc.dart';
import 'features/requirements/bloc/requirements_bloc.dart';
import 'features/clients/bloc/clients_bloc.dart';
import 'core/navigation/app_router.dart';
import 'core/design_system/tokens/app_colors.dart';
import 'core/design_system/tokens/app_typography.dart';

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
        RepositoryProvider(create: (context) => RequirementsRepository()),
        RepositoryProvider(create: (context) => ClientsRepository()),
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
          BlocProvider(
            create: (context) => RequirementsBloc(
              requirementsRepository: context.read<RequirementsRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => ClientsBloc(
              clientsRepository: context.read<ClientsRepository>(),
            ),
          ),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'NB Listings',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            fontFamily: CRMTypography.fontFamily,
            colorScheme: ColorScheme.fromSeed(
              seedColor: CRMColors.primary,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: CRMColors.background,
          ),
          routerConfig: _appRouter.router,
        ),
      ),
    );
  }
}