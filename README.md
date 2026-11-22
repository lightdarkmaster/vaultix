
# Vaultix – Password Manager

**Vaultix** is a Flutter-based mobile password manager application designed to help users securely organize, manage, and access their sensitive login credentials in one centralized location.

The application aims to provide a simple, modern, and user-friendly experience for managing passwords while prioritizing security, privacy, and convenience. Vaultix is intended to eliminate the need to remember multiple passwords by allowing users to store and organize their credentials within a dedicated password management application.

---

## Project Information

| Information | Details |
|---|---|
| Project Name | Vaultix |
| Application Type | Mobile Application |
| Framework | Flutter |
| Programming Language | Dart |
| Platform | Android / iOS |
| Repository | Vaultix |
| Development Status | In Development |

## Branches

The project follows a branch-based development workflow to organize development activities, manage features, and maintain stable application versions.

| Branch | Description |
|---|---|
| `main` | Main branch containing stable and production-ready versions of the application. |
| `dev` | Development branch where new features, improvements, and bug fixes are integrated and tested. |
| `phase4` | Dedicated development branch for Phase 4 implementation, enhancements, and project-specific requirements. |

### Branch Workflow

1. **main** – Maintains the stable version of Vaultix.
2. **dev** – Used for ongoing development, feature integration, and testing.
3. **phase4** – Used for implementing and maintaining Phase 4 requirements.

Changes should be developed and tested in the appropriate development branch before being integrated into the main branch.

---

## Project Overview

Vaultix aims to provide users with a centralized platform for storing and managing important account credentials without relying on manual password tracking or unsecured storage methods.

Through its mobile interface, users will be able to organize their saved accounts, retrieve login information when needed, and manage their stored credentials conveniently.

The application is being developed using Flutter to support a consistent user experience and maintain a scalable codebase for future enhancements.

## Key Features

The following features represent the intended functionality of Vaultix:

### 1. Password Management

- Add and save account credentials.
- View and manage stored passwords.
- Edit existing credential entries.
- Delete outdated or unnecessary credentials.
- Organize credentials by account or service.

### 2. Password Generator

- Generate random and strong passwords.
- Customize password length.
- Configure uppercase and lowercase letters.
- Include numbers and special characters.
- Generate passwords to help users create stronger account credentials.

### 3. Secure Access

- Provide an authentication mechanism for accessing the application.
- Support biometric authentication where available.
- Protect sensitive password information.
- Implement appropriate encryption and secure data storage.

### 4. Credential Organization

- Categorize saved credentials.
- Search for specific accounts.
- View saved account information through an organized interface.
- Easily navigate between stored credentials.

### 5. User Interface and Experience

- Modern and clean mobile application interface.
- User-friendly navigation.
- Responsive layouts for different screen sizes.
- Light and dark theme support.
- Consistent application styling and visual components.

---

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform mobile application development |
| Dart | Primary programming language |
| Material Design | User interface components and styling |
| SQLite / Local Storage | Local data persistence, depending on implementation |
| Git | Version control |
| GitHub | Source code repository and collaboration |

*Note: The technology and storage integrations may evolve as the project progresses.*

---

## Getting Started

Follow these instructions to set up and run Vaultix on your local development environment.

### Prerequisites

Before running the project, ensure that the following tools are installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- [Android Studio](https://developer.android.com/studio) or [Visual Studio Code](https://code.visualstudio.com/)
- Git
- Android Emulator or a physical Android device

### Installation

**1. Clone the Repository**

```bash
git clone <repository-url>
```

**2. Navigate to the Project Directory**

```bash
cd vaultix
```

**3. Switch to the Development Branch**

```bash
git checkout dev
```

**4. Install Dependencies**

```bash
flutter pub get
```

**5. Check Flutter Environment**

```bash
flutter doctor
```

**6. Run the Application**

```bash
flutter run
```

---

## Development Guidelines

To maintain an organized development workflow, follow these guidelines:

1. Create or switch to the appropriate branch before implementing changes.
2. Follow the existing project structure and coding conventions.
3. Use meaningful names for variables, classes, methods, and files.
4. Keep application components modular and reusable.
5. Test newly implemented features before merging changes.
6. Resolve identified bugs before integrating changes into stable branches.
7. Commit changes using clear and descriptive commit messages.

### Example Git Commands

```bash
# Check current branch
git branch

# Switch to development branch
git checkout dev

# Pull latest changes
git pull origin dev

# Stage changes
git add .

# Commit changes
git commit -m "feat: implement password management"

# Push changes
git push origin dev
```

---

## Project Objectives

The primary objectives of Vaultix are:

- Develop a reliable and user-friendly password management application.
- Provide a centralized solution for managing multiple account credentials.
- Promote better password management practices.
- Prioritize user privacy and data protection.
- Implement secure mechanisms for handling sensitive information.
- Establish a scalable application architecture that supports future improvements and additional features.

---

## Future Enhancements

Potential improvements and additional functionalities include:

- Cloud backup and synchronization.
- Password health and strength analysis.
- Duplicate password detection.
- Secure password sharing.
- Automatic password expiration reminders.
- Import and export of password records.
- Multi-device synchronization.
- Additional authentication and security options.

---

## Resources and Documentation

The following resources can help developers understand Flutter development and application implementation:

- [Flutter Documentation](https://docs.flutter.dev/)
- [Write Your First Flutter App](https://docs.flutter.dev/get-started/codelab)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Dart Documentation](https://dart.dev/guides)
- [Flutter Packages](https://pub.dev/)

For additional information about Flutter development, refer to the official [Flutter Documentation](https://docs.flutter.dev/), which provides tutorials, development guides, code samples, and API references.

---

## License

This project is currently maintained as a development project. Licensing and distribution details may be established in a future release.

---

**Vaultix – Your Passwords, Organized. Your Digital Life, Protected.**


By: Christian Barbosa, Junior Software Developer
