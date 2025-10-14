# Achievement Testing Guide

## Quick Testing Tool - NOW AVAILABLE! 🧪

I've created a **dedicated testing screen** that allows you to easily simulate different time durations and test all achievement badges!

## How to Access the Testing Tool

### Method 1: From Progress Screen
```
1. Open the app
2. Go to Progress screen
3. Scroll to bottom
4. Tap "Test Achievements" button (orange)
```

### Method 2: Direct Navigation
```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const AchievementTestingScreen()),
);
```

## Testing Screen Features

### 🎯 Quick Test Buttons

The screen includes **one-tap buttons** for all major milestones:

| Button | Sets Quit Date | Tests Achievement |
|--------|---------------|-------------------|
| **24 Hours Ago** | 1 day ago | 🌱 Day 1: Fresh Start |
| **3 Days Ago (72 Hours)** | 3 days ago | ⏳ 72 Hours: Detox Hero |
| **1 Week Ago** | 7 days ago | 🗓️ 1 Week Streak |
| **2 Weeks Ago** | 14 days ago | 💪 2 Weeks Strong |
| **1 Month Ago** | 30 days ago | 🌟 1 Month Milestone |
| **2 Months Ago** | 60 days ago | 🔥 2 Months Momentum |
| **3 Months Ago** | 90 days ago | 🏆 3 Months Champion |
| **6 Months Ago** | 180 days ago | 🎯 6 Months Warrior |
| **1 Year Ago** | 365 days ago | 👑 1 Year Smoke-Free Legend |

### ⚙️ Additional Features

**Pick Custom Date**
- Choose any specific date from calendar picker
- Great for testing edge cases

**Reset to Now**
- Clears all achievements
- Sets quit date to current time
- Fresh start for testing

**Current Status Display**
- Shows current quit date
- Displays duration (X days, Y hours ago)
- Real-time updates

## Step-by-Step Testing Guide

### Test Scenario 1: First Day Badge (24 Hours)

```
1. Open Testing Screen
2. Tap "24 Hours Ago" button
3. Wait for confirmation message
4. Go back to Dashboard
5. Pull down to refresh
6. See "🌱 Day 1: Fresh Start" celebration popup!
7. Check Badges screen to confirm badge unlocked
```

**Expected Result:**
- ✅ Celebration notification appears
- ✅ Badge added to collection
- ✅ Dashboard shows "Day 1" as completed milestone
- ✅ Next milestone card updates to show "3 Days"

### Test Scenario 2: 3 Days Badge (72 Hours)

```
1. Open Testing Screen
2. Tap "3 Days Ago (72 Hours)" button
3. Wait for confirmation
4. Pull down on Dashboard to refresh
5. See "⏳ 72 Hours: Detox Hero" notification!
```

**Expected Result:**
- ✅ Both Day 1 AND 72 Hours badges unlocked
- ✅ Two celebration notifications (if viewing for first time)
- ✅ Progress screen shows 3 days smoke-free
- ✅ Money saved updates accordingly

### Test Scenario 3: One Week (7 Days)

```
1. Tap "1 Week Ago (7 Days)"
2. Refresh Dashboard
3. Check Badges screen
```

**Expected Result:**
- ✅ 3 badges unlocked: Day 1, 72 Hours, 1 Week
- ✅ Dashboard shows 7 days smoke-free
- ✅ Next milestone: "2 Weeks Strong"

### Test Scenario 4: Jump to 1 Month

```
1. Tap "1 Month Ago (30 Days)"
2. Refresh Dashboard
```

**Expected Result:**
- ✅ 5 badges unlocked (all up to 1 month)
- ✅ Dashboard shows 30 days
- ✅ Money saved significantly increased
- ✅ Next milestone: "2 Months"

### Test Scenario 5: Full Year

```
1. Tap "1 Year Ago (365 Days)"
2. Refresh Dashboard
3. View all badges
```

**Expected Result:**
- ✅ ALL 9 time-based badges unlocked!
- ✅ Dashboard shows 365 days
- ✅ Significant money saved
- ✅ No next milestone (all complete!)

## What Happens When You Change the Date

### Behind the Scenes:

```
1. Updates SharedPreferences (local storage)
   - Key: 'startDate'
   - Value: Milliseconds since epoch

2. Updates Firebase (cloud storage)
   - Collection: users/{userId}
   - Field: quitDate (Timestamp)

3. Triggers Achievement Check
   - Calls: gamificationProvider.checkAchievementsNow()
   - Compares current time vs quit date
   - Unlocks all eligible achievements

4. Shows Notifications
   - Animated celebration popups
   - Haptic feedback
   - Badge collection updated

5. Updates UI
   - Dashboard refreshes
   - Progress screen updates
   - Badge screen shows new badges
```

## Testing Different Scenarios

### Scenario A: Offline Testing

```
1. Enable Airplane Mode
2. Open Testing Screen
3. Change quit date
4. Check that local storage works
5. Disable Airplane Mode
6. Changes sync to Firebase automatically
```

### Scenario B: Cross-Device Sync

```
1. Device A: Set quit date to 7 days ago
2. Device B: Login with same account
3. Device B: Open app
4. Device B: Should show all badges from Device A
```

### Scenario C: Reset and Retest

```
1. Tap "Reset to Now"
2. Confirm reset
3. All badges cleared
4. Quit date set to current time
5. Start testing from scratch
```

### Scenario D: Custom Date Testing

```
1. Tap "Pick Custom Date"
2. Select specific date (e.g., March 15, 2024)
3. Confirm
4. App calculates duration from that date to now
5. Unlocks appropriate badges
```

