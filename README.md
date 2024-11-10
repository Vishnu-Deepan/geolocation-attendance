# Geolocation-Based Attendance Management System

A Flutter-based mobile application for tracking attendance using geolocation. This application leverages location services to verify and log users’ attendance at designated locations, ideal for organizations and institutions that require a reliable, location-based check-in/check-out system.

## Features

- **Login & Sign-up**: Secure user authentication for new and returning users.
- **Geolocation Check-In/Check-Out**: Automatically records attendance when users enter or exit designated areas.
- **Manual Check-In Option**: Allows users to log attendance manually if geolocation fails.
- **Attendance History**: View and track past attendance records in an organized format.
- **Working Hours Calculation**: Calculates total hours worked based on check-in and check-out times.
- **User Dashboard**: Personalized homepage displaying attendance status, work hours, and quick access to key features.

## Screens

1. **Login Page**: User authentication screen.
2. **Sign-Up Page**: New user registration.
3. **Home Page**: Dashboard with quick access to attendance features.
4. **Attendance History**: View past attendance records.
5. **Manual Check-In**: For manual attendance in case of location service issues.
6. **Working Hours Page**: Displays total hours worked.
7. **Work Hours Tracking**: Logs check-in/check-out times to calculate work duration.

## Installation

1. Clone this repository.
   ```bash
   git clone https://github.com/yourusername/geolocation-attendance.git
2. Ensure Flutter and Dart SDKs are installed.
3. Install dependencies.
   ```bash
   flutter pub get
4. Run the app on a connected device or emulator.
   ```bash
   flutter run

# Usage

- Register as a new user or log in with existing credentials.
- Allow location access for geolocation-based check-ins.
- Use the dashboard to track attendance, check working hours, and view attendance history.

# Future Enhancements

- **Admin Dashboard**: Interface for administrators to view all users' attendance.
- **Push Notifications**: Reminders for check-in/check-out.
- **Offline Mode**: Record attendance even without internet, sync when online.
- **Settings**: Settings Page in the User Dashboard to customize the preferences.

# Screenshots

![Login Screen](./screenshots/login-screen.png)  
![Home Screen](./screenshots/home-screen.png)  
![Attendance History](./screenshots/attendance-history.png)  
![Working Hours](./screenshots/working-hours.png)
