# Actions View Design

## Overview

The Actions view serves as an aggregate "Actions" flow specifically designed for phone layout, working similar to notifications or an inbox with calls to action (CTAs) for the user. Each entry represents one CTA that guides the user to complete specific tasks or access important features.

## Platform Behavior

- **iPhone (Compact)**: Full-screen Actions view accessible via Actions button in bottom toolbar
- **iPad/macOS (Regular)**: Actions accessible via sidebar entry with same icon and name

## Content Structure

### 1. Call-to-Action Entries
Each CTA is presented as a single, focused entry:

- **Settings Access**: Navigate to Settings with specific highlighted items
- **Account Updates**: Update account information, profile details
- **Identification Workflow**: Complete user verification processes
- **Evidence Recording Requests**: Prompts to record specific evidence
- **Team Invitations**: Join or manage team memberships
- **Onboarding Steps**: Complete setup or tutorial flows

### 2. Agreements Section
Display contents from the agreements table:
- **Terms of Service**: Current agreement status
- **Privacy Policy**: Acceptance and updates
- **Data Processing**: Consent management
- **Premium Features**: Subscription agreements

### 3. Account & Team Access
Navigation to account-related views:
- **Account Profile**: Personal information and preferences
- **Team Management**: Team settings and member management
- **Owner Dashboard**: Organization-level controls (if applicable)

## Design Principles

### User Experience
- **One CTA per entry**: Clear, focused actions
- **Priority-based ordering**: Most important actions first
- **Visual hierarchy**: Clear distinction between action types
- **Progress indicators**: Show completion status where applicable

### Navigation Flow
- **Contextual**: Actions lead to specific, relevant screens
- **Breadcrumb-aware**: Clear path back to Actions view
- **State preservation**: Maintain user's place in workflows

### Content Management
- **Dynamic**: Actions appear/disappear based on user state
- **Personalized**: Relevant to user's current needs and permissions
- **Timely**: Time-sensitive actions prioritized appropriately

## Implementation Notes

### Data Sources
- **User Profile**: Account completion status
- **Agreements Table**: Legal document acceptance
- **Team Memberships**: Pending invitations and roles
- **App State**: Onboarding progress, feature availability
- **Notifications**: System-generated action items

### iPhone-Specific Considerations
- **Settings Navigation**: Direct access to Settings view when on iPhone
- **Full-Screen Layout**: Optimized for single-handed use
- **Swipe Gestures**: Support for common iOS navigation patterns
- **Safe Areas**: Proper handling of notch and home indicator

### iPad/macOS Integration
- **Sidebar Consistency**: Same functionality as iPhone but in sidebar context
- **Split View Support**: Actions can be shown alongside other content
- **Keyboard Navigation**: Support for keyboard shortcuts and focus management

## Future Enhancements

- **Push Notifications**: Integration with system notifications
- **Badges**: Unread count indicators
- **Search/Filter**: Find specific actions or agreements
- **Bulk Actions**: Handle multiple items simultaneously
- **Automation**: Smart suggestions based on user behavior
