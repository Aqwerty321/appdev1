# 🤖 AI Matchmaking Setup Guide

## Overview

This implementation adds **AI-powered study buddy matchmaking** using **Google's Gemini API** with secure backend architecture. Your API key is safely stored in Firebase Cloud Functions, never exposed to clients.

## Architecture

```
Flutter App (Client)
    ↓
    Calls Cloud Functions
    ↓
Firebase Cloud Functions (Server)
    ↓
    Uses secure GEMINI_API_KEY
    ↓
Google Gemini API
    ↓
    Returns AI matchmaking results
```

**Security Benefits:**
- ✅ API key stored server-side only
- ✅ No client-side API key exposure
- ✅ Firebase authentication required
- ✅ Rate limiting via Firebase quotas
- ✅ Usage monitoring in Firebase Console

---

## 🔧 Setup Steps

### 1. Get Your Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Click "Create API Key"
3. Copy your API key (keep it secret!)

### 2. Install Cloud Functions Dependencies

```bash
cd functions
npm install
```

### 3. Configure Firebase Secret

Store your Gemini API key securely in Firebase:

```bash
firebase functions:secrets:set GEMINI_API_KEY
```

When prompted, paste your Gemini API key.

### 4. Deploy Cloud Functions

```bash
firebase deploy --only functions
```

This deploys two functions:
- `findStudyBuddyMatches` - AI matchmaking
- `getConversationStarters` - Personalized icebreakers

### 5. Install Flutter Dependencies

```bash
flutter pub get
```

### 6. Update Firebase Security Rules (Optional but Recommended)

Add rate limiting to Firestore rules if you want to prevent abuse:

```javascript
// In firestore.rules
match /users/{userId} {
  allow read: if isSignedIn() && 
    request.time < resource.data.lastMatchRequest + duration.value(1, 'm');
  // ... other rules
}
```

---

## 🎯 How It Works

### AI Matchmaking Flow

1. **User opens AI Matchmaking screen**
2. **Client calls `findStudyBuddyMatches` Cloud Function** with:
   - User's interests
   - User's bio
3. **Cloud Function:**
   - Fetches all user profiles from Firestore
   - Sends data to Gemini API with custom prompt
   - Gemini analyzes compatibility based on:
     - Shared interests (weighted highest)
     - Complementary skills
     - Bio compatibility
     - Study style hints
4. **AI returns:**
   - Match score (0-100) for each candidate
   - Personalized explanation of why they match
5. **Client displays** ranked results with:
   - Match percentage
   - AI-generated reason
   - Profile preview

### Conversation Starters

1. **User taps on a matched buddy**
2. **Optional: Call `getConversationStarters`** with target user ID
3. **AI generates 4 personalized icebreakers** based on:
   - Shared interests
   - Both users' bios
   - Conversational tone
4. **User can use these to start a chat** (future feature)

---

## 📁 Files Added

### Backend (Cloud Functions)

- **`functions/package.json`** - Node.js dependencies
- **`functions/index.js`** - Cloud Functions implementation
  - `findStudyBuddyMatches()` - Main matchmaking function
  - `getConversationStarters()` - Icebreaker generator
- **`functions/.eslintrc.js`** - Linting config
- **`functions/.gitignore`** - Keep secrets out of git

### Frontend (Flutter)

- **`lib/ai_matchmaking_service.dart`** - Service layer for Cloud Functions
  - `findMatches()` - Call matchmaking function
  - `getConversationStarters()` - Get icebreakers
  - `AiMatchedBuddy` model
- **`lib/ai_matchmaking_screen.dart`** - UI for displaying matches
  - Color-coded match scores
  - AI reasoning display
  - Profile preview cards
- **Updated `lib/home.dart`** - Added navigation to AI Matchmaking

### Configuration

- **Updated `firebase.json`** - Functions deployment config
- **Updated `pubspec.yaml`** - Added `cloud_functions` dependency

---

## 🎨 UI Features

### Match Score Colors

- 🟢 **80-100%**: Success Green (0xFF00FF94) - Excellent match
- 🔵 **60-79%**: Bright Cyan (0xFF00D9FF) - Good match
- 🟣 **50-59%**: Vibrant Purple (0xFFB366FF) - Decent match

### AI Reasoning Display

Each match shows a light bulb icon with AI-generated explanation:
- "Shared passion for Flutter and web development"
- "Your interests in machine learning align perfectly"
- "Complementary skills - you can learn from each other"

---

## 💰 Cost Considerations

### Gemini API Pricing (as of 2024)

**Gemini 1.5 Flash** (used in this implementation):
- First 2 million tokens/day: **FREE**
- After that: $0.35 per 1M input tokens

**Estimated Usage:**
- ~1,000 tokens per matchmaking request
- ~500 tokens per conversation starters request
- **2000 free matchmaking calls per day** before charges

### Firebase Cloud Functions Pricing

