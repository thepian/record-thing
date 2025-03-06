# Product Requirements Document (PRD)

This PRD provides requirements on user flows, data structures, backend integration, UI components, error handling.

## **1. Overview**

### **Product Name:** Record Thing  

### **Purpose:**  

An iOS application that helps users catalog their belongings for insurance purposes with AI-enhanced automation.  

### **Target Audience:**  

Individuals who want an organized record of their possessions, particularly for insurance claims or asset management.  

### **Key Value Proposition:**  

AI-powered object recognition and event tracking with minimal manual input.  

---

## **2. Core Features & Functionalities**

### **2.A. Object Recording & Recognition**

- **Auto-capture**: Users hold objects in front of the camera, and the app captures multiple angles when the subject is relevant and novel.  
- **Object Recognition**: Detects previously recorded objects to enable manipulation of related data.  
- **Metadata Storage**: Automatically associates images, descriptions, and object details (price, date, category, etc.).  

### **2.B. Document & Event Association**

- **Attach Documents**: Upload purchase receipts, warranties, and insurance documents.  
- **Log Events**: Users can record maintenance, damage, theft, or sale events related to an object.  

### **2.C. Information Requests & Responses**

- **Request Data**: Users can generate reports or share object details with insurers or other stakeholders.  
- **Receive Requests**: Users can receive requests (e.g., from an insurance company) and respond via the app.  

### **2.D. Local & Cloud Database Sync**

- **SQLite Local Storage**: Data is stored on-device for quick access.  
- **Cloud Sync**: Data is backed up and synchronized with a cloud storage provider.  

### **2.E. Data Browsing & Management**

- **Search & Filter**: Users can browse their belongings, filter by category, and search for specific items.  
- **Edit & Delete**: Items can be updated or removed.  

---

## **3. Technical Architecture**

### **3.A. Mobile App (iOS)**

- **Framework**: Swift (Mainly SwiftUI, Secondary UIKit)
- **Camera Integration**: AVFoundation for capturing images and video clips  
- **Core ML Integration**: ML models for object recognition and categorization  
- **Local Database**: SQLite for offline storage  
- **Cloud Storage**: Sync with Storage buckets (AWS like) & iCloud  

### **3.B. Backend (Optional for Sync)**

- **Cloud Functions**: To manage user authentication and data synchronization  
- **Storage Backend**: Bunny, AWS DynamoDB, AWS Buckets, B2, or similar for cloud storage  

A CDN(thing.thepia.net)  is maintained backed by a Storage Bucket at B2 / Linode / Bunny.

### **3.C. ML Model Requirements**

- **Image Embedding Model**: Converts images to feature vectors for comparison using DINO v2
- **Image Classification Model**: Detects objects and categorizes them  
- **Optical Character Recognition (OCR)**: Extracts text from receipts/documents (Open OCR)  
- **Instance Recognition**: Identifies previously seen objects  

---

## **4. Database Structure**

The database contains the following tables:

- universe
- things
- evidence
- requests
- accounts
- owners
- product
- evidence_type
- feed
- brand
- company
- translations
- image_assets

---

## **5. User Stories**

- **Object Recording**:  
  *As a user, I want to scan my belongings effortlessly so that I can maintain a record for insurance purposes.*  
- **Recognition & Avoiding Duplicates**:  
  *As a user, I want the app to recognize previously recorded items to prevent duplicates.*  
- **Document Association**:  
  *As a user, I want to attach receipts and warranties to my recorded objects for proof of purchase.*  
- **Event Logging**:  
  *As a user, I want to record incidents (damage, maintenance) linked to my belongings.*  
- **Data Sync & Backup**:  
  *As a user, I want my records stored safely in the cloud so I don’t lose my data.*  
- **Showcase my Purchase**
  *As a user, I want to help showing my new purchase to my friends and family.*

### **5.A. Object Recording**

  *As a user, I want to scan my belongings effortlessly so that I can maintain a record for insurance purposes.*

  I will hold the object in front of the camera, and the app will automatically capture multiple angles. The app will associate the images with metadata such as descriptions, prices, and categories. The app will group related images of the same object and suggest the type of recordings that should be made by the user.

