# Coding Style Guide for Mujahedeen Flutter Project

This guide is designed for AI models and developers to understand and follow the coding style used in the Mujahedeen Flutter project. It is based on an analysis of the existing codebase.

## 1. Project Structure
- **Feature-Based Organization**: The codebase follows a feature-based structure under `lib/features/`, where each feature (e.g., `assign_tasks`, `notifications`, `attendance`) has its own folder containing subfolders like `data`, `model`, `presentation`, etc.
- **Core Utilities**: Common utilities and widgets are placed under `lib/core/` (e.g., `cubits`, `presentation/widgets`, `services`).

## 2. Naming Conventions
- **Classes and Widgets**: Use PascalCase for class and widget names (e.g., `AppContainer`, `AssignTasksScreen`).
- **Private Members**: Prefix private fields and methods with an underscore (e.g., `_isLoading`, `_loadEmployees()`).
- **File Names**: Use snake_case for file names (e.g., `assign_tasks_screen.dart`).
- **Variables**: Use camelCase for variable and method names (e.g., `hasReachedMax`, `getTasks()`).

## 3. State Management
- **Bloc/Cubit**: The project heavily uses `flutter_bloc` for state management. Each feature typically has a Cubit (e.g., `AssignTasksCubit`) and a corresponding state class (e.g., `AssignTasksState`) that extends `Equatable`.
- **State Properties**: State classes include status enums (e.g., `AssignTasksStatus`), data lists, error messages, and pagination flags (e.g., `hasReachedMax`).

## 4. UI and Widgets
- **Custom Widgets**: Reusable widgets are prefixed with `App` (e.g., `AppButton`, `AppText`, `AppContainer`) and are located in `lib/core/presentation/widgets/`.
- **Styling**: Use predefined constants for colors (`AppColors`), sizes (`AppSize`), and dimensions (`AppDimensions`) to maintain consistency.
- **Localization**: Text is localized using `.trans` extension (e.g., `'work_shifts_title'.trans`) for Arabic and English support.
- **Spacing**: Use extensions like `.heightBox` and `.widthBox` for consistent spacing (e.g., `8.heightBox`).

## 5. Data Handling
- **Models**: Data models are defined with fields matching API responses and often include helper getters for formatted data (e.g., `formattedDateRange` in `WorkMission`).
- **Repositories**: Data sources are abstracted into repository classes suffixed with `Rds` (e.g., `AssignTasksRds`) under `data/` folders.
- **Pagination**: Implement infinite scrolling with `ScrollController` and flags like `hasReachedMax` to load more data.

## 6. Error Handling and Loading
- **Loading States**: Use boolean flags (e.g., `_isLoading`) or state enums to manage loading UI states.
- **Error Handling**: Capture errors in state classes and display them via UI or logs (e.g., `errorMessage` in state).

## 7. Code Organization
- **Separation of Concerns**: UI (`presentation`), business logic (`cubit`), and data fetching (`data`) are strictly separated within each feature.
- **Dependency Injection**: Use a central `DependencyInjector` to provide services, cubits, and navigation across the app.

## 8. Language and Directionality
- **RTL/LTR Support**: The app supports Arabic (RTL) and English (LTR) with dynamic text direction based on locale (e.g., `TextDirection.rtl` for Arabic).
- **Locale Management**: Managed via `AppCubit` to switch between languages and update UI accordingly.

## 9. Logging
- **Debug Logs**: Use `log()` for debugging with descriptive messages and context (e.g., `log('[SplashScreen] Profile fetched successfully')`).

## 10. Best Practices
- **Null Safety**: The codebase adheres to Dart's null safety with appropriate use of nullable types (e.g., `String? errorMessage`).
- **Immutable State**: State updates are done immutably using `copyWith()` methods with ONLY on state class per cubit no state class extensions.
- **Minimal Rebuilds**: Optimize widgets to minimize unnecessary rebuilds by using `BlocBuilder` selectively.

## 11. Form Handling and Validation
- **Custom Form Fields**: Use `AppFormField` for consistent text input fields with properties like `isPassword` for toggling visibility and `validator` for input validation (e.g., in `login_screen.dart`).
- **Validation**: Implement validation using `AppValidators` class for reusable checks (e.g., `validateEmptyField`, `validateEmail`) with localized error messages.
- **Form Keys**: Utilize `GlobalKey<FormState>` for form validation and submission (e.g., in `LoginScreen` and `AddEditVisitScreen`).
- **Controllers**: Use `TextEditingController` for each form field to manage input state, especially in complex forms (e.g., `_taskNameArController` in `edit_add_task_sheet.dart`).

## 12. API Integration and Error Handling
- **Network Service**: Abstract API calls through `NetworkService` with methods like `post`, `get`, ensuring a single point of interaction with backend services.
- **Repository Pattern**: Implement data repositories (e.g., `AuthRDSImpl`, `PresenceInquiryRdsImpl`) to handle API calls and data parsing for each feature.
- **Error Handling**: Use `ApiError` class for structured error responses with localized messages via `getLocalizedMessage()` and fallback messages.
- **Data Parsing**: Models include `fromJson` and `toJson` methods for seamless API data conversion (e.g., `User.fromJson` in `user.dart`).
- **Pagination**: API calls for lists implement pagination with parameters like `pageNumber` and `pageSize`, and responses are wrapped in `PaginatedResponse` (e.g., in `PresenceInquiryRdsImpl`).

## 13. Custom Widgets and UI Consistency
- **Reusable Components**: Create custom widgets like `AppContainer`, `AppButton`, and `AppText` for consistent styling and behavior across the app.
- **Configurable Widgets**: Widgets accept extensive parameters for customization (e.g., `AppContainer` with margins, padding, shadows) to adapt to various UI needs.
- **Stateful Widgets**: Use stateful widgets for interactive components like `AppButton` with loading states and `AppFormField` with password visibility toggles.

## 14. Navigation and Routing
- **Navigation Service**: Use `NavigationService` for abstracted navigation with methods like `pushScreen`, `pushAndRemoveAll` to handle screen transitions (e.g., in `AuthCubit` for login navigation).
- **Route Names**: Define static `routeName` constants in screen widgets for named routing (e.g., `LoginScreen.routeName`).
- **Dependency Injection for Navigation**: Access navigation via `DependencyInjector().navigationService` to decouple navigation logic from UI code.

## 15. Additional Notes
- **Mock Data**: In development, mock data is often used for UI testing before API integration (e.g., in `_AssignEmployeesScreenState` with hardcoded employee lists).
- **Stateful Widget Lifecycle**: Leverage `initState` and `dispose` for initialization and cleanup, especially for controllers and listeners (e.g., in `AssignTasksScreen` for `ScrollController`).
- **Feature-Specific Cubits**: Each feature uses dedicated cubits for business logic, maintaining separation of concerns (e.g., `VisitCubit` for visit-related operations).

By following these conventions and structures, AI models can generate code that aligns with the existing style of the Mujahedeen project, ensuring consistency and maintainability.
