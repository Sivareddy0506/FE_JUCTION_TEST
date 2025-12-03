# Quick Action Plan: Fix App Store Rejections

## ✅ COMPLETED (Backend)

1. ✅ Updated Prisma schema to add `blockedUsers` field
2. ✅ Created `blockController.js` with block/unblock/getBlockedUsers functions
3. ✅ Added routes for block user functionality
4. ✅ Updated chat controller to filter blocked users

## 🔄 NEXT STEPS

### Step 1: Run Database Migration (Backend)

```bash
cd /Users/saijitvan/Siva/Junction/junction-BE
npx prisma migrate dev --name add_blocked_users
npx prisma generate
```

**Then restart your backend server.**

---

### Step 2: Create Privacy Policy Page (Website)

1. **Create a public Privacy Policy page** at:
   - URL: `https://www.junctionverse.com/privacy-policy`
   - Must be accessible WITHOUT login
   - Must include all data collection practices

2. **Privacy Policy should include:**
   - Personal information (name, email, phone, address)
   - Location data
   - Camera/photo access
   - Chat messages and user-generated content
   - Product listings
   - Payment information
   - FCM tokens for push notifications
   - Analytics and usage data
   - How data is stored and secured
   - Third-party services (Firebase, Razorpay, etc.)
   - User rights (data deletion, access, etc.)

---

### Step 3: Update App Store Connect

1. **Go to App Store Connect → Your App → App Information**
2. **Set Privacy Policy URL:** `https://www.junctionverse.com/privacy-policy`
3. **Go to App Review Information → Notes**
4. **Add:**
   ```
   Terms of Service: https://www.junctionverse.com/terms-of-service
   Community Guidelines: https://www.junctionverse.com/community-guidelines
   
   Block User Feature:
   - Users can block other users from profile and chat screens
   - Blocked users cannot send messages or interact
   - Users can unblock from settings
   
   Privacy Policy:
   - Available at https://www.junctionverse.com/privacy-policy
   - Accessible without login
   - Covers all data collection practices
   ```

---

### Step 4: Add Block User UI (Frontend)

**Create these files:**

1. **`lib/screens/profile/block/block_user_screen.dart`** - List of blocked users
2. **Add "Block User" button in:**
   - `lib/screens/profile/user_profile.dart` (when viewing another user's profile)
   - `lib/screens/Chat/chat_page.dart` (in chat options menu)

**API Endpoints to use:**
- `POST /user/block-user` - Body: `{ "userIdToBlock": "uuid" }`
- `POST /user/unblock-user` - Body: `{ "userIdToUnblock": "uuid" }`
- `GET /user/blocked-users` - Returns list of blocked users
- `GET /user/check-blocked?userId=uuid` - Check if a user is blocked

---

### Step 5: Add Terms & Privacy Links in App

**Add links in:**
1. **Settings page** (`lib/screens/profile/account_settings_page.dart`)
2. **Sign-up flow** (terms acceptance screen)
3. **About page** (if exists)

**Links:**
- Terms of Service: `https://www.junctionverse.com/terms-of-service`
- Privacy Policy: `https://www.junctionverse.com/privacy-policy`
- Community Guidelines: `https://www.junctionverse.com/community-guidelines`

---

### Step 6: Test Everything

1. ✅ Test blocking a user
2. ✅ Test unblocking a user
3. ✅ Test that blocked users cannot send messages
4. ✅ Verify Privacy Policy URL is accessible without login
5. ✅ Verify Terms/Privacy links work in app

---

### Step 7: Resubmit to App Store

**In App Store Connect → App Review Information → Notes, add:**

```
We have addressed the following issues:

1.2.0 - User Generated Content:
- Added block user feature (users can block other users from profile and chat screens)
- Blocked users cannot send messages or interact
- Added Terms of Service and Community Guidelines links in app and App Store Connect
- Enhanced report feature to report users, products, and messages
- Implemented content filtering to prevent blocked users from interacting

5.1.1 - Privacy Policy:
- Created comprehensive Privacy Policy at https://www.junctionverse.com/privacy-policy (accessible without login)
- Updated Privacy Policy URL in App Store Connect
- Verified App Privacy declarations match Privacy Policy content
- Added Privacy Policy link in app settings

Test Accounts:
- Student: student@junctionverse.com / OTP: 5675
- Non-Student: developer@gmail.com / OTP: 6785
```

---

## Priority Order

1. **HIGH PRIORITY:**
   - Run database migration
   - Create Privacy Policy page on website
   - Update Privacy Policy URL in App Store Connect

2. **MEDIUM PRIORITY:**
   - Add block user UI in frontend
   - Add Terms/Privacy links in app

3. **BEFORE RESUBMISSION:**
   - Test all features
   - Update App Review notes
   - Resubmit for review

---

## Estimated Time

- Database migration: 5 minutes
- Privacy Policy page: 1-2 hours (if you need to write it)
- Block user UI: 2-3 hours
- Terms/Privacy links: 30 minutes
- Testing: 1 hour
- **Total: ~5-7 hours**

