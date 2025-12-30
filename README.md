🛡️ HerShield – Women Safety App (Hackathon Project)

HerShield is a real-time women safety mobile application built using Flutter + Firebase, designed to provide immediate emergency assistance, AI-driven safety guidance, and stealth protection features in dangerous situations.

This project was developed as a hackathon submission, focusing on real-world usability, offline resilience, and quick emergency response.

🚀 Problem Statement

Women often face unsafe situations where:

They cannot quickly call for help

They panic and don’t know what to do

Internet connectivity may be unavailable

Using an obvious emergency app may increase danger

HerShield solves this by combining:

One-tap SOS

Live location sharing

AI-driven safety assistant

Stealth emergency mode

✨ Key Features
🚨 Emergency SOS System

One-tap SOS activation

Automatic live location tracking

SOS start / update / stop stored securely in Firebase

Emergency alert sent to trusted contacts via SMS, even without internet

🧠 AI Safety Assistant (Gemini-Powered)

HerShield includes an intelligent AI safety assistant that actively supports the user before, during, and after danger.

Chat-based interaction where the user can explain their situation in natural language

AI listens and analyzes user messages in real time

Automatically classifies risk level (Low / Medium / High)

Suggests activating SOS when high-risk intent is detected

Displays India-specific emergency numbers (Police – 112, Ambulance – 108)

Users can directly call emergency services from the chat screen

Modes designed for emotional context:

Unsafe

Panic

Confused

General Assistance

This ensures users receive guidance even before they press SOS, reducing panic and improving decision-making.

📍 Live Location Sharing

Continuous GPS tracking

Updates location every few seconds

Works even with limited or no internet

Location is shared only during active SOS

📞 Immediate Emergency Actions (India-Specific)

Call Police – 112

Call Ambulance – 108

Open Nearby Police Stations on Maps

Open Nearby Hospitals on Maps

Even without internet, maps may still load using offline maps + GPS, ensuring access to nearby help.

🕶️ Stealth / Hide Mode (Calculator Disguise)

Emergency screen can be hidden instantly

Disguised as a realistic calculator UI

SOS continues silently in background

Long-press on = returns to emergency screen

This protects users when opening a visible emergency app could escalate danger.

📳 Shake-to-Trigger SOS

Shake phone to activate SOS hands-free

Useful when user cannot unlock phone or discreetly access the app

🛠️ Tech Stack
Layer	Technology
Frontend	Flutter (Dart)
Backend	Firebase
Auth	Firebase Authentication
Database	Cloud Firestore
Storage	Firebase Storage
Location	Geolocator
AI	Google Gemini API
Maps	Google Maps
Utilities	url_launcher, SMS
📱 App Screens

Home Screen (SOS + Safety Assistant)

Safety Chat Screen (AI Assistant)

Emergency Screen (Live SOS)

Stealth Calculator Screen

Profile & Emergency Contacts

SOS History

Settings

🔐 Privacy & Safety Considerations

SOS runs silently when screen is hidden

Emergency actions available even without internet

No unnecessary permissions

Location shared only during SOS

SMS fallback ensures alerts reach contacts without internet

API keys are used only for hackathon/demo purposes.

🧪 Demo Flow (For Judges)

Open app → Home Screen

Start Safety Assistant chat

Type a risky message (e.g., “Someone is following me”)

AI analyzes message and suggests SOS + emergency numbers

User can call police directly from chat or activate SOS

Emergency screen appears

Location sharing starts automatically

Hide screen → Calculator disguise

Long-press = to return

Enable airplane mode to demonstrate SMS fallback

🏆 Why HerShield Is Different

AI assists before danger escalates

Realistic emergency UX

Works in low / no internet conditions with SMS fallback

AI-driven escalation logic

Stealth safety mode

Designed for actual emergency behavior, not just demos

👥 Team

Sarthak Deore
Apurva Deshpande
Shreya Gaykar
Esha Patil

📌 Future Improvements

AI-Driven Predictive Threat Analysis – Uses location, time, movement patterns, and crime data to predict danger zones

Blockchain-Secured Incident Logging – Tamper-proof evidence for legal and police use

Decentralized Mesh Network Communication – SOS over Bluetooth/Wi-Fi Direct during total network outages

Satellite SOS Integration – Emergency communication in remote areas

Smart Environment Safety Protocol – IoT integration with smart homes and vehicles

Cross-Platform Emergency Dashboard – Real-time analytics for law enforcement

✅ Hackathon Readiness

Fully working prototype

Real-world features including AI safety analysis and offline SMS fallback

Clear problem-solution mapping

Production-like UX

HerShield is not just an app — it’s a safety companion that listens, understands, and acts when it matters most.
