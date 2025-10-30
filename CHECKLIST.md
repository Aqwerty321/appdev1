# ✅ Firestore Integration Checklist

## 📋 Pre-Launch Checklist

Before running your app, make sure you've completed these steps:

### 🔥 Firebase Configuration

- [ ] **Firebase project created** at [console.firebase.google.com](https://console.firebase.google.com)
- [ ] **Blaze plan enabled** (required for Cloud Functions and external API calls)
- [ ] **Authentication enabled:**
  - Go to Authentication → Sign-in method
  - Enable "Email/Password"
- [ ] **Firestore Database created:**
  - Go to Firestore Database → Create database
  - Start in test mode (we'll apply rules next)
- [ ] **Storage bucket created:**
  - Go to Storage → Get started
  - Start in test mode
- [ ] **Cloud Functions enabled:**
  - Functions deploy successfully
  - See `findStudyBuddyMatches` and `getConversationStarters` in console

### 🛡️ Security Rules Applied

- [ ] **Firestore Security Rules:**
  - Go to Firestore Database → Rules tab
  - Copy rules from `SECURITY_RULES.md`
  - Click "Publish"
  - Wait for "Rules published successfully" message

- [ ] **Storage Security Rules:**
  - Go to Storage → Rules tab
  - Copy Storage rules from `SECURITY_RULES.md`
  - Click "Publish"
  - Wait for confirmation

### 🤖 AI Matchmaking Configuration

- [ ] **Gemini API key obtained:**
  - Get from [Google AI Studio](https://aistudio.google.com/app/apikey)
  - Free tier: 2M tokens/day
  
- [ ] **API key set in Firebase:**
  ```bash
  firebase functions:secrets:set GEMINI_API_KEY
  ```
  
- [ ] **Cloud Functions deployed:**
  ```bash
  cd functions
  npm install
  cd ..
  firebase deploy --only functions
  ```
  
- [ ] **Functions accessible:**
  - Test in Firebase Console → Functions
  - No errors in function logs

### 📱 App Configuration

- [ ] **Firebase config files present:**
  - `lib/firebase_options.dart` exists
  - `android/app/google-services.json` exists (for Android)
  - `ios/Runner/GoogleService-Info.plist` exists (for iOS)

- [ ] **Dependencies installed:**
  ```bash
  flutter pub get
  ```
  
- [ ] **Cloud Functions package added:**
  - `cloud_functions: ^6.0.1` in pubspec.yaml

- [ ] **No compilation errors:**
  ```bash
  flutter analyze --no-fatal-infos
  ```

---

## 🧪 Testing Checklist

### Phase 1: Authentication

- [ ] **App launches to login screen**
- [ ] **Sign up new account**
  - Email validation works
  - Password requirements enforced
  - Success message appears
- [ ] **Auto-redirect to main app** after signup
- [ ] **Check Firebase Console:**
  - Authentication → Users tab shows new user
  - Firestore → `users` collection has user document

### Phase 2: User Profile

- [ ] **Navigate to Profile screen**
- [ ] **Edit profile:**
  - Change name
  - Update bio
  - Add 3+ interests
- [ ] **Upload profile image:**
  - Select image
  - See loading spinner
  - Image appears in profile
- [ ] **Verify in Firebase Console:**
  - Firestore → `users/{uid}` → name/bio/interests updated
  - Storage → `profile_images/{uid}.jpg` exists

### Phase 3: AI Matchmaking

- [ ] **Navigate to Home screen (Discover Buddies)**
- [ ] **Check for AI indicator:**
  - Yellow loading circle appears (briefly)
  - Brain icon (🧠) appears when loaded
  - Hover shows "AI match scores loaded"
- [ ] **Check buddy cards:**
  - Each card shows "XX% Match"
  - Percentages are NOT all 0%
  - Scores range from 50-100%
- [ ] **Navigate to AI Matchmaking screen:**
  - Drawer → ✨ AI Matchmaking
  - See detailed match list with explanations
  - AI reasoning displayed for each match
- [ ] **Check browser console (F12):**
  - See "🚀 Fetching AI match scores..."
  - See "✅ Received X matches from AI service"
  - See "📊 AI Match: username (userId) = XX%"
  - No errors in console
- [ ] **Verify in Firebase Console:**
  - Functions → Logs show successful executions
  - No "Null check operator" errors

### Phase 4: Study Groups

- [ ] **Navigate to Study Groups tab**
- [ ] **Create new group:**
  - Fill name: "Test Group"
  - Fill description
  - Add topics (comma-separated)
  - Click Create
  - See loading spinner
  - Group appears in list
- [ ] **Verify in Firebase Console:**
  - Firestore → `study_groups` collection has new document
  - `memberUids` array contains your UID

### Phase 5: Multi-User Testing

**Open second browser/incognito:**

- [ ] **Create second user account**
- [ ] **Second user: Navigate to Study Groups**
- [ ] **Second user: Join first user's group**
- [ ] **First user: Refresh and see second user in members**
- [ ] **Verify in Firebase Console:**
  - `memberUids` array has both UIDs
  - `memberNames` array has both names

### Phase 6: Messaging

- [ ] **Both users: Open same group detail screen**
- [ ] **User 1: Send message "Hello!"**
- [ ] **Verify in Firebase Console:**
  - `study_groups/{id}/messages` subcollection has message
- [ ] **User 2: Navigate away and back to see message**
  - (Real-time update pending StreamBuilder integration)

### Phase 7: Message Features

- [ ] **Edit your own message:**
  - Click edit icon
  - Change text
  - See "edited" label
- [ ] **Add reaction:**
  - Click reaction trigger (emoji icon)
  - Select emoji
  - See reaction appear
- [ ] **Verify in Firebase Console:**
  - Message has `editedAt` timestamp
  - `reactions` array has your reaction

### Phase 8: Group Management

- [ ] **Leave group** (both users)
- [ ] **Verify in Firebase Console:**
  - Group document auto-deleted when empty

### Phase 9: Logout & Re-login

- [ ] **Click logout in drawer**
- [ ] **Redirected to login screen**
- [ ] **Log back in with same credentials**
- [ ] **Profile data persists**
- [ ] **Groups still visible**

---

## 🔍 Verification Points

### Firebase Console Checks

#### Authentication Tab
- [ ] User count matches created accounts
- [ ] Each user has a UID
- [ ] Email/Password provider shows "Enabled"

#### Firestore Database Tab
- [ ] `users` collection exists
- [ ] Each user has document with UID as ID
- [ ] User documents have:
  - name
  - email
  - bio
  - interests (array)
  - createdAt (timestamp)
- [ ] `study_groups` collection exists
- [ ] Group documents have:
  - name, description
  - topics (array)
  - memberNames (array)
  - memberUids (array)
  - createdAt (timestamp)
- [ ] Group messages subcollection has:
  - authorName, authorUid
  - content
  - timestamp
  - reactions (array)

#### Storage Tab
- [ ] `profile_images/` folder exists
- [ ] Each uploaded image has {uid}.jpg name
- [ ] Images downloadable (click to preview)

#### Usage Tab (Optional)
- [ ] Reads/writes incrementing
- [ ] Storage usage increasing

---

## 🐛 Common Issues & Fixes

### ❌ "Permission denied" on write

**Problem:** Security rules not applied  
**Fix:**
1. Copy rules from `SECURITY_RULES.md`
2. Go to Firebase Console → Rules tab
3. Paste and publish
4. Wait 30 seconds for propagation

### ❌ "User not found" on login

**Problem:** Trying to sign in with unregistered email  
**Fix:**
1. Toggle to "Sign Up" mode in login screen
2. Create account first
3. Then log in

### ❌ Image upload fails

**Problem:** Storage rules not configured or file too large  
**Fix:**
1. Apply Storage rules from `SECURITY_RULES.md`
2. Check image is < 5MB
3. Verify image format is JPG/PNG

### ❌ Messages don't appear immediately

**Status:** Known - StreamBuilder integration pending  
**Workaround:** Navigate away and back to refresh  
**Future Fix:** Wrap message list in StreamBuilder

### ❌ Group doesn't appear for second user

**Problem:** Not refreshing or not joined correctly  
**Fix:**
1. Check `memberUids` in Firestore Console
2. Ensure both UIDs in array
3. Refresh Study Groups screen

---

## 📊 Success Metrics

Your integration is **100% successful** if:

- ✅ All Phase 1-8 tests pass
- ✅ Firebase Console shows correct data structure
- ✅ Multi-user collaboration works
- ✅ Images upload and display
- ✅ Security rules prevent unauthorized access
- ✅ No compilation errors in `flutter analyze`

---

## 🎯 Optional Enhancements

After completing checklist:

- [ ] Add StreamBuilder to message board for real-time updates
- [ ] Implement session scheduling UI
- [ ] Add date separators in messages
- [ ] Enable Firestore offline persistence
- [ ] Add typing indicators
- [ ] Implement push notifications (FCM)
- [ ] Add message deletion
- [ ] Implement search across groups

---

## 📄 Documentation Quick Links

- **Setup Guide:** `FIRESTORE_SETUP.md`
- **Security Rules:** `SECURITY_RULES.md`
- **Testing Steps:** `TESTING_GUIDE.md`
- **Architecture:** `ARCHITECTURE.md`
- **Summary:** `README_INTEGRATION.md`

---

## ✅ Final Check

Before considering integration complete:

```bash
# 1. Run analysis
flutter analyze --no-fatal-infos

# Expected: 56 issues found (all info-level)
# No errors

# 2. Run app
flutter run -d chrome

# 3. Complete all testing phases above

# 4. Verify Firebase Console data structure

# 5. Test with second user

# 6. ✅ Integration complete!
```

---

**🎉 You're ready to launch!**

Once all checkboxes are ticked, your app has:
- Secure authentication
- Real-time multi-user features
- Cloud-backed data persistence
- Beautiful UI with consistent theming

**Happy coding! 🚀**
