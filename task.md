# Tasks: Dynamic Locations & Modal Form

- [ ] Backend updates
  - [ ] Update `src/config/databaseCheck.js` to seed major Gujarat cities
  - [ ] Implement `createCity` and `createArea` in repository, service, and controller
  - [ ] Mount routes for `POST /api/v1/properties/cities` and `POST /api/v1/properties/areas`
- [ ] Frontend Updates
  - [ ] Update `PropertiesScreen` and `AppShell` to display `AddEditPropertyScreen` as a modal Dialog
  - [ ] Set "Add New Property" as the modal header title
  - [ ] Add "+" buttons next to City and Area fields inside `AddEditPropertyScreen`
  - [ ] Implement dynamic creation logic for City and Area calling backend APIs and refreshing state instantly
  - [ ] Add "Location Settings" manager inside `settings_screen.dart`
- [ ] Verification
  - [ ] Compile and run `flutter test`
