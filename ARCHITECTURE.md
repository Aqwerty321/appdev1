# 🔄 Firestore Integration - Data Flow Architecture

## 📱 Application Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         YOUR FLUTTER APP                        │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                        │                        │
        ▼                        ▼                        ▼
┌──────────────┐        ┌──────────────┐        ┌──────────────────┐
│ AuthService  │        │UserDataService│       │AiMatchmakingService│
│              │        │              │        │                  │
│ • signIn()   │        │ • currentUser│        │ • findMatches()  │
│ • signUp()   │        │ • allGroups  │        │ • getStarters()  │
│ • signOut()  │        │ • myGroups   │        │ (AI proxy)       │
│ • resetPwd() │        │ (local cache)│        └────────┬─────────┘
└──────┬───────┘        └──────┬───────┘                 │
       │                       │                         │
       │         ┌─────────────┼─────────────────────────┘
       │         │             │
       │         ▼             ▼
       │  ┌────────────────────────┐
       └─▶│  FirestoreService      │
          │                        │
          │  Real-time Data Layer  │
          └───────────┬────────────┘
                      │
                      │
        ┌─────────────┼──────────────────────┐
        │             │                      │
        ▼             ▼                      ▼
┌──────────────┐ ┌──────────────┐  ┌─────────────────┐
│   Firebase   │ │  Firestore   │  │     Storage     │
│     Auth     │ │   Database   │  │    (Images)     │
└──────────────┘ └──────────────┘  └─────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────┐
│            Firebase Cloud Functions                  │
│  ┌────────────────────────────────────────────┐     │
│  │  findStudyBuddyMatches()                   │     │
│  │  • Fetch all users from Firestore          │     │
│  │  • Send to Gemini AI for analysis          │     │
│  │  • Return match scores + reasoning         │     │
│  └────────────┬───────────────────────────────┘     │
│               │                                      │
│  ┌────────────▼───────────────────────────────┐     │
│  │  getConversationStarters()                 │     │
│  │  • Get user profiles                       │     │
│  │  • Generate icebreakers via Gemini         │     │
│  └────────────────────────────────────────────┘     │
└──────────────────────┬───────────────────────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │  Google Gemini  │
              │  API (2.0-flash)│
              │  Secret: GEMINI │
              │  _API_KEY       │
              └─────────────────┘
```

---

## 🔐 Authentication Flow

```
User Opens App
      │
      ▼
┌─────────────────┐
│  AuthWrapper    │ ← Listens to auth state changes
│  (StreamBuilder)│
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
Not Auth    Authenticated
    │         │
    ▼         ▼
┌──────┐  ┌─────────────────┐
│Login │  │ Initialize User │
│Screen│  │ Profile from    │
└──────┘  │ Firestore       │
             │               │
             ▼               │
          ┌─────────────┐   │
          │ HomeScreen  │◀──┘
          └─────────────┘
```

**Code Path:**
1. `main.dart` → `AuthWrapper`
2. `AuthWrapper` checks `FirebaseAuth.authStateChanges`
3. If logged in → `_initializeUserData()` → Load from Firestore
4. Sync to `UserDataService.currentUser`
5. Navigate to `HomeScreen`

---

## 👤 Profile Update Flow

```
User Edits Profile
      │
      ▼
┌────────────────────┐
│ EditProfileScreen  │
│ • Update local     │
│ • _saveChanges()   │
└─────────┬──────────┘
          │
          ▼
┌──────────────────────────┐
│ UserDataService          │
│ .updateUserData()        │
│ (updates local cache)    │
└─────────┬────────────────┘
          │
          ▼
┌──────────────────────────┐
│ FirestoreService         │
│ .saveUserProfile()       │
│ (writes to Firestore)    │
└─────────┬────────────────┘
          │
          ├──── If image changed ────┐
          │                           │
          ▼                           ▼
┌──────────────────┐        ┌──────────────────┐
│ Firestore DB     │        │ Firebase Storage │
│ users/{uid}      │        │ profile_images/  │
│ • name           │        │ {uid}.jpg        │
│ • bio            │        └──────────────────┘
│ • interests      │
│ • imageUrl       │
└──────────────────┘
```

---

## 👥 Study Group Creation Flow

```
User Creates Group
      │
      ▼
