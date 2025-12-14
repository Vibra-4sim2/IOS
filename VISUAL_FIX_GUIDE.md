# 📱 HOW TO FIX: Notifications Not Staying in Notification Center

## 🎯 THE PROBLEM YOU DESCRIBED:
> "Notification appears, but once it disappears, I can't find it in Notification Center"

---

## ✅ SOLUTION (2 STEPS):

### STEP 1: CHECK iPhone SETTINGS ⚡ (MOST LIKELY CAUSE!)

**On your iPhone (the one with 5:45 on the lock screen):**

1. Open **Settings** app
2. Scroll down until you see **VIBRA**
3. Tap on **VIBRA**
4. You'll see this screen:

```
┌─────────────────────────────────┐
│        VIBRA                    │
├─────────────────────────────────┤
│ Allow Notifications        [ON] │ ← Must be ON
│                                 │
│ ✓ Lock Screen             [ON] │
│ ✓ Notification Center     [ON] │ ← ⚠️ CHECK THIS!
│ ✓ Banners                 [ON] │
│                                 │
│ Banner Style: Temporary         │
│                                 │
│ Sounds                    [ON] │
│ Badges                    [ON] │
└─────────────────────────────────┘
```

### ⚠️ IF "Notification Center" IS OFF:
- **This is your problem!**
- Turn it **ON**
- **Test immediately** (no need to rebuild)

---

### STEP 2: REBUILD THE APP (Code Fixed)

**In Xcode:**

1. Stop the app if running
2. **Clean Build**: `⌘⇧K` (Product → Clean Build Folder)
3. **Build**: `⌘B` (Product → Build)
4. **Run**: `⌘R` (Product → Run)

---

## 🧪 HOW TO TEST:

1. **Login** to VIBRA
2. **Create a publication**
3. **Wait 30 seconds**
4. Notification banner appears at top
5. **Swipe down from the very top** of the screen (from the notch area)
6. **Look for VIBRA** in the notification list

### ✅ You Should See:
```
┌───────────────────────────────┐
│  Notifications                │
├───────────────────────────────┤
│  📱 VIBRA            now      │
│  John Doe a publié            │
│  Nouvelle publication...      │
└───────────────────────────────┘
```

---

## 🔍 TROUBLESHOOTING:

### Still Not Working?

1. **Delete VIBRA app** from iPhone completely
2. **Rebuild from Xcode** (⌘R)
3. When installed, **Allow Notifications**
4. **Check Settings → VIBRA → Notification Center → ON**
5. **Test again**

---

## 📊 BEFORE vs AFTER:

### BEFORE (Current Problem):
```
1. Notification appears → 💬
2. Banner goes away after 3 seconds
3. Swipe down → ❌ Nothing in list
4. Can't find notification
```

### AFTER (Fixed):
```
1. Notification appears → 💬
2. Banner goes away after 3 seconds
3. Swipe down → ✅ See it in list!
4. Can tap anytime to open
```

---

## ⚡ QUICK ACTION:

**RIGHT NOW:**
1. Grab your iPhone
2. Settings → VIBRA
3. Check "Notification Center" switch
4. If OFF → Turn ON
5. Test immediately

**Code is already fixed!** Just need iPhone settings + rebuild.

---

**Most likely it's just the iPhone setting. Check that first!** 🎯
