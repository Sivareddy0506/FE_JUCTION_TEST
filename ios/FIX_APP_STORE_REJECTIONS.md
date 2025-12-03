# Fix App Store Rejections: 1.2.0 & 5.1.1

## Rejection Reasons

### 1. **1.2.0 Safety: User Generated Content**
Your app allows users to post products, chat messages, images, and other user-generated content. Apple requires:
- ✅ Report feature (you have this)
- ❌ Block user feature (MISSING)
- ❌ Easy access to Terms of Service/Community Guidelines
- ✅ Contact information (you have this in App Review section)
- ❌ Content moderation/filtering mechanism

### 2. **5.1.1 Legal: Privacy - Data Collection and Storage**
Your app collects user data but:
- ❌ Privacy Policy URL is missing or incorrect
- ❌ Privacy Policy must be accessible without login
- ❌ Privacy Policy must match App Privacy declarations

---

## Solution Steps

### PART 1: Fix 1.2.0 (User Generated Content)

#### Step 1: Add Block User Feature

**Backend (junction-BE):**

1. **Update Prisma Schema** (`prisma/schema.prisma`):
```prisma
model User {
  // ... existing fields ...
  blockedUsers String[] @default([]) // Array of user IDs that this user has blocked
  blockedBy     String[] @default([]) // Array of user IDs that have blocked this user
}
```

2. **Create Block Controller** (`controllers/blockController.js`):
```javascript
const prisma = require('../prisma');

// Block a user
exports.blockUser = async (req, res) => {
  const { email } = req.user;
  const { userIdToBlock } = req.body;

  if (!userIdToBlock) {
    return res.status(400).json({ error: 'User ID to block is required' });
  }

  try {
    const currentUser = await prisma.user.findUnique({ where: { email } });
    if (!currentUser) return res.status(404).json({ error: 'User not found' });

    // Add to blockedUsers array
    const updatedUser = await prisma.user.update({
      where: { email },
      data: {
        blockedUsers: {
          push: userIdToBlock
        }
      }
    });

    // Also update the blocked user's blockedBy array
    await prisma.user.update({
      where: { id: userIdToBlock },
      data: {
        blockedBy: {
          push: currentUser.id
        }
      }
    });

    res.json({ message: 'User blocked successfully', blockedUsers: updatedUser.blockedUsers });
  } catch (error) {
    console.error('Error blocking user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Unblock a user
exports.unblockUser = async (req, res) => {
  const { email } = req.user;
  const { userIdToUnblock } = req.body;

  try {
    const currentUser = await prisma.user.findUnique({ where: { email } });
    if (!currentUser) return res.status(404).json({ error: 'User not found' });

    const updatedUser = await prisma.user.update({
      where: { email },
      data: {
        blockedUsers: {
          set: currentUser.blockedUsers.filter(id => id !== userIdToUnblock)
        }
      }
    });

    await prisma.user.update({
      where: { id: userIdToUnblock },
      data: {
        blockedBy: {
          set: (await prisma.user.findUnique({ where: { id: userIdToUnblock } })).blockedBy.filter(id => id !== currentUser.id)
        }
      }
    });

    res.json({ message: 'User unblocked successfully' });
  } catch (error) {
    console.error('Error unblocking user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get blocked users list
exports.getBlockedUsers = async (req, res) => {
  const { email } = req.user;

  try {
    const user = await prisma.user.findUnique({
      where: { email },
      select: { blockedUsers: true }
    });

    if (!user) return res.status(404).json({ error: 'User not found' });

    const blockedUsersDetails = await prisma.user.findMany({
      where: { id: { in: user.blockedUsers } },
      select: {
        id: true,
        fullName: true,
        email: true,
        selfieUrl: true
      }
    });

    res.json({ blockedUsers: blockedUsersDetails });
  } catch (error) {
    console.error('Error fetching blocked users:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
```

3. **Add Routes** (`routes/userRoutes.js`):
```javascript
const blockController = require('../controllers/blockController');

router.post('/block-user', authenticateToken, blockController.blockUser);
router.post('/unblock-user', authenticateToken, blockController.unblockUser);
router.get('/blocked-users', authenticateToken, blockController.getBlockedUsers);
```

