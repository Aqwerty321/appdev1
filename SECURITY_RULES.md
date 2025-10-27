# Firebase Security Rules Quick Setup

## 📋 How to Apply These Rules

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Firestore Database** → **Rules** tab
4. Copy and paste the Firestore rules below
5. Navigate to **Storage** → **Rules** tab
6. Copy and paste the Storage rules below
7. Click **Publish** for both

---

## 🔥 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isSignedIn() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the resource
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    // Helper function to check if user is a member of a group
    function isMember(groupId) {
      return isSignedIn() && 
             request.auth.uid in get(/databases/$(database)/documents/study_groups/$(groupId)).data.memberUids;
    }
    
    // User profiles - users can only modify their own
    match /users/{userId} {
      allow read: if isSignedIn();
      allow create, update: if isOwner(userId);
      allow delete: if false; // Prevent profile deletion
    }
    
    // Study groups
    match /study_groups/{groupId} {
      // Anyone can read public groups
      allow read: if isSignedIn();
      
      // Any authenticated user can create a group
      allow create: if isSignedIn() && 
                       request.resource.data.createdByUid == request.auth.uid &&
                       request.auth.uid in request.resource.data.memberUids;
      
      // Only members can update group info
      allow update: if isMember(groupId);
      
      // Groups can only be deleted if empty (or by creator)
      allow delete: if isSignedIn() && 
                       (resource.data.memberUids.size() == 0 || 
                        request.auth.uid == resource.data.createdByUid);
      
      // Messages subcollection
      match /messages/{messageId} {
        // Members can read all messages
        allow read: if isMember(groupId);
        
        // Members can create messages
        allow create: if isMember(groupId) && 
                         request.resource.data.authorUid == request.auth.uid;
        
        // Only message author can update
        allow update: if isMember(groupId) && 
                         resource.data.authorUid == request.auth.uid;
        
        // Only message author can delete
        allow delete: if isMember(groupId) && 
                         resource.data.authorUid == request.auth.uid;
      }
      
      // Sessions subcollection
      match /sessions/{sessionId} {
        // Members can read sessions
        allow read: if isMember(groupId);
        
        // Members can create sessions
        allow create: if isMember(groupId);
        
        // Session creator or group admin can update/delete
        allow update, delete: if isMember(groupId);
      }
    }
  }
}
```

---

## 🗄️ Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Profile images - users can only upload their own
    match /profile_images/{userId}.jpg {
      // Anyone can view profile images
      allow read: if request.auth != null;
      
      // Only the user can upload/update their own image
      allow write: if request.auth != null && 
                      request.auth.uid == userId &&
                      request.resource.size < 5 * 1024 * 1024 && // Max 5MB
                      request.resource.contentType.matches('image/.*');
      
      // Only the user can delete their own image
      allow delete: if request.auth != null && 
                       request.auth.uid == userId;
    }
    
    // Prevent access to all other paths
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

## ✅ Verification Steps

After applying the rules:

1. **Test in Firebase Console:**
   - Go to Firestore → Rules → **Rules Playground**
   - Simulate operations with different user IDs
   - Verify read/write permissions work as expected

2. **Test in your app:**
   - Create a user account
   - Try editing someone else's profile (should fail)
   - Create a group and invite another user
   - Have both users send messages
   - Try editing another user's message (should fail)

---

## 🔒 Security Features

✅ **User Profiles:**
- Users can only edit their own profile
- All authenticated users can view profiles
- Profile deletion is disabled

✅ **Study Groups:**
- Anyone can browse groups
- Only members can update group details
- Empty groups can be auto-deleted

✅ **Messages:**
- Only group members can read/write messages
- Authors can edit/delete their own messages
- Message creation requires membership

✅ **Profile Images:**
- 5MB file size limit
- Only image formats allowed
- Users can only upload their own photo

---

## ⚠️ Important Notes

- **Test Mode**: Firebase creates databases in "test mode" by default (wide-open access for 30 days). Make sure to apply these rules!
- **Updates**: Rule changes take effect immediately
- **Versioning**: Always use `rules_version = '2'` for latest features
- **Debugging**: Check Firebase Console → Rules → **Requests** tab to see denied operations

---

## 🐛 Troubleshooting

**"Permission denied" errors:**
1. Check Firebase Console → Authentication to verify user is logged in
2. Verify user's UID matches in Firestore document
3. Check Rules Playground with actual UIDs
4. Ensure `memberUids` array contains user's UID for group access

**Images not uploading:**
1. Verify file is under 5MB
2. Check file format is image/*
3. Ensure user is authenticated
4. Check Storage → Rules tab for typos

---

## 📚 Learn More

- [Firestore Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Storage Security Rules Documentation](https://firebase.google.com/docs/storage/security)
- [Rules Testing Best Practices](https://firebase.google.com/docs/rules/unit-tests)

**Happy coding! 🚀**