## Verification Checklist

After changing the quit date, verify:

- [ ] Success message shown
- [ ] Current quit date updates on testing screen
- [ ] Duration text updates (X days, Y hours ago)
- [ ] Dashboard pull-to-refresh works
- [ ] Celebration notifications appear (first time viewing)
- [ ] Badges screen shows new badges
- [ ] Progress screen shows correct days
- [ ] Money saved calculated correctly
- [ ] Next milestone card updates
- [ ] Firebase data synced (check debug logs)

## Debug Logs to Watch

Enable debug mode and look for these logs:

```dart
// When changing quit date:
✓ "Quit date set to DD/MM/YYYY"
✓ "Quit date saved to Firebase"
✓ "AchievementTracker: Hours since quit: X"

// When achievements unlock:
✓ "AchievementTracker: Unlocking 🌱 Day 1: Fresh Start"
✓ "FirebaseAchievement: Saved day_1 for user abc123"
✓ "Synced X badges from Firebase"

// On dashboard refresh:
✓ "AchievementTracker: Syncing from Firebase..."
✓ "Synced X achievements from Firebase"
```

## Common Testing Workflows

### Quick Badge Test (2 minutes)

```
1. Tap "3 Days Ago"
2. Refresh Dashboard
3. Verify 2 badges (Day 1, 72 Hours)
4. Tap "Reset to Now"
5. Done!
```

### Full Badge Test (5 minutes)

```
1. Tap "24 Hours Ago" → Check badge
2. Tap "3 Days Ago" → Check badges
3. Tap "1 Week Ago" → Check badges
4. Tap "1 Month Ago" → Check badges
5. Tap "1 Year Ago" → Check all 9 badges
6. Tap "Reset to Now"
```

### Edge Case Testing

```
1. Set quit date to exactly NOW
   - Should show 0 days
   - No badges unlocked

2. Set quit date to 23 hours ago
   - Still 0 days (not 24h yet)
   - No Day 1 badge

3. Set quit date to 24 hours 1 minute ago
   - Shows 1 day
   - Day 1 badge unlocks!

4. Set quit date to future (shouldn't work)
   - Date picker prevents future dates
```

## Troubleshooting

### "Badge didn't unlock after changing date"

**Solution:**
1. Go to Dashboard
2. Pull down to refresh (triggers achievement check)
3. Badge should appear now

**If still not working:**
- Check debug logs for errors
- Verify quit date was actually saved
- Try "Reset to Now" then test again

### "Shows wrong number of days"

**Possible causes:**
- Timezone issues
- Date set to wrong day
- Cache not cleared

**Solution:**
```
1. Tap "Reset to Now"
2. Wait 5 seconds
3. Set date again
4. Refresh Dashboard
```

### "Celebration notification doesn't show"

**Note:** Notifications only show ONCE per badge

**To see again:**
1. Reset all progress
2. Set quit date again
3. First view will show notification

**Alternative:** Check Badges screen to verify badge is there

### "Firebase not syncing"

**Check:**
1. Is user logged in? (Check auth status)
2. Is internet connected?
3. Are Firestore rules set correctly?

**Debug:**
```dart
final user = FirebaseAuth.instance.currentUser;
debugPrint('User: ${user?.uid}');
```

## Best Practices for Testing

### Do's ✅

- ✅ Use testing screen for quick tests
- ✅ Pull-to-refresh after changing dates
- ✅ Check both Badges and Progress screens
- ✅ Test offline mode
- ✅ Verify Firebase sync with different accounts
- ✅ Reset between major test runs

### Don'ts ❌

- ❌ Don't change dates too rapidly (wait for saves)
- ❌ Don't test in production without warning users
- ❌ Don't forget to reset after testing
- ❌ Don't expect notifications after first view
- ❌ Don't use testing screen for real quit tracking

## Production Considerations

### Before Release

**Option 1: Hide Testing Screen**
```dart
// Only show in debug mode
if (kDebugMode) {
  // Show testing button
}
```

**Option 2: Remove Testing Button**
```dart
// Comment out in progress_screen.dart
// OutlinedButton.icon(
//   onPressed: () => Navigator.push(...AchievementTestingScreen()),
//   ...
// ),
```

**Option 3: Admin-Only Access**
```dart
// Check if user is admin
final isAdmin = user?.email == 'admin@myquitmate.com';
if (isAdmin) {
  // Show testing screen
}
```

### In Production

If you keep the testing screen:
- Add clear warnings
- Require confirmation dialogs
- Log all testing actions
- Consider disabling Firebase sync during tests

## Example Test Script

```dart
// Automated test script (for QA)
Future<void> testAllAchievements() async {
  final testScreen = AchievementTestingScreen();

  // Test each milestone
  for (int days in [1, 3, 7, 14, 30, 60, 90, 180, 365]) {
    await testScreen._setDaysAgo(days);
    await Future.delayed(Duration(seconds: 2));

    // Verify badges
    final provider = context.read<GamificationProvider>();
    final statuses = await provider.getAchievementStatuses();

    // Assert badges are unlocked
    print('Days: $days - Badges: ${statuses.where((s) => s.isUnlocked).length}');
  }

  // Reset
  await provider.resetAll();
}
```

## Summary

The Achievement Testing Screen provides:

✅ **One-tap testing** for all milestones
✅ **Custom date picker** for specific scenarios
✅ **Real-time updates** showing current status
✅ **Firebase sync** verification
✅ **Easy reset** for repeated testing
✅ **Visual feedback** with status messages

**Access it from Progress Screen → "Test Achievements" button!**

Happy testing! 🧪🎉
