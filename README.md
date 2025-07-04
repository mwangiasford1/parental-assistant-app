# Parental Assistant

A cross-platform Flutter app to help families manage safety, learning, communication, and digital wellbeing, with roles for parents, children, and nannies.

---

## Features

- **Authentication & Roles**
  - Register/login as Parent, Child, or Nanny
  - Role-based home screen with tailored features

- **Onboarding & Welcome**
  - First-launch welcome and onboarding flow
  - Custom welcome message after registration based on user role

- **Chat & Messaging**
  
  - Real-time user-to-user messaging (parent ↔ child, parent ↔ nanny, etc.)
    - Conversation selector
    - Unread message badges
    - Last message preview
    - In-app and push notification support (optional)
  - Modern, secure chat UI

- **Password Backup & Recovery**
  - Securely store and manage passwords
  - Export/backup passwords
  - “Forgot Password?” feature for account recovery

- **Emergency SOS**
  - Send SOS alerts with location
  - View SOS alerts on a map
  - View and clear SOS alert log

- **Rewards, Homework, Scheduling, and More**
  - Manage rewards, homework, schedules, and content filtering
  - Parental controls and family management tools

- **Notifications**
  - Notification icon with badge for new messages
  - Placeholder for future notification center

- **UI/UX**
  - Clean, modern, and responsive design
  - Dark mode support
  - No debug banner in production

---

## Tech Stack
- **Flutter** (cross-platform mobile/web/desktop)
- **Firebase** (Auth, Firestore, Cloud Messaging)
- **OpenAI API** (ChatGPT integration)
- **Provider** (state management)
- **Other packages:** logger, flutter_map, etc.

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Firebase Project](https://firebase.google.com/)
- [OpenAI API Key](https://platform.openai.com/)

### Setup
1. **Clone the repository:**
   ```sh
   git clone <your-repo-url>
   cd parental_assistant
   ```
2. **Install dependencies:**
   ```sh
   flutter pub get
   ```
3. **Configure Firebase:**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the appropriate directories.
   - Update `firebase_options.dart` if needed.
4. **Set your OpenAI API key:**
   - In `lib/services/chatgpt_service.dart`, set your API key.

### Running the App
```sh
flutter run
```

---

## Usage Guide
1. **Register or log in:**
   - Choose your role (Parent, Child, Nanny) and set up your profile.
2. **Explore features:**
   - Use chat, manage passwords, send SOS, and more from the home screen.
3. **Messaging:**
   - Chat with the AI assistant or other users in real time.
   - See unread message badges and notifications.
4. **Password Backup:**
   - Store, export, and recover passwords securely.
5. **Emergency SOS:**
   - Send alerts, view on map, and clear your SOS log.

---

## Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

---

## License
[MIT](LICENSE)
