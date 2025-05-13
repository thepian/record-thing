# Project Brief: Record Thing

## Project Overview

Record Thing is a comprehensive solution for recording, recognizing, and organizing physical items using computer vision and machine learning. The application allows users to record things and events in the world and organize the recordings for various purposes. It's designed to work across iOS and macOS platforms.

## Core Functionality

- Scan and catalogue physical items using computer vision
- Organize items by categories
- Collect evidence about items (receipts, photos, etc.)
- Manage requests related to items
- Make recordings based on pre-defined workflows
- Prove claims about items
- Share recordings with other users
- Create community showcases
- Request recordings from other users

## Technical Architecture

The project consists of:

1. **Client Applications**

   - iOS App (Swift/SwiftUI)
   - macOS App (Swift/SwiftUI)
   - Android App (planned)

2. **Backend Components**

   - Python-based data management
   - ML processing systems
   - Synchronization services

3. **Core Technologies**
   - Swift/SwiftUI for client apps
   - Python for backend tools
   - SQLite with Vector Extensions for database
   - Blackbird as Swift ORM
   - MLX (Apple's ML framework for Apple Silicon)
   - DINO v2 for computer vision
   - KNN for scene recognition
   - Open OCR for text recognition
   - B2/Bunny CDN for asset synchronization and storage

## Project Goals

1. Create a user-friendly application for recording and organizing physical items
2. Implement robust ML-based recognition for various object types
3. Build a secure system for storing and sharing evidence
4. Develop a cross-platform solution that works seamlessly on iOS and macOS
5. Enable community features for sharing and requesting recordings

## Target Users

- Individuals wanting to catalog valuable possessions
- Users needing to document items for insurance purposes
- Communities sharing information about collectibles
- Anyone needing to prove ownership or condition of items

## Project Scope

The initial release focuses on core recording and recognition functionality for iOS and macOS, with plans to expand to Android in the future. The system includes both local storage and cloud synchronization options.
