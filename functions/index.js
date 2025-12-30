//const functions = require("firebase-functions");
//const fetch = require("node-fetch");
//
//// 🔐 Read Gemini API key from Firebase env config
//const GEMINI_API_KEY = functions.config().gemini.key;
//
//// ✅ Gemini endpoint (latest stable flash model)
//const GEMINI_ENDPOINT =
//  "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent";
//
///**
// * Secure Gemini callable function
// * Called from Flutter via Firebase Functions
// */
//exports.geminiGenerate = functions.https.onCall(async (data, context) => {
//  // 🛡 AUTH GUARD (VERY IMPORTANT)
//  if (!context.auth) {
//    throw new functions.https.HttpsError(
//      "unauthenticated",
//      "User must be authenticated to use Gemini"
//    );
//  }
//
//  const systemPrompt = data.systemPrompt;
//  const userMessage = data.userMessage;
//
//  if (!systemPrompt || !userMessage) {
//    throw new functions.https.HttpsError(
//      "invalid-argument",
//      "systemPrompt and userMessage are required"
//    );
//  }
//
//  try {
//    const response = await fetch(`${GEMINI_ENDPOINT}?key=${GEMINI_API_KEY}`, {
//      method: "POST",
//      headers: {
//        "Content-Type": "application/json",
//      },
//      body: JSON.stringify({
//        systemInstruction: {
//          parts: [{ text: systemPrompt }],
//        },
//        contents: [
//          {
//            role: "user",
//            parts: [{ text: userMessage }],
//          },
//        ],
//        generationConfig: {
//          temperature: 0.7,
//          topK: 40,
//          topP: 0.95,
//          maxOutputTokens: 300,
//        },
//      }),
//    });
//
//    const result = await response.json();
//
//    if (!response.ok) {
//      console.error("Gemini API error:", result);
//      throw new Error(result.error?.message || "Gemini request failed");
//    }
//
//    const text =
//      result?.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
//
//    if (!text) {
//      throw new Error("Empty response from Gemini");
//    }
//
//    return { text };
//  } catch (error) {
//    console.error("Gemini backend error:", error);
//
//    throw new functions.https.HttpsError(
//      "internal",
//      error.message || "Gemini generation failed"
//    );
//  }
//});