┌──────────────────────┐
│ StudyGroupsScreen    │
│ • Fill form          │
│ • _createGroup()     │
└─────────┬────────────┘
          │
          ▼
┌──────────────────────────┐
│ FirestoreService         │
│ .createGroup()           │
│ • Generate doc ID        │
│ • Add creator as member  │
└─────────┬────────────────┘
          │
          ▼
┌─────────────────────────────────┐
│ Firestore DB                    │
│ study_groups/{groupId}          │
│ • name, description             │
│ • topics                        │
│ • memberNames: [currentUser]    │
│ • memberUids: [currentUserUid]  │
│ • createdBy, createdAt          │
└─────────┬───────────────────────┘
          │
          │ Real-time update via StreamBuilder
          ▼
┌──────────────────────┐
│ StudyGroupsScreen    │
│ StreamBuilder        │
│ .watchMyGroups()     │
│ → UI auto-updates    │
└──────────────────────┘
```

---

## 💬 Message Sending Flow

```
User Types Message
      │
      ▼
┌──────────────────────────┐
│ StudyGroupDetailScreen   │
│ • TextField              │
│ • _sendMessage()         │
└─────────┬────────────────┘
          │
          ▼
┌──────────────────────────┐
│ FirestoreService         │
│ .sendMessage()           │
│ • groupId, content       │
└─────────┬────────────────┘
          │
          ▼
┌────────────────────────────────────────┐
│ Firestore DB                           │
│ study_groups/{groupId}/messages/       │
│   {messageId}/                         │
│     • authorName, authorUid            │
│     • content                          │
│     • timestamp (server timestamp)     │
│     • reactions: []                    │
└─────────┬──────────────────────────────┘
          │
          │ (Currently: manual refresh)
          │ (Future: StreamBuilder auto-update)
          ▼
┌──────────────────────────┐
│ Message appears in UI    │
└──────────────────────────┘
```

---

## 🤖 AI Matchmaking Flow

```
User Opens Home Screen
      │
      ▼
┌──────────────────────────┐
│ HomeScreen._initState()  │
│ • Fetch match scores     │
│ • Cache for 30 minutes   │
└─────────┬────────────────┘
          │
          ▼
┌──────────────────────────────┐
│ AiMatchmakingService         │
│ .findMatches()               │
│ • interests: Set<String>     │
│ • bio: String                │
└─────────┬────────────────────┘
          │
          │ HTTPS Callable
          ▼
┌─────────────────────────────────────────────────┐
│ Firebase Cloud Function                         │
│ findStudyBuddyMatches(interests, bio)           │
│                                                 │
│ 1. Fetch all users from Firestore              │
│    const usersSnapshot = await db               │
│      .collection('users').get()                 │
│                                                 │
│ 2. Build AI prompt with user data               │
│    "Analyze compatibility between users..."     │
│                                                 │
│ 3. Call Gemini API                              │
│    const model = genAI.getGenerativeModel()     │
│    const result = await model.generateContent() │
│                                                 │
│ 4. Parse JSON response                          │
│    { matches: [{userId, score, reason}] }       │
│                                                 │
│ 5. Filter matches >= 50%                        │
└─────────┬───────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────┐
│ Google Gemini API               │
│ (gemini-2.0-flash-exp)          │
│                                 │
│ • Analyzes interests overlap    │
│ • Evaluates bio compatibility   │
│ • Identifies complementary skills│
│ • Returns 0-100% match scores   │
│ • Generates personalized reasons│
└─────────┬───────────────────────┘
          │
          │ JSON Response
          ▼
┌──────────────────────────────────────┐
│ Flutter App (HomeScreen)             │
│                                      │
│ _matchScores = {                     │
│   "userId1": 95,                     │
│   "userId2": 88,                     │
│   "userId3": 60                      │
│ }                                    │
│                                      │
│ Display on buddy cards:              │
│ • 95% Match (Green)                  │
│ • 88% Match (Cyan)                   │
│ • 60% Match (Cyan)                   │
└──────────────────────────────────────┘
```

**Security:**
- ✅ API key stored in Firebase Secret Manager
- ✅ Cloud Function acts as secure proxy
- ✅ Client never sees Gemini API key
- ✅ Authenticated users only

---

## 🔥 Real-Time Sync (StreamBuilder)

```
┌───────────────────────────────────────────────────────┐
│                   Flutter Widget                      │
│                                                       │
│  StreamBuilder<List<StudyGroup>>(                    │
│    stream: FirestoreService().watchMyGroups(),       │
│    builder: (context, snapshot) {                    │
│      final groups = snapshot.data ?? [];             │
│      // Build UI with groups                         │
│    }                                                  │
│  )                                                    │
└─────────────────────────┬─────────────────────────────┘
                          │
                          │ Listens continuously
                          ▼
            ┌──────────────────────────┐
            │  Firestore Database      │
            │  .snapshots()            │
            │                          │
            │  Emits new data when:    │
            │  • Document added        │
            │  • Document updated      │
            │  • Document deleted      │
            └──────────┬───────────────┘
                       │
                       │ Auto-triggers rebuild
                       ▼
            ┌──────────────────────────┐
            │  Flutter Widget          │
            │  → UI updates instantly  │
            └──────────────────────────┘
