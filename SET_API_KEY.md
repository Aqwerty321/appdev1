# 🔑 Set Your Gemini API Key - REQUIRED!

The Cloud Functions are deployed, but they won't work until you set your Gemini API key.

## Step 1: Get Gemini API Key

1. Visit: https://makersuite.google.com/app/apikey
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the key (it looks like: AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXX)

## Step 2: Set the Secret in Firebase

Run this command and paste your API key when prompted:

```bash
firebase functions:secrets:set GEMINI_API_KEY
```

Example:
```
$ firebase functions:secrets:set GEMINI_API_KEY
? Enter a value for GEMINI_API_KEY: AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXX
✔  Created a new secret version projects/studybuddyapp-309d8/secrets/GEMINI_API_KEY
```

## Step 3: Redeploy Functions (to use the new secret)

```bash
firebase deploy --only functions
```

## Step 4: Test!

Refresh your app and click "AI Matchmaking" - it should work now! 🎉

---

**Note:** The error you saw (`[firebase_functions/internal] internal`) happened because the secret wasn't set yet. Once you complete these steps, the AI matchmaking will work perfectly!
