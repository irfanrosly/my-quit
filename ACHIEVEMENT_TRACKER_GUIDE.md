# Achievement Tracker System - User Guide

## Overview

The Achievement Tracker is an **active monitoring system** that tracks your smoke-free progress in real-time and automatically unlocks badges when you reach specific milestones.

## Features

### 1. **Active Time-Based Tracking**
The tracker monitors your smoke-free duration continuously and checks for new achievements every hour.

### 2. **Milestone Achievements**
The system tracks the following time-based milestones:

- **🌱 Day 1: Fresh Start** - 24 hours smoke-free
- **⏳ 72 Hours: Detox Hero** - 3 days smoke-free
- **🗓️ 1 Week Streak** - 7 days smoke-free
- **💪 2 Weeks Strong** - 14 days smoke-free
- **🌟 1 Month Milestone** - 30 days smoke-free
- **🔥 2 Months Momentum** - 60 days smoke-free
- **🏆 3 Months Champion** - 90 days smoke-free
- **🎯 6 Months Warrior** - 180 days smoke-free
- **👑 1 Year Smoke-Free Legend** - 365 days smoke-free

### 3. **Real-Time Notifications**
When you unlock a new achievement:
- An animated popup appears at the top of the screen
- Haptic feedback celebrates your success
- The badge is automatically added to your collection

### 4. **Progress Tracking**
On the dashboard, you'll see:
- **Next Achievement Card** - Shows your progress toward the next milestone
- Progress percentage and days remaining
- Tap the card to view all achievements in detail

## How It Works

### Automatic Tracking
1. The tracker starts automatically when you open the app
2. It checks your progress every hour
3. When you reach a milestone, you get an instant notification
4. No manual action required!

### Manual Refresh
- Pull down on the dashboard to refresh your progress
- This will check for any newly unlocked achievements immediately

### Viewing All Achievements
- Tap the "Next Achievement" card on the dashboard
- Or go to **Quick Actions > Badges** to see all badges
- View your progress toward locked achievements

## Achievement Categories

### Time-Based Achievements
Automatically unlocked based on your smoke-free duration:
- Calculated from your quit date
- Updated hourly
- Cannot be lost once earned

### Activity-Based Achievements (Existing)
Earned through actions:
- **Money Saved**: RM100, RM500, RM1000
- **Cravings Managed**: 5, 10, 20 cravings
- **Consistent Logging**: 7 days, 30 days logged

## Technical Details

### Services

#### `AchievementTrackerService`
- Monitors smoke-free duration
- Checks milestones hourly
- Triggers achievement unlock events
- Stores unlocked achievements in SharedPreferences

#### `AchievementNotificationService`
- Displays celebration popups
- Provides haptic feedback
- Manages notification animations

### Data Storage

Achievement data is stored locally in:
- `unlocked_achievements` - List of achievement IDs
- Synced with the gamification provider
- Persisted across app sessions

## Developer Notes

### Testing Achievements

To test the system:

1. **Set a recent quit date** for faster milestone unlocking
2. **Pull to refresh** on the dashboard to check immediately
3. **Reset progress** using the test button in Progress screen

### Integration Points

The tracker integrates with:
- **GamificationProvider** - Syncs badges
- **Dashboard** - Shows next milestone
- **BadgesScreen** - Displays all badges
- **AchievementDetailScreen** - Shows detailed progress

### Customization

To add new milestones, edit:
```dart
// lib/services/achievement_tracker_service.dart
_milestones.add(
  AchievementMilestone(
    id: 'new_milestone',
    title: 'Title',
    description: 'Description',
    requiredHours: 48, // 2 days
    category: AchievementCategory.streak,
  ),
);
```

Don't forget to add the mapping in:
```dart
// lib/state/gamification_provider.dart
final achievementToBadge = {
  'new_milestone': 'Badge Title',
  // ...
};
```

## User Experience

### First 24 Hours
- User sets quit date during onboarding
- Tracker starts monitoring immediately
- After 24 hours, first badge unlocks automatically

### Ongoing Journey
- Receives notifications as milestones are reached
- Can view progress toward next milestone on dashboard
- Badge collection grows over time

### Motivation Features
- Visual progress bars show how close you are
- Clear countdown of days remaining
- Celebration animations reinforce achievements

## Benefits

1. **Passive Motivation** - No effort required, automatic recognition
2. **Clear Goals** - Always know what's next
3. **Sense of Progress** - Visual feedback on your journey
4. **Celebration Moments** - Positive reinforcement at key milestones
5. **Long-term Tracking** - Monitors progress up to 1 year and beyond

## Troubleshooting

### Achievements Not Unlocking?
- Ensure your quit date is set correctly
- Pull down to refresh on the dashboard
- Check that the app has been open for at least a few seconds

### Wrong Progress Shown?
- The tracker calculates from your quit date in SharedPreferences
- If needed, use the reset function (testing only)

### Notifications Not Appearing?
- Ensure the app is in the foreground
- Check that animations are enabled on your device

## Future Enhancements

Potential additions:
- Push notifications for achievements (when app is closed)
- Social sharing of achievements
- Special milestone celebrations
- Custom milestone creation
- Achievement streaks and combos