```

**Active StreamBuilders:**
- ✅ `StudyGroupsScreen` → `watchMyGroups()`
- ⏳ `StudyGroupDetailScreen` messages (pending)
- ⏳ Sessions list (pending)

---

## 📸 Image Upload Flow

```
User Selects Image
      │
      ▼
┌──────────────────────┐
│ EditProfileScreen    │
│ • ImagePicker        │
│ • Uint8List          │
└─────────┬────────────┘
          │
          ▼
┌──────────────────────────┐
│ FirestoreService         │
│ .uploadProfileImage()    │
│ • Compress to JPEG       │
└─────────┬────────────────┘
          │
          ▼
┌────────────────────────────────────┐
│ Firebase Storage                   │
│ PUT profile_images/{uid}.jpg       │
│ • Max 5MB                          │
│ • Content-Type: image/jpeg         │
└─────────┬──────────────────────────┘
          │
          │ Get download URL
          ▼
┌────────────────────────────────────┐
│ Update Firestore                   │
│ users/{uid}                        │
│   imageUrl: "https://..."          │
└────────────────────────────────────┘
```

---

## 🔒 Security Rules Flow

```
Client Request
      │
      ▼
┌────────────────────────┐
│ Firestore/Storage      │
│ Security Rules         │
└────────┬───────────────┘
         │
    ┌────┴────┐
    │         │
  ALLOW     DENY
    │         │
    ▼         ▼
┌────────┐ ┌──────────┐
│Execute │ │ Return   │
│Request │ │ Error    │
└────────┘ └──────────┘
```

**Rule Checks:**
1. Is user authenticated?
2. Does UID match resource owner?
3. Is user in group's `memberUids`?
4. Is file size < 5MB?
5. Is content type valid?

---

## 📊 Data Consistency

```
┌─────────────────────────────────────────────────────────┐
│              Multi-User Scenario                        │
└─────────────────────────────────────────────────────────┘

User A's Device          Firestore Cloud         User B's Device
      │                        │                        │
      │  Create group "AI"     │                        │
      ├───────────────────────▶│                        │
      │                        │                        │
      │                        │   StreamBuilder        │
      │                        │   detects change       │
      │                        ├───────────────────────▶│
      │                        │                        │
      │                        │                 UI updates
      │                        │                 (new group)
      │                        │                        │
      │                        │  User B joins group    │
      │                        │◀───────────────────────┤
      │                        │                        │
      │  StreamBuilder         │                        │
      │  detects change        │                        │
      │◀───────────────────────│                        │
      │                        │                        │
  UI updates                   │                        │
  (B added to members)         │                        │
```

---

## 🎯 Key Takeaways

1. **AuthWrapper** controls app navigation based on auth state
2. **FirestoreService** is the single source of truth for all database operations
3. **UserDataService** acts as a local cache for fast UI access
4. **StreamBuilder** enables real-time updates without manual refresh
5. **Security Rules** enforce access control at the database level
6. **All writes are async** - UI shows loading states during operations

---

## 🚀 Performance Optimizations

- ✅ **Local cache** via UserDataService for instant UI
- ✅ **Firestore indexes** auto-created for queries
- ✅ **Server timestamps** ensure consistency
- ✅ **Array operations** (add/remove members) are atomic
- ⏳ **Offline persistence** (can be enabled in Firestore)

---

**This architecture ensures:**
- Real-time collaboration
- Data consistency across devices
- Secure access control
- Scalable performance
- Smooth user experience

🎉 **Ready for production!**
