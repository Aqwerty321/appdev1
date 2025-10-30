const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const {GoogleGenerativeAI} = require("@google/generative-ai");

admin.initializeApp();

// Define secret for Gemini API key (will be set via Firebase CLI)
const geminiApiKey = defineSecret("GEMINI_API_KEY");

/**
 * AI-powered study buddy matchmaking using Gemini
 * 
 * Input: { interests: string[], bio: string, currentUserId: string }
 * Output: Array of matched users with AI-generated match scores and explanations
 */
exports.findStudyBuddyMatches = onCall(
  {secrets: [geminiApiKey]},
  async (request) => {
    // Authentication check
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const currentUserId = request.auth.uid;
    const {interests, bio} = request.data;

    // Validation
    if (!interests || !Array.isArray(interests) || interests.length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "Interests array is required and must not be empty"
      );
    }

    try {
      // Fetch all users from Firestore (excluding current user)
      const usersSnapshot = await admin
        .firestore()
        .collection("users")
        .get();

      const candidates = [];
      usersSnapshot.forEach((doc) => {
        if (doc.id !== currentUserId) {
          const userData = doc.data();
          candidates.push({
            id: doc.id,
            name: userData.name || "Anonymous",
            bio: userData.bio || "",
            interests: userData.interests || [],
            imageUrl: userData.imageUrl || "",
          });
        }
      });

      if (candidates.length === 0) {
        return {matches: []};
      }

      // Initialize Gemini AI (using Gemini 2.5 Flash - free tier)
      const genAI = new GoogleGenerativeAI(geminiApiKey.value());
      const model = genAI.getGenerativeModel({model: "gemini-2.0-flash-exp"});

      // Create AI prompt for matchmaking
      const prompt = `You are a study buddy matchmaking assistant. Analyze the following user profile and candidate profiles to suggest the best study matches.

Current User Profile:
- Interests: ${interests.join(", ")}
- Bio: ${bio || "No bio provided"}

Candidate Profiles:
${candidates.map((c, idx) => `
${idx + 1}. ${c.name}
   - Interests: ${c.interests.join(", ") || "None listed"}
   - Bio: ${c.bio || "No bio"}
`).join("\n")}

For each candidate, provide a match score (0-100) and a brief, friendly explanation (max 50 words) of why they would be a good study buddy. Consider:
1. Overlapping interests (most important)
2. Complementary skills
3. Bio compatibility
4. Study style hints

Respond in valid JSON format:
{
  "matches": [
    {
      "candidateIndex": 0,
      "score": 85,
      "reason": "Your explanation here"
    }
  ]
}

Only include candidates with score >= 50. Sort by score descending.`;

      const result = await model.generateContent(prompt);
      const response = result.response;
      const text = response.text();

      // Parse AI response (handle potential markdown wrapping)
      let matchData;
      try {
        // Remove potential markdown code blocks
        const cleanedText = text
          .replace(/```json\n?/g, "")
          .replace(/```\n?/g, "")
          .trim();
        matchData = JSON.parse(cleanedText);
      } catch (parseError) {
        console.error("Failed to parse AI response:", text);
        throw new HttpsError(
          "internal",
          "Failed to parse AI matchmaking results"
        );
      }

      // Map AI results back to full user profiles
      const enrichedMatches = matchData.matches
        .filter((m) => m.score >= 50 && m.candidateIndex !== undefined)
        .map((match) => {
          const candidate = candidates[match.candidateIndex];
          if (!candidate) {
            console.error(`Candidate not found for index ${match.candidateIndex}`);
            return null;
          }
          return {
            userId: candidate.id,
            name: candidate.name,
            bio: candidate.bio,
            interests: candidate.interests,
            imageUrl: candidate.imageUrl,
            matchScore: Math.min(100, Math.max(0, match.score)), // Clamp 0-100
            matchReason: match.reason || "Similar interests and study goals",
          };
        })
        .filter((m) => m !== null)
        .sort((a, b) => b.matchScore - a.matchScore)
        .slice(0, 20); // Limit to top 20 matches

      return {matches: enrichedMatches};
    } catch (error) {
      console.error("Error in findStudyBuddyMatches:", error);
      throw new HttpsError(
        "internal",
        "An error occurred during matchmaking"
      );
    }
  }
);

/**
 * Get AI-powered conversation starter suggestions
 * 
 * Input: { targetUserId: string }
 * Output: { starters: string[] } - Array of 3-5 conversation starters
 */
exports.getConversationStarters = onCall(
  {secrets: [geminiApiKey]},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const currentUserId = request.auth.uid;
    const {targetUserId} = request.data;

    if (!targetUserId) {
      throw new HttpsError(
        "invalid-argument",
        "Target user ID is required"
      );
    }

    try {
      // Fetch both user profiles
      const [currentUserDoc, targetUserDoc] = await Promise.all([
        admin.firestore().collection("users").doc(currentUserId).get(),
        admin.firestore().collection("users").doc(targetUserId).get(),
      ]);

      if (!currentUserDoc.exists || !targetUserDoc.exists) {
        throw new HttpsError("not-found", "User profile not found");
      }

      const currentUser = currentUserDoc.data();
      const targetUser = targetUserDoc.data();

      // Initialize Gemini AI (using Gemini 2.5 Flash - free tier)
      const genAI = new GoogleGenerativeAI(geminiApiKey.value());
      const model = genAI.getGenerativeModel({model: "gemini-2.0-flash-exp"});

      const prompt = `Generate 4 friendly, natural conversation starters for a study buddy connection.

Your Profile:
- Name: ${currentUser.name}
- Interests: ${(currentUser.interests || []).join(", ")}
- Bio: ${currentUser.bio || "No bio"}

Their Profile:
- Name: ${targetUser.name}
- Interests: ${(targetUser.interests || []).join(", ")}
- Bio: ${targetUser.bio || "No bio"}

Create conversation starters that:
1. Reference shared interests
2. Are casual and friendly
3. Invite collaboration
4. Are 10-20 words each

Respond in valid JSON:
{
  "starters": [
    "Your starter here",
    "Another starter",
    "Third starter",
    "Fourth starter"
  ]
}`;

      const result = await model.generateContent(prompt);
      const text = result.response.text();

      let starterData;
      try {
        const cleanedText = text
          .replace(/```json\n?/g, "")
          .replace(/```\n?/g, "")
          .trim();
        starterData = JSON.parse(cleanedText);
      } catch (parseError) {
        console.error("Failed to parse starters:", text);
        // Fallback starters
        starterData = {
          starters: [
            `Hey ${targetUser.name}! Want to study together?`,
            "I saw we share some interests. Want to collaborate?",
            "Looking for a study buddy - interested?",
            "Would love to learn from you!",
          ],
        };
      }

      return starterData;
    } catch (error) {
      console.error("Error in getConversationStarters:", error);
      throw new HttpsError(
        "internal",
        "Failed to generate conversation starters"
      );
    }
  }
);