### **5.F. Showcase my Purchase**

  *As a user, I want to help showing my new purchase to my friends and family.*

  I will record the packaging, subject and related documents. The app will construct a showcase video and page that I can share with my friends and family.
  I will earn points for creating it for the first time for a specific product or model, and for sharing it with friends and family.

  The showcase recording requires; A barcode, a purchase/sales receipt, a photo of the packaging back/sides with information(company name, product name, model name, SKU, shop sticker, website, Product Manual QR code), a photo of packaging front,
  a hero shot of the unpackaged product placed on a surface, a 360 video of the held/standing product, a hero shot in context(where used).

---

## **6. MVP Scope**

### **6.A. Must-Have Features**

- Object recognition and cataloging  
- Local SQLite storage  
- Cloud sync  
- Attach documents to objects  
- Simple event logging  
- Upload Recorded Showcase to CDN
- Barcode/QR code scanning and lookup of EAN/UPC/ISBN/ISNI
- Lookup meaning of text scanned by Gemini calls with Google Grounding.

### **6.B. Nice-to-Have Features (Post-MVP)**

- AI-driven valuation estimates  
- Integration with insurance providers  
- Multi-user collaboration  

---

## **7. What the future wants:**

- Privacy of data collected. Keep it local
- Data ownership
- Always on cameras that aren't creepy
- Suggestions of implications and actions based on past recorded events

---

## **8. User Interface Design**

- **Clean & Minimalistic**: Focus on the object being scanned
- **Intuitive Navigation**: Easy access to object details and editing options
- **8.C. Simple Floating Toolbar**: The default view shows a context or camera view with a 3 button toolbar at the bottom.
- **8.D. Belonging full-screen View**: Full screen view for recording and showcasing belongings.
- **8.E. Assets browsing View**: Full screen view of Belongings arranged in a typical Photos layout.
- **8.F. Actions browsing View**: Full screen view of Actions.

### 8.A. Clean & Minimalistic

If the app has gone through the initial onboarding process, the default view shows a context or camera view with a 3 button toolbar at the bottom. The toolbar has a rounded-rect mostly transparent color.

Additional questions can be shown with an icon above the toolbar.

Thumbs up and down icon buttons can be shown below the toolbar together with an assertion of the subject recognised.

### 8.C. Simple Floating Toolbar

Create a new Component for a floating toolbar with configurable buttons. Stack - Take Picture - Account(Signature). It has a rounded-rect mostly transparent color.

![Floating Toolbar](./Screens/First%20Categorical%20Scan%20-%20iPhone%2013%20mini.png)

### 8.D. Belonging full-screen View

Full screen view for recording and showcasing belongings. It shows the belonging taking up the full screen with toolbars and other interactive components laid out on top.

### 8.E. Assets browsing View

Full screen view of Belongings arranged in a typical iOS Photos layout.
It can be grouped by time and searched/filtered by topic/category.
The view is accessed through the left button in the toolbar with a stack icon.
Selecting an asset navigates to its full-screen view.
In addition to belongs special feed entries may be shown.
Assets are a filtered view of the `feed` table in the database.
The overview should always be visible. It can be a sidebar on iPad, but full-screen on iOS.


### 8.F. Actions browsing View

Full screen view of Actions.
Selecting an action navigates to its full-screen view.
In addition to requests special feed entries may be shown.
Actions are a filtered view of the `feed` table in the database.

---

## TODO further refinements:

Recording Showcase Scenario

Showcase Recording setting - Learning / Optional / Private  (Optional makes the user choose case by case)
Server setting - Thepia / Evidently / Specific Org Server domain (thing.myorg.com)

If a showcase is not chosen to be private it will be uploaded to a CDN determined by the Server setting.

## Key Features

1. **Live Camera Scene Determination**
2. **Multi-Angle Object Image Capture**
3. **Known Object Detection**
4. **Open OCR Contract Scanning**
5. **Open OCR Receipt Scanning**
6. **Event Recording**  
7. **Data Browsing and Editing (Admin)**
8. **Transitioning between Information Screens and Camera**
9. **Settings, Sponsor Setup and Universe Switching**
