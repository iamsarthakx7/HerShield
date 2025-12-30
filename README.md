# 🛡️ HerShield – Women Safety App

### **A Real-Time Emergency Response & AI-Driven Safety Companion**

HerShield is a **Flutter + Firebase** powered mobile application designed to provide immediate emergency assistance, intelligent safety guidance, and discreet protection features in unsafe situations. Built as a hackathon submission, it focuses on real-world usability, offline resilience, and rapid response.

---

## 🚀 **The Problem**
Women often face unsafe situations where:
- Quick help is inaccessible
- Panic leads to unclear decisions
- Internet is unavailable
- Using an obvious safety app could escalate danger

**HerShield solves this** by integrating:
- One-tap SOS with live location
- AI-powered risk detection & guidance
- Stealth emergency mode
- Offline SMS fallback

---

## ✨ **Key Features**

### 🧠 **AI Safety Assistant (Powered by Gemini)**
An intelligent chat-based assistant that:
- Analyzes user messages in real-time for risk
- Classifies danger level (Low/Medium/High)
- Suggests SOS activation when high risk is detected
- Displays emergency contacts (Police: 112, Ambulance: 108)
- Supports contextual modes:
  - **Unsafe** – Immediate danger
  - **Panic** – High anxiety situations
  - **Confused** – Need clarity
  - **General** – Safety advice

### 🚨 **Emergency SOS System**
- **One-tap activation** or **shake-to-trigger**
- **Live GPS tracking** with continuous updates
- Alerts sent to trusted contacts via **SMS (works offline)**
- SOS data stored securely in Firebase

### 📍 **Live Location & Emergency Actions**
- **Real-time location sharing** (only during SOS)
- **Direct emergency calls** to police (112) & ambulance (108)
- **Maps integration** for nearby police stations & hospitals
- **Offline map support** using cached GPS data

### 🕶️ **Stealth / Hide Mode**
- **Instant disguise** as a fully functional calculator
- SOS continues running in background
- **Long-press "="** to return to emergency screen
- Protects users when visible apps could increase risk

### 📶 **Offline Resilience**
- **SMS-based alert fallback** when internet fails
- **Location caching** for poor connectivity areas
- **Emergency actions accessible** without network

---

## 🛠️ **Tech Stack**

| **Layer**     | **Technology**          |
|---------------|-------------------------|
| **Frontend**  | Flutter (Dart)          |
| **Backend**   | Firebase                |
| **Auth**      | Firebase Authentication |
| **Database**  | Cloud Firestore         |
| **Storage**   | Firebase Storage        |
| **Location**  | Geolocator              |
| **AI**        | Google Gemini API       |
| **Maps**      | Google Maps API         |
| **Utilities** | url_launcher, SMS       |

---

## 📱 **App Screens**
- **Home Screen** – SOS button + AI Assistant access
- **Safety Chat Screen** – Interactive AI guidance
- **Emergency Screen** – Live SOS controls & location
- **Stealth Calculator** – Disguised emergency interface
- **Profile & Contacts** – Manage trusted contacts
- **SOS History** – View past emergencies
- **Settings** – Configure preferences & permissions

---

## 🔐 **Privacy & Safety**
- **Minimal permissions** – Only what’s necessary
- **Location shared only during active SOS**
- **No data retention** beyond emergency periods
- **Encrypted communications**
- *API keys used for demo purposes only*

---

## 🧪 **Demo Flow (For Judges)**
1. **Launch app** → Home Screen
2. **Open AI Assistant** → Type: *"Someone is following me"*
3. **AI detects risk** → Suggests SOS + shows emergency numbers
4. **Activate SOS** → Emergency screen launches
5. **Live location** begins sharing with contacts
6. **Hide screen** → Switches to calculator disguise
7. **Long-press "="** → Returns to emergency screen
8. **Enable Airplane Mode** → Demonstrates SMS fallback
9. **Stop SOS** → Ends emergency session

---

## 🏆 **Why HerShield Stands Out**
✅ **Proactive AI Guidance** – Intervenes before escalation  
✅ **Real-World Reliability** – Works offline via SMS fallback  
✅ **Discreet Protection** – Calculator disguise for stealth safety  
✅ **Intuitive UX** – Designed for panic situations  
✅ **Scalable Architecture** – Ready for production deployment  

---

## 👥 **Team**
- Sarthak Deore
- Apurva Deshpande  
- Shreya Gaykar
- Esha Patil

---

## 📌 **Future Roadmap**
- **Predictive Threat Analysis** – ML models using location/time patterns
- **Blockchain Incident Logs** – Tamper-proof evidence for legal use
- **Mesh Network SOS** – Bluetooth/Wi-Fi Direct during network outages
- **Satellite SOS Integration** – Remote area emergency coverage
- **IoT Safety Protocol** – Smart home/vehicle integration
- **Law Enforcement Dashboard** – Real-time emergency analytics

---

## ✅ **Hackathon Ready**
- **Fully functional prototype** with core features
- **Real-world testing** of emergency scenarios
- **Clear problem-solution alignment**
- **Production-grade code structure**
- **Demo-ready with judge-friendly flow**

---

### **HerShield isn’t just an app—it’s an intelligent safety companion that listens, understands, and acts when every second counts.**
