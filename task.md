# Tasks: Integrate UI reference code

- [x] Merge styling and core modules
  - [x] Copy `C:\Users\DELL\Downloads\lib\core\theme\theme_manager.dart` to `c:\Users\DELL\StudioProjects\nblistings\lib\core\theme\theme_manager.dart`
  - [x] Copy `C:\Users\DELL\Downloads\lib\core\theme\app_theme.dart` to `c:\Users\DELL\StudioProjects\nblistings\lib\core\theme\app_theme.dart`
  - [x] Copy `C:\Users\DELL\Downloads\lib\core\design_system\tokens\app_colors.dart` to `c:\Users\DELL\StudioProjects\nblistings\lib\core\design_system\tokens\app_colors.dart`
  - [x] Copy `C:\Users\DELL\Downloads\lib\core\design_system\widgets\app_shell.dart` to `c:\Users\DELL\StudioProjects\nblistings\lib\core\design_system\widgets\app_shell.dart`
- [x] Copy updated features
  - [x] Copy splash and auth views
  - [x] Copy clients, properties, requirements, users features (except owners/builders)
- [x] Merge router & main providers
  - [x] Update `app_router.dart` with `/owners` and `/builders` routes
  - [x] Update `main.dart` with theme toggle and owners/builders bloc registrations
- [x] Verification
  - [x] Run `flutter test` and resolve dynamic const color compile issues