4. **Update Chat Controller** to filter blocked users:
In `controllers/chatController.js`, before sending messages, check if users are blocked:
```javascript
// Before sending a message, check if blocked
const sender = await prisma.user.findUnique({ where: { id: senderId } });
const receiver = await prisma.user.findUnique({ where: { id: receiverId } });

if (sender.blockedUsers?.includes(receiverId) || receiver.blockedUsers?.includes(senderId)) {
  return res.status(403).json({ error: 'Cannot send message to blocked user' });
}
```

**Frontend (FE_JUCTION_TEST):**

1. **Create Block User Screen** (`lib/screens/profile/block/block_user.dart`):
```dart
// Add a "Block User" button in user profile or chat screen
// When clicked, show confirmation dialog, then call API to block
```

2. **Add Block Button in Chat Screen** (`lib/screens/Chat/chat_page.dart`):
```dart
// In the chat options menu, add "Block User" option
// Show confirmation dialog before blocking
```

3. **Filter Blocked Users** in product listings and chat lists

#### Step 2: Add Terms of Service & Community Guidelines Link

**In App Store Connect:**
1. Go to your app version page
2. In "App Review Information" section
3. Add a link to Terms of Service in "Notes" field:
   ```
   Terms of Service: https://www.junctionverse.com/terms-of-service
   Community Guidelines: https://www.junctionverse.com/community-guidelines
   ```

**In App:**
1. Add a "Terms of Service" and "Community Guidelines" link in:
   - Settings page
   - Sign-up flow
   - About page

#### Step 3: Enhance Report Feature

Update `lib/screens/profile/report/report.dart` to include:
- Option to report specific users
- Option to report specific products
- Option to report specific chat messages

---

### PART 2: Fix 5.1.1 (Privacy Policy)

#### Step 1: Create Privacy Policy Page

**On Your Website:**
1. Create a public Privacy Policy page at: `https://www.junctionverse.com/privacy-policy`
2. Make it accessible WITHOUT requiring login
3. Include all data collection practices:
   - Personal information (name, email, phone)
   - Location data
   - Camera/photo access
   - Chat messages
   - Product listings
   - Payment information
   - FCM tokens for push notifications
   - Analytics data

#### Step 2: Update App Store Connect

1. Go to **App Information** → **Privacy Policy URL**
2. Set it to: `https://www.junctionverse.com/privacy-policy`
3. **IMPORTANT:** This URL must be accessible without login

#### Step 3: Verify App Privacy Matches Privacy Policy

In App Store Connect → **App Privacy**:
- Ensure all declared data types match what's in your Privacy Policy
- Common data types you collect:
  - ✅ Contact Info (Name, Email, Phone)
  - ✅ User Content (Chat messages, Product listings, Photos)
  - ✅ Identifiers (User ID, Device ID)
  - ✅ Location (Approximate location)
  - ✅ Usage Data (Product interactions, App launches)
  - ✅ Diagnostics (Crash logs, Performance data)

#### Step 4: Add Privacy Policy Link in App

Add a link to Privacy Policy in:
- Settings page
- Sign-up flow
- About page

---

## Quick Checklist

### For 1.2.0 (User Generated Content):
- [ ] Add block user feature (backend + frontend)
- [ ] Update chat controller to filter blocked users
- [ ] Add Terms of Service link in App Store Connect notes
- [ ] Add Community Guidelines link in App Store Connect notes
- [ ] Add Terms/Community Guidelines links in app UI
- [ ] Enhance report feature to report users/products/messages

### For 5.1.1 (Privacy Policy):
- [ ] Create Privacy Policy page on website (public, no login required)
- [ ] Update Privacy Policy URL in App Store Connect
- [ ] Verify App Privacy declarations match Privacy Policy
- [ ] Add Privacy Policy link in app UI

---

## Response to Apple

When resubmitting, in the "Notes" section, add:

```
We have addressed the following issues:

1.2.0 - User Generated Content:
- Added block user feature (users can block other users from profile and chat screens)
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

## Next Steps

1. **Implement block user feature** (backend + frontend)
2. **Create Privacy Policy page** on your website
3. **Update App Store Connect** with Privacy Policy URL
4. **Add Terms/Privacy links** in app UI
5. **Test all features** thoroughly
6. **Resubmit for review**

