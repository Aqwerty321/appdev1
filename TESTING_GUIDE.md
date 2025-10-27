# 🚀 Quick Start - Testing Firestore Integration

## Before You Begin

Make sure you have:
- ✅ Firebase project created
- ✅ `firebase_options.dart` file exists
- ✅ `google-services.json` (Android) configured
- ✅ Security rules applied (see `SECURITY_RULES.md`)

---

## 🧪 Testing Steps

### 1️⃣ First Launch & Authentication

```bash
flutter run -d chrome
```

**What to test:**
- [ ] Login screen appears on first launch
- [ ] Create new account with email/password
- [ ] Verify login redirects to main app
- [ ] Check Firebase Console → Authentication → Users (your account should appear)

**Expected Firestore Data Created:**
```
users/{your-uid}/
  ├─ name: "user" (from email prefix)
  ├─ email: "your@email.com"
  ├─ bio: ""
  ├─ interests: []
  ├─ createdAt: [timestamp]
  └─ updatedAt: [timestamp]
```

---

### 2️⃣ Profile Management

**Navigate to:** Profile Screen → Edit Profile

**What to test:**
- [ ] Edit your name and bio
- [ ] Add interests (e.g., #flutter, #firebase, #webdev)
- [ ] Upload a profile picture
- [ ] Click "Save Changes" (should show loading spinner)
- [ ] Return to profile screen (changes should persist)

**Verify in Firebase Console:**
- Go to Firestore Database → `users` → `{your-uid}`
- Check that name, bio, interests updated
- Go to Storage → `profile_images`
- Verify your image uploaded as `{your-uid}.jpg`

---

### 3️⃣ Study Group Creation (Single User)

**Navigate to:** Study Groups tab

**What to test:**
- [ ] Click "+" to create group
- [ ] Fill in:
  - Name: "Flutter Study Group"
  - Description: "Learning Flutter together"
  - Topics: "flutter, dart, mobile"
- [ ] Click "Create" (should show loading spinner)
- [ ] Group appears in your list immediately

**Verify in Firestore:**
```
study_groups/{group-id}/
  ├─ name: "Flutter Study Group"
  ├─ description: "Learning Flutter together"
  ├─ topics: ["flutter", "dart", "mobile"]
  ├─ memberNames: ["your-name"]
  ├─ memberUids: ["{your-uid}"]
  ├─ createdBy: "your-name"
  ├─ createdByUid: "{your-uid}"
  └─ createdAt: [timestamp]
```

---

### 4️⃣ Real-Time Multi-User Testing

**Open second browser/device:**

1. **Device 1:** Create account as "Alice"
2. **Device 2:** Create account as "Bob"
3. **Device 1 (Alice):** Create a study group "AI Research"
4. **Device 2 (Bob):** 
   - Navigate to Study Groups
   - Find "AI Research" in suggested groups
   - Click to join
5. **Device 1 (Alice):**
   - Open "AI Research" group
   - You should see Bob in the members list (real-time!)

**Verify in Firestore:**
```
study_groups/{ai-research-id}/
  ├─ memberNames: ["Alice", "Bob"]
  └─ memberUids: ["{alice-uid}", "{bob-uid}"]
```

---

### 5️⃣ Real-Time Messaging

**With both users in same group:**

1. **Device 1 (Alice):** Send message "Hello, Bob!"
2. **Device 2 (Bob):** 
   - Navigate to group detail screen
   - Message should appear instantly (if StreamBuilder connected)
   - Currently needs manual refresh - message saved to Firestore but UI update pending

**Send from Device 2 (Bob):** "Hi Alice!"

**Verify in Firestore:**
```
study_groups/{group-id}/messages/
  ├─ {message-1-id}/
  │   ├─ authorName: "Alice"
  │   ├─ authorUid: "{alice-uid}"
  │   ├─ content: "Hello, Bob!"
  │   └─ timestamp: [timestamp]
  └─ {message-2-id}/
      ├─ authorName: "Bob"
      ├─ authorUid: "{bob-uid}"
      ├─ content: "Hi Alice!"
      └─ timestamp: [timestamp]
```

---

### 6️⃣ Message Editing & Reactions

**As message author:**

1. Click edit icon on your message
2. Change text to "Hello, Bob! 👋"
3. Save
4. Verify "edited" label appears

**Add reaction:**
1. Click reaction trigger (emoji icon)
2. Select emoji (👍, 🔥, or 🎯)
3. Reaction appears below message

**Verify in Firestore:**
```
messages/{message-id}/
  ├─ content: "Hello, Bob! 👋"
  ├─ editedAt: [timestamp]
  └─ reactions: [
      {
        userName: "Bob",
        userUid: "{bob-uid}",
        type: "👍"
      }
    ]
```

---

### 7️⃣ Leave Group & Auto-Delete

**Test group cleanup:**

1. **Device 1 (Alice):** Leave the group
2. **Device 2 (Bob):** Leave the group
3. Check Firestore → The group document should be deleted automatically

---

## 🐛 Common Issues

### "Permission denied" error

**Cause:** Security rules not applied or incorrect  
**Fix:** 
1. Go to Firebase Console → Firestore → Rules
2. Copy rules from `SECURITY_RULES.md`
3. Click "Publish"

### Profile image not uploading

**Cause:** Storage rules not configured  
**Fix:**
1. Go to Firebase Console → Storage → Rules
2. Copy Storage rules from `SECURITY_RULES.md`
3. Click "Publish"

### Messages not appearing in real-time

**Current Status:** Messages save to Firestore correctly, but detail screen needs StreamBuilder wrapper for live updates.

**Workaround:** Navigate away and back to group to refresh

**Future Fix:** Wrap message list in StreamBuilder (see `FIRESTORE_SETUP.md`)

### "User not found" on login

**Cause:** Creating account instead of logging in  
**Fix:** Toggle "Sign Up" mode in login screen

---

## 📊 Success Criteria

Your integration is working if:

- ✅ User profiles save to Firestore
- ✅ Profile images upload to Storage
- ✅ Study groups appear in Firestore
- ✅ Multiple users can join same group
- ✅ Messages save to Firestore subcollection
- ✅ Reactions update message arrays
- ✅ Empty groups auto-delete
- ✅ Edit profile reflects in Firestore
- ✅ Logout clears auth state

---

## 🎯 Next Steps

Once basic testing passes:

1. **Enable real-time message updates** - Add StreamBuilder to message board
2. **Add session UI** - StreamBuilder for scheduled sessions
3. **Implement buddy discovery** - Share profiles for matching
4. **Add push notifications** - Firebase Cloud Messaging
5. **Offline support** - Enable Firestore persistence

---

## 📸 What to Check in Firebase Console

### Authentication Tab
- Number of users matches accounts created
- Email/password provider enabled
- UIDs match Firestore user documents

### Firestore Database Tab
- `users` collection has one doc per user
- `study_groups` collection has created groups
- `study_groups/{id}/messages` subcollections have messages
- `memberUids` arrays update on join/leave

### Storage Tab
- `profile_images/` folder contains uploaded images
- Image names match user UIDs

### Usage Tab
- Reads/writes incrementing (shows activity)
- Storage usage increasing with image uploads

---

**Happy testing! 🎉** Report any issues and check `FIRESTORE_SETUP.md` for detailed architecture info.
