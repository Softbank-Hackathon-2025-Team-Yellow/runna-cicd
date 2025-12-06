# Requirements Document

## Introduction

This feature provides a linting and validation system for enforcing frontend development rules in a React + TypeScript + TailwindCSS + Vite project. The system validates architectural patterns, API call conventions, state management practices, component structure, and TypeScript usage according to defined team standards.

## Scope

THE FE Rules Validator SHALL validate static code patterns, file paths, imports, and architectural conventions.

## Out of Scope

THE FE Rules Validator SHALL NOT:
- Evaluate runtime behavior
- Execute API calls or run React components
- Validate UI design or TailwindCSS colors
- Infer developer intent beyond static code analysis

## Rule Priority Levels

- **HIGH**: Must always be enforced. Violations break the build.
- **MEDIUM**: Strongly recommended. Violations generate warnings.
- **LOW**: Optional conventions. Violations generate suggestions only.

## Glossary

- **FE Rules Validator**: The frontend rules validation and enforcement system
- **Project Structure**: The organized directory layout including api/, features/, components/, stores/, pages/, hooks/, types/, utils/, styles/
- **Feature Module**: A domain-based module under features/ containing hooks, components, and related logic
- **API Module**: Axios-based HTTP client and endpoint definitions in api/ directory
- **React Query Hook**: Custom hooks that wrap React Query for data fetching
- **Zustand Store**: Global state management store for UI state
- **Developer**: A user who writes code subject to the validation rules

## Requirements

### Requirement 1

**User Story:** As a Developer, I want the project structure to be validated against the defined architecture, so that all files are organized correctly

#### Acceptance Criteria

1. [HIGH] THE FE Rules Validator SHALL verify that source files are organized into api/, features/, components/, hooks/, pages/, stores/, types/, utils/, and styles/ directories
2. [HIGH] WHEN a file is created outside the defined structure, THE FE Rules Validator SHALL report a violation with the expected location
3. [MEDIUM] THE FE Rules Validator SHALL verify that feature modules under features/ contain hooks/, components/, and index.ts files
4. [HIGH] THE FE Rules Validator SHALL validate that API endpoint definitions exist only within the api/ directory
5. [MEDIUM] THE FE Rules Validator SHALL check that global styles are placed in the styles/ directory

### Requirement 2

**User Story:** As a Developer, I want API calls to follow the defined pattern, so that data fetching is consistent and maintainable

#### Acceptance Criteria

1. [HIGH] THE FE Rules Validator SHALL detect direct axios calls in components/ and pages/ directories and report violations
2. [HIGH] WHEN an API call is found, THE FE Rules Validator SHALL verify it uses an API module from the api/ directory
3. [HIGH] THE FE Rules Validator SHALL verify that React Query custom hooks wrap API calls for data fetching
4. [MEDIUM] THE FE Rules Validator SHALL check that api/http.ts contains the axios instance with baseURL from environment variables
5. [LOW] THE FE Rules Validator SHALL validate that API modules export named functions following the pattern entityAPI.methodName

### Requirement 3

**User Story:** As a Developer, I want state management to follow defined patterns, so that application state is predictable and well-organized

#### Acceptance Criteria

1. [HIGH] THE FE Rules Validator SHALL verify that server data is managed through React Query hooks, not Zustand stores
2. [MEDIUM] WHEN a Zustand store is detected, THE FE Rules Validator SHALL verify it contains only UI state such as theme, modal state, or authentication status
3. [HIGH] THE FE Rules Validator SHALL detect API response data stored in Zustand and report violations
4. [LOW] THE FE Rules Validator SHALL verify that component-local state uses useState for simple cases
5. [MEDIUM] THE FE Rules Validator SHALL check that store files are located in the stores/ directory with .store.ts naming convention

### Requirement 4

**User Story:** As a Developer, I want component structure to be validated, so that components follow architectural guidelines

#### Acceptance Criteria

1. [MEDIUM] THE FE Rules Validator SHALL verify that reusable UI components in components/ directory have no internal state or API calls
2. [MEDIUM] THE FE Rules Validator SHALL check that feature-specific components are placed within their respective features/ subdirectories
3. [MEDIUM] THE FE Rules Validator SHALL verify that page components in pages/ directory contain minimal logic and delegate to custom hooks
4. [HIGH] THE FE Rules Validator SHALL validate that TailwindCSS classes are used for styling instead of separate CSS files
5. [HIGH] THE FE Rules Validator SHALL detect global CSS usage outside the styles/ directory and report violations

### Requirement 5

**User Story:** As a Developer, I want TypeScript usage to be validated, so that type safety is maintained throughout the codebase

#### Acceptance Criteria

1. [MEDIUM] THE FE Rules Validator SHALL verify that all functions have explicit return type annotations
2. [HIGH] THE FE Rules Validator SHALL check that API DTO types are defined in types/api/ directory
3. [LOW] THE FE Rules Validator SHALL verify that component Props interfaces are defined within the component file
4. [HIGH] THE FE Rules Validator SHALL detect usage of 'any' type and report violations with suggestions for proper typing
5. [LOW] THE FE Rules Validator SHALL validate that imported types use the 'type' keyword in import statements where applicable

### Requirement 6

**User Story:** As a Developer, I want error and loading states to be handled consistently, so that user experience is predictable

#### Acceptance Criteria

1. [HIGH] THE FE Rules Validator SHALL verify that React Query hooks check isLoading, isError, and data states
2. [MEDIUM] WHEN a data fetching hook is used, THE FE Rules Validator SHALL verify that LoadingSpinner, ErrorMessage, or EmptyState components are rendered for respective states
3. [HIGH] THE FE Rules Validator SHALL detect unhandled loading or error states in components using data fetching hooks
4. [MEDIUM] THE FE Rules Validator SHALL verify that error boundaries are implemented for feature modules
5. [MEDIUM] THE FE Rules Validator SHALL check that async operations include proper error handling with try-catch blocks

### Requirement 7

**User Story:** As a Developer, I want React Query hooks to follow naming and structure conventions, so that data fetching is standardized

#### Acceptance Criteria

1. [MEDIUM] THE FE Rules Validator SHALL verify that React Query custom hooks are named with the 'use' prefix followed by the entity name
2. [HIGH] THE FE Rules Validator SHALL check that React Query hooks are located in features/[domain]/hooks/ directories
3. [MEDIUM] THE FE Rules Validator SHALL verify that queryKey arrays follow the pattern ["entity", "operation", ...params]
4. [HIGH] THE FE Rules Validator SHALL validate that queryFn references an API module function, not inline axios calls
5. [MEDIUM] THE FE Rules Validator SHALL check that mutation hooks use useMutation with proper onSuccess and onError handlers
