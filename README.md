# StudyBuddy App 📚

A Flutter web application for finding study partners, forming study groups, and collaborating with fellow students in real-time.

## 🌟 Features

### User Management
- **Firebase Authentication** - Secure email/password authentication
- **Profile Customization** - Upload profile pictures, write bio, add interests
- **Real-time Sync** - All user data synced with Firestore

### AI-Powered Matchmaking 🤖
- **Smart Compatibility Scoring** - Google Gemini AI analyzes profiles to calculate 50-100% match scores
- **Personalized Match Insights** - AI-generated explanations for why users are compatible
- **Intelligent Recommendations** - Discover study buddies based on shared interests and complementary skills
- **Conversation Starters** - AI-suggested icebreakers for each match
- **Match Score Display** - Real-time percentage display on all buddy cards

### Study Buddy Discovery
- **Discover Buddies** - Browse all registered users with AI match percentages
- **Find by Interest** - Filter users by shared interests and tags
- **Interest Tags** - Dynamic tag system with popular and all tags sections
- **Profile Views** - View detailed profiles with compatibility insights

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
  - Firebase Cloud Functions (Node.js 20)
  - Firebase Secret Manager
- **AI/ML**: Google Gemini API (gemini-2.0-flash-exp)
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
├── ai_matchmaking_service.dart    # AI matchmaking API client
├── home.dart                      # Home screen with AI match scores
├── profile_screen.dart            # User's own profile
├── buddy_profile_screen.dart      # Other users' profiles
├── edit_profile_screen.dart       # Profile editing
├── ai_matchmaking_screen.dart     # AI matchmaking results screen
├── study_groups_screen.dart       # Study groups list
├── study_group_detail_screen.dart # Group chat and details
└── widgets/
    ├── image_uploader.dart        # Profile image upload
    ├── neon_border_tile.dart      # Custom styled containers
    └── interest_chip.dart         # Tag/interest chips

functions/
├── index.js                       # Cloud Functions (AI proxy)
├── package.json                   # Node.js dependencies
└── .env                           # Environment variables
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
   - Enable Cloud Functions (Blaze plan required for external API calls)
   - Download `google-services.json` and place in `android/app/`
   - Run `flutterfire configure` to generate `lib/firebase_options.dart`

4. **AI Matchmaking Setup**
   ```bash
   # Get Gemini API key from https://aistudio.google.com/app/apikey
   
   # Set API key in Firebase Secret Manager
   firebase functions:secrets:set GEMINI_API_KEY
   
   # Install Cloud Functions dependencies
   cd functions
   npm install
   cd ..
   
   # Deploy Cloud Functions
   firebase deploy --only functions
   ```
   
   See [AI_MATCHMAKING_SETUP.md](AI_MATCHMAKING_SETUP.md) for detailed instructions.

5. **Configure Firebase Storage CORS**
   ```bash
   # Install Google Cloud SDK
   # Authenticate
   gcloud auth login
   
   # Apply CORS configuration
   gsutil cors set cors.json gs://your-project.firebasestorage.app
   ```

6. **Deploy Firestore Rules**
   ```bash
   firebase deploy --only firestore
   ```

7. **Deploy Storage Rules**
   ```bash
   firebase deploy --only storage
   ```

8. **Run the app**
   ```bash
   flutter run -d chrome
   ```

9. **Build for production**
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

### AI Matchmaking
- **Gemini-Powered Analysis**: Uses Google's Gemini 2.0 Flash model to analyze user profiles
- **Smart Caching**: Match scores cached for 30 minutes to optimize API usage
- **Real-time Display**: AI match percentages shown on all buddy discovery cards
- **Color-Coded Scores**: Green (80-100%), Cyan (60-79%), Purple (50-59%)
- **Secure Architecture**: API keys protected via Firebase Cloud Functions proxy

### Real-time Updates
All data updates instantly using Firestore streams:
- New messages appear immediately
- Group member changes sync in real-time
- Profile updates reflect across all users
- Study session updates are live
- AI match scores refresh automatically

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
