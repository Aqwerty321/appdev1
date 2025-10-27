# StudyBuddy App 📚

A Flutter web application for finding study partners, forming study groups, and collaborating with fellow students in real-time.

## 🌟 Features

### User Management
- **Firebase Authentication** - Secure email/password authentication
- **Profile Customization** - Upload profile pictures, write bio, add interests
- **Real-time Sync** - All user data synced with Firestore

### Study Buddy Discovery
- **Discover Buddies** - Browse all registered users
- **Find by Interest** - Filter users by shared interests and tags
- **Interest Tags** - Dynamic tag system with popular and all tags sections
- **Profile Views** - View detailed profiles of other users

### Study Groups
- **Create Groups** - Form study groups with custom topics
- **Real-time Chat** - Message board with reactions and edit functionality
- **Member Management** - Admin controls for adding/removing members
- **Sessions Scheduling** - Plan and track study sessions
- **Pinned Links** - Share important resources
- **Topic Editing** - Admins can modify group topics

### Admin Features
- Add members by name or email
- Remove members from groups
- Promote members to admin
- Edit group topics
- Pin important URLs
- Schedule study sessions

## 🚀 Live Demo

[https://studybuddyapp-309d8.web.app](https://studybuddyapp-309d8.web.app)

## 🛠️ Tech Stack

- **Frontend**: Flutter (Web)
- **Backend**: Firebase
  - Firebase Authentication
  - Cloud Firestore (Database)
  - Firebase Storage (Profile images)
  - Firebase Hosting
- **State Management**: StreamBuilder (Real-time updates)
- **Design**: Custom neon/dark blue theme

## 📦 Project Structure

```
lib/
├── main.dart                      # App entry point
├── auth_service.dart              # Authentication logic
├── auth_wrapper.dart              # Auth state management
├── firestore_service.dart         # Firestore CRUD operations
├── user_data_service.dart         # Local user data management
├── home.dart                      # Home screen with buddy discovery
├── profile_screen.dart            # User's own profile
├── buddy_profile_screen.dart      # Other users' profiles
├── edit_profile_screen.dart       # Profile editing
├── study_groups_screen.dart       # Study groups list
├── study_group_detail_screen.dart # Group chat and details
└── widgets/
    ├── image_uploader.dart        # Profile image upload
    ├── neon_border_tile.dart      # Custom styled containers
    └── interest_chip.dart         # Tag/interest chips
```

## 🔧 Setup Instructions

### Prerequisites
- Flutter SDK (latest stable)
- Firebase account
- Google Cloud SDK (for CORS configuration)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/studybuddy-app.git
   cd studybuddy-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication (Email/Password)
   - Enable Firestore Database
   - Enable Firebase Storage
   - Download `google-services.json` and place in `android/app/`
   - Run `flutterfire configure` to generate `lib/firebase_options.dart`

4. **Configure Firebase Storage CORS**
   ```bash
   # Install Google Cloud SDK
   # Authenticate
   gcloud auth login
   
   # Apply CORS configuration
   gsutil cors set cors.json gs://your-project.firebasestorage.app
   ```

5. **Deploy Firestore Rules**
   ```bash
   firebase deploy --only firestore
   ```

6. **Deploy Storage Rules**
   ```bash
   firebase deploy --only storage
   ```

7. **Run the app**
   ```bash
   flutter run -d chrome
   ```

8. **Build for production**
   ```bash
   flutter build web
   firebase deploy --only hosting
   ```

## 🔐 Security Rules

### Firestore Rules (`firestore.rules`)
- Users can read/write their own profile
- Users can read all profiles (for buddy discovery)
- Study group members can read/write group data
- Admins have additional permissions for member management

### Storage Rules (`storage.rules`)
- Profile images are publicly readable
- Only authenticated users can upload images
- Max file size: 5MB
- Only image files allowed

## 🎨 Design Theme

- **Primary Color**: Dark Blue (#13233F)
- **Accent Color**: Neon Purple (#986AF0)
- **Highlight Color**: Light Blue (#81A7EE)
- **Style**: Dark mode with neon accents and gradient effects

## 📱 Features in Detail

### Real-time Updates
All data updates instantly using Firestore streams:
- New messages appear immediately
- Group member changes sync in real-time
- Profile updates reflect across all users
- Study session updates are live

### Image Upload
- Profile pictures stored in Firebase Storage
- Automatic compression and optimization
- Cached for performance
- Fallback placeholder icons

### Search & Discovery
- Tag-based filtering
- Popular tags section
- Interest matching algorithm
- Real-time user search

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 👨‍💻 Author

Created with ❤️ for students everywhere

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend infrastructure
- Community for icons and assets
