# RecordedStackAndRequirementsView Carousel Gesture Design Document

## Overview
The Carousel component requires precise, high-quality gesture handling that meets Apple Design Award standards. This document outlines the gesture implementation strategy focusing on natural interaction patterns and polished animations.

## Gesture Requirements

### 1. Horizontal Swipe
- **Purpose**: Navigate between evidence pieces
- **Implementation Details**:
  - Minimum distance: 20 points
  - Threshold: 50 points
  - Velocity-based animation
  - Haptic feedback on successful swipe
  - Spring animation for card movement
  - Cards should follow finger with natural resistance
  - Overscroll effect with rubber banding

### 2. Vertical Swipe (Downward)
- **Purpose**: Exit reviewing mode
- **Implementation Details**:
  - Minimum distance: 20 points
  - Threshold: 50 points
  - 45-degree trajectory towards bottom right
  - Velocity-based animation scaling
  - Progressive opacity fade during drag
  - Haptic feedback on threshold crossing
  - Spring animation for exit transition
  - Cards should maintain relative positions during exit

### 3. Tap
- **Purpose**: Select current evidence piece
- **Implementation Details**:
  - Maximum movement: 10 points
  - Maximum duration: 0.3 seconds
  - Subtle scale animation (0.95)
  - Haptic feedback on tap
  - Quick spring animation

## Animation Specifications

### 1. Card Movement
- **Spring Parameters**:
  - Mass: 1.0
  - Stiffness: 100
  - Damping: 10
  - Initial velocity: Based on gesture velocity
- **Overscroll**:
  - Rubber banding effect
  - Maximum overscroll: 30% of card width
  - Deceleration curve: Custom cubic bezier

### 2. Exit Animation
- **Trajectory**:
  - 45-degree angle
  - Distance: Screen diagonal
  - Progressive rotation (0-15 degrees)
- **Timing**:
  - Duration: 0.5 seconds
  - Easing: Custom spring with high damping
- **Visual Effects**:
  - Progressive opacity fade (1.0 to 0.0)
  - Scale reduction (1.0 to 0.8)
  - Blur effect during movement

## Gesture State Management

### 1. State Machine

```swift
enum GestureState {
    case idle
    case dragging(translation: CGSize, velocity: CGSize)
    case decelerating(velocity: CGSize)
    case settling
    case exiting
}
```

managed in Carousel component.

### 2. Transition Rules
- `idle` → `dragging`: On gesture start
- `dragging` → `decelerating`: On gesture end with velocity
- `dragging` → `exiting`: On downward threshold crossing
- `decelerating` → `settling`: When velocity drops below threshold
- `settling` → `idle`: When position stabilizes

## Performance Considerations

### 1. Frame Rate
- Target: 60 FPS
- Minimum: 30 FPS
- Use Metal for blur effects
- Optimize image scaling

### 2. Memory Management
- Cache transformed images
- Release resources on exit
- Preload adjacent cards

## Accessibility

### 1. VoiceOver
- Announce current card position
- Provide swipe instructions
- Indicate exit gesture availability

### 2. Dynamic Type
- Scale text appropriately
- Maintain readability during animations

## Testing Requirements

### 1. Unit Tests
- Gesture recognition accuracy
- Animation timing
- State transitions
- Edge cases

### 2. Performance Tests
- Frame rate under load
- Memory usage
- Battery impact

### 3. User Testing
- Gesture recognition accuracy
- Animation feel
- Accessibility compliance

## Implementation Phases

### Phase 1: Core Gestures
1. Implement basic horizontal swipe
2. Add vertical swipe detection
3. Integrate state machine

### Phase 2: Polish
1. Add haptic feedback
2. Implement spring animations
3. Add overscroll effects

### Phase 3: Exit Animation
1. Implement trajectory calculation
2. Add visual effects
3. Optimize performance

### Phase 4: Accessibility
1. Add VoiceOver support
2. Implement Dynamic Type
3. Test with assistive technologies

## Success Criteria
1. Gestures feel natural and responsive
2. Animations are smooth and polished
3. Performance meets or exceeds 60 FPS
4. Accessibility requirements are met
5. Edge cases are handled gracefully
6. Battery impact is minimal

