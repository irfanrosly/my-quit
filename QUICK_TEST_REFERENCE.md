# Quick Test Reference - Achievement Testing

## 🚀 Fastest Way to Test (30 seconds)

```
1. Open App
2. Go to Progress screen (from Dashboard)
3. Scroll to bottom
4. Tap "Test Achievements" button (orange)
5. Tap "3 Days Ago (72 Hours)"
6. Go back to Dashboard
7. Pull down to refresh
8. 🎉 See celebration popup!
```

## 📱 Testing Screen Buttons

### Quick Milestone Buttons (One Tap Each)

| Button | Result |
|--------|--------|
| **24 Hours Ago** | Unlocks: Day 1 badge |
| **3 Days Ago** | Unlocks: Day 1 + 72 Hours badges |
| **1 Week Ago** | Unlocks: Day 1, 72 Hours, 1 Week |
| **1 Month Ago** | Unlocks: 5 badges |
| **1 Year Ago** | Unlocks: ALL 9 badges! |

### Other Options

- **Pick Custom Date**: Choose any date from calendar
- **Reset to Now**: Clear all achievements and start fresh

## ✅ Expected Results After Each Test

### After "24 Hours Ago":
```
Dashboard:
- Shows: "1 day smoke-free"
- Next Milestone: "3 Days (72 Hours)"

Badges:
- Unlocked: 🌱 Day 1: Fresh Start

Notification:
- Celebration popup appears (first time only)
```

### After "3 Days Ago":
```
Dashboard:
- Shows: "3 days smoke-free"
- Next Milestone: "1 Week"

Badges:
- Unlocked: 🌱 Day 1: Fresh Start
- Unlocked: ⏳ 72 Hours: Detox Hero

Progress:
- Money saved increases
- Progress bar updates
```

### After "1 Week Ago":
```
Dashboard:
- Shows: "7 days smoke-free"
- Next Milestone: "2 Weeks Strong"

Badges:
- 3 total badges unlocked

Stats:
- Week 1 milestones complete
```

### After "1 Month Ago":
```
Dashboard:
- Shows: "30 days smoke-free"
- Next Milestone: "2 Months"

Badges:
- 5 total badges unlocked
- Day 1, 72 Hours, 1 Week, 2 Weeks, 1 Month

Money:
- Significant savings shown
```

### After "1 Year Ago":
```
Dashboard:
- Shows: "365 days smoke-free"
- Next Milestone: None (all complete!)

Badges:
- ALL 9 time-based badges unlocked!
- Complete achievement collection

Celebration:
- Epic 1-year milestone reached!
```

## 🔄 Common Testing Workflow

### Test Flow 1: Quick Badge Check (1 min)
```
1. Test Achievements button
2. Tap "3 Days Ago"
3. Back → Dashboard → Pull down
4. ✓ Verify 2 badges
5. Done!
```

### Test Flow 2: Progressive Testing (3 mins)
```
1. Test Achievements button
2. Tap "24 Hours" → Verify
3. Tap "3 Days" → Verify
4. Tap "1 Week" → Verify
5. Tap "Reset to Now"
6. Done!
```

### Test Flow 3: Full System Test (5 mins)
```
1. Test Achievements button
2. Test each milestone (24h → 1 year)
3. Check badges after each
4. Verify Firebase sync (check logs)
5. Test on second device
6. Reset when done
```

## 🎯 What to Check

After changing quit date, always verify:

- [ ] Success message appears
- [ ] Go to Dashboard and pull down
- [ ] Check Badges screen
- [ ] Verify Progress screen
- [ ] Check money saved updates
- [ ] Confirm next milestone card

## 🐛 Quick Fixes

### Badge didn't appear?
→ Pull down on Dashboard to refresh

### Wrong number shown?
→ Tap "Reset to Now", then try again

### Want to see notification again?
→ Reset progress first (notifications show once)

### Firebase not syncing?
→ Check internet connection and user login

## 📊 Data Changes

When you tap a test button:

```
Local Storage (SharedPreferences):
  startDate: [Updated to X days ago]

Firebase (Firestore):
  users/{userId}/quitDate: [Updated to X days ago]
  users/{userId}/achievements/: [New badges added]

UI Updates:
  Dashboard: [Refreshes with new data]
  Progress: [Shows new days count]
  Badges: [Shows unlocked badges]
```

## 💡 Pro Tips

1. **Always pull-to-refresh** after changing dates
2. **Check logs** to see Firebase sync (in debug mode)
3. **Test offline mode** by enabling airplane mode
4. **Reset between major tests** for clean results
5. **Use "Reset to Now"** instead of uninstalling app

## ⚠️ Important Notes

- **Notifications show once**: After first view, won't reappear
- **Badges are permanent**: Once unlocked, stay unlocked
- **Reset clears everything**: Both local and Firebase
- **Date changes affect calculations**: Money saved, days, etc.
- **Firebase sync is automatic**: Happens in background

## 🎨 Visual Reference

```
Testing Screen Layout:
┌─────────────────────────────┐
│  ⚠️ Testing Tool Banner     │
├─────────────────────────────┤
│  📅 Current Quit Date       │
│     DD/MM/YYYY              │
│     X days, Y hours ago     │
├─────────────────────────────┤
│  Quick Test Milestones:     │
│                             │
│  [24 Hours Ago]             │
│  [3 Days Ago (72 Hours)]    │
│  [1 Week Ago (7 Days)]      │
│  [2 Weeks Ago (14 Days)]    │
│  [1 Month Ago (30 Days)]    │
│  [2 Months Ago (60 Days)]   │
│  [3 Months Ago (90 Days)]   │
│  [6 Months Ago (180 Days)]  │
│  [1 Year Ago (365 Days)]    │
│                             │
│  [Pick Custom Date]         │
│  [Reset to Now]             │
├─────────────────────────────┤
│  ℹ️ How This Works          │
└─────────────────────────────┘
```

## 🚀 Super Quick Commands

```bash
# To test 3 days achievement:
1. Progress → Test Achievements → 3 Days Ago
2. Dashboard → Pull down
3. ✓ See badges!

# To reset:
Progress → Test Achievements → Reset to Now → Confirm

# To test everything:
Test Achievements → 1 Year Ago → Dashboard → Check badges
```

## 🎉 Success Indicators

You know it's working when:
- ✅ Success message shows on testing screen
- ✅ Dashboard shows updated days count
- ✅ Pull-to-refresh triggers achievement check
- ✅ Celebration popup appears (first time)
- ✅ Badges screen shows new badges
- ✅ Progress screen reflects changes
- ✅ Debug logs show Firebase sync

## 🔗 Related Docs

- Full guide: [ACHIEVEMENT_TESTING_GUIDE.md](ACHIEVEMENT_TESTING_GUIDE.md)
- System docs: [FIREBASE_HYBRID_IMPLEMENTATION.md](FIREBASE_HYBRID_IMPLEMENTATION.md)
- User guide: [ACHIEVEMENT_TRACKER_GUIDE.md](ACHIEVEMENT_TRACKER_GUIDE.md)

---

**Access Testing Screen:**
Dashboard → Progress → Scroll down → "Test Achievements" (orange button)

**That's it! Happy testing! 🎉**
