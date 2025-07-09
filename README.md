# Running Group Booking App

This Flutter app is built for a small running group to manage and book runs seamlessly. It provides user authentication, run listings, attendance tracking, and notifications — all powered by Firebase and Google APIs.

## Overview

Users can log in or register using Firebase Authentication. There are two types of accounts: regular users (runners) and admins. Admins have extra privileges like creating, editing, and deleting runs.

The app shows a list of upcoming runs with details like run number, title, description, and meeting point. Each run has a unique meeting location displayed on a map using the Google Maps API. The location is chosen via the Places API, which suggests addresses and retrieves the exact coordinates.

On the run detail page, users can RSVP if they plan to attend. They can also scan a QR code at the event to confirm attendance and choose their run distance (3, 5, or 7 km). This attendance system is tied to an XP and leveling system, which helps prevent cheating by ensuring users physically attend the event.

Users also have a profile page showing their running statistics, such as completed runs, streaks, and percentile ranking compared to others.

Admins can post runs with images hosted on Google Drive. Runs automatically become unavailable to join after their scheduled time passes.

## Notifications

The app sends push notifications via Firebase Cloud Messaging (FCM) to users, whether the app is in the foreground, background, or closed, ensuring everyone stays updated when a new run is posted.

## Bug Reporting

There’s a dedicated bug report page that uses EmailJS to send professional emails directly from the app. I thought it would be a better idea than opening the user's email app to send what they added inside the form.

## Technical Highlights

- Firebase Authentication for login, registration, and password recovery  
- Firestore for run data, user profiles, and attendance  
- Google Maps and Places APIs for location selection and display  
- Firebase Cloud Messaging (FCM) for push notifications  
- QR code scanning to verify attendance and run distance selection  
- XP and leveling system to reward participation and prevent cheating  
- Provider package for efficient state management and code reuse  
- Race condition prevention using request queues for critical actions  
- Admin tools for run management (add, edit, delete)  
- Runs automatically expire after their scheduled time  
- Backend API hosted on Render for managing API keys securely  
- Python script that exports Firebase data into spreadsheets for admin analysis

## What I Learned

- Integrating multiple Firebase services into a single app  
- Working with Google Maps and Places APIs inside Flutter  
- Managing user roles and permissions cleanly  
- Handling push notifications across app states  
- Implementing real-time attendance verification with QR codes  
- Building a reliable bug reporting system from the app  
- Structuring a Flutter app for scalability and maintainability  
- Syncing backend scripts for data export and admin insights  

## Future Plans

- Final polishing and UI improvements based on user feedback  
- Preparing the app for release on both Android and iOS  
- Adding small platform-specific adjustments for iOS compatibility  
- Expanding notification features and analytics  
- Potential integration with social features or community boards  