**Free Tier (Spark Plan):**
- 2M invocations/month
- 400K GB-seconds, 200K GHz-seconds

**Blaze Plan (Pay-as-you-go):**
- $0.40 per 1M invocations
- Your current deployment should stay in free tier

---

## 🧪 Testing

### Test AI Matchmaking

1. **Build and deploy:**
   ```bash
   flutter build web
   firebase deploy
   ```

2. **Open your app** and log in

3. **Create test users** with varied interests:
   - User 1: #flutter #firebase #webdev
   - User 2: #flutter #dart #mobiledev
   - User 3: #python #machinelearning #ai

4. **Navigate to AI Matchmaking** from drawer

5. **Verify:**
   - Loading spinner appears
   - Match scores calculated
   - AI reasons are meaningful
   - Clicking opens profile

### Test Conversation Starters (Optional)

Add a button in `buddy_profile_screen.dart`:

```dart
ElevatedButton.icon(
  onPressed: () async {
    final starters = await AiMatchmakingService()
        .getConversationStarters(userId);
    // Show in dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Icebreakers'),
        content: Column(
          children: starters.map((s) => Text('• $s')).toList(),
        ),
      ),
    );
  },
  icon: Icon(Icons.chat),
  label: Text('Get Icebreakers'),
)
```

---

## 🔍 Monitoring

### Firebase Console

**Functions Dashboard:**
- Track invocation count
- Monitor execution time
- Check error rates

**Logs:**
```bash
firebase functions:log
```

**Real-time logs:**
```bash
firebase functions:log --follow
```

### Check Secret Configuration

```bash
firebase functions:secrets:access GEMINI_API_KEY
```

---

## 🚨 Troubleshooting

### "Permission denied" when calling function

**Solution:** Ensure user is authenticated:
```dart
// Check if user is logged in
if (FirebaseAuth.instance.currentUser == null) {
  print('User not authenticated');
}
```

### "Secret GEMINI_API_KEY not found"

**Solution:** Set the secret:
```bash
firebase functions:secrets:set GEMINI_API_KEY
firebase deploy --only functions
```

### "Failed to parse AI matchmaking results"

**Cause:** Gemini response wasn't valid JSON

**Solution:** Already handled with fallback logic. Check logs:
```bash
firebase functions:log
```

### Cloud Functions not deploying

**Solution:** Check Node.js version:
```bash
node --version  # Should be 18 or higher
```

Update if needed:
```bash
nvm install 18
nvm use 18
```

---

## 🎯 Future Enhancements

### Immediate (Easy)

- ✅ Add conversation starters to profile screen
- ✅ Cache match results for 1 hour
- ✅ Add pull-to-refresh on matchmaking screen

### Short-term (Medium)

- 🔄 Real-time match notifications
- 🔄 "Super like" feature for top matches
- 🔄 Filter by match score threshold
- 🔄 Save favorite matches

### Long-term (Advanced)

- 🚀 Collaborative filtering (learn from user interactions)
- 🚀 Schedule compatibility matching
- 🚀 Group study recommendations
- 🚀 Multi-language support via Gemini
- 🚀 Video call matching via WebRTC

---

## 📊 Sample Gemini Prompt

Here's what we send to Gemini:

```
You are a study buddy matchmaking assistant. Analyze the following user profile and candidate profiles to suggest the best study matches.

Current User Profile:
- Interests: flutter, firebase, webdev
- Bio: Passionate about building modern web apps

Candidate Profiles:
1. Alice
   - Interests: flutter, dart, mobiledev
   - Bio: Learning Flutter for mobile development

2. Bob
   - Interests: python, ai, machinelearning
   - Bio: Data science enthusiast

For each candidate, provide a match score (0-100) and explanation...
```

**Gemini Response:**
```json
{
  "matches": [
    {
      "candidateIndex": 0,
      "score": 85,
      "reason": "Strong overlap in Flutter and mobile development interests..."
    },
    {
      "candidateIndex": 1,
      "score": 45,
      "reason": "Different tech stacks but complementary..."
    }
  ]
}
```

---

## 🔐 Security Best Practices

1. **Never commit API keys** - Always use Firebase secrets
2. **Validate input** - Cloud Functions validate user auth
3. **Rate limiting** - Firebase handles this automatically
4. **Error handling** - All functions have try-catch blocks
5. **HTTPS only** - Cloud Functions enforce secure connections

---

## 📚 Additional Resources

- [Gemini API Documentation](https://ai.google.dev/docs)
- [Firebase Cloud Functions Guide](https://firebase.google.com/docs/functions)
- [Firebase Secrets Management](https://firebase.google.com/docs/functions/config-env#secret-manager)
- [Cloud Functions Pricing](https://firebase.google.com/pricing)

---

**Ready to match! 🎉**

Your users can now discover study buddies powered by AI. The system is secure, scalable, and cost-effective.
