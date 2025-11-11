# Test Cases - Junction App Features

**Date:** Today's Session  
**Purpose:** Comprehensive test cases for features developed and fixed

---

## 1. Product Listing Duplication Fix

### Test Case 1.1: Product Card in Chat
**Priority:** High  
**Description:** Verify that product cards do not appear twice in chat messages

**Steps:**
1. Open a chat conversation
2. Navigate to a chat where a product card was shared
3. Scroll through the message history

**Expected Result:**
- Each product card should appear only once
- No duplicate product cards with the same product ID
- Messages should be unique (no exact duplicate messages)

**Actual Result:** [To be filled by tester]

---

## 2. Error Handling - User-Friendly Messages

### Test Case 2.1: Login Page Error Messages
**Priority:** High  
**Description:** Verify that API errors show user-friendly messages instead of technical errors

**Steps:**
1. Open the login page
2. Enter invalid credentials or trigger network error
3. Submit the form

**Expected Result:**
- Error message should be user-friendly (e.g., "Unable to connect. Please check your internet connection")
- No technical error codes or stack traces visible
- Success messages show properly when OTP is sent

**Test Locations:**
- Login page (`login_page.dart`)
- User rating page (`user_rating.dart`)
- Manual signup page (`manual_signup_page.dart`)
- Chat page (`chat_page.dart`)
- Product detail page (`product_detail.dart`)

**Actual Result:** [To be filled by tester]

---

### Test Case 2.2: Network Error Handling
**Priority:** High  
**Description:** Verify error handling for different error types

**Test Scenarios:**
1. **No Internet Connection:**
   - Turn off WiFi/Mobile data
   - Try to perform any API call
   - Expected: "Unable to connect. Please check your internet connection"

2. **Timeout Errors:**
   - Slow down network connection
   - Expected: "Request timed out. Please try again"

3. **Server Errors (500):**
   - Expected: "Something went wrong. Please try again later"

4. **Client Errors (400, 401, 403):**
   - Expected: User-friendly message based on error type

**Actual Result:** [To be filled by tester]

---

## 3. Admin Dashboard Statistics API

### Test Case 3.1: Dashboard Stats Endpoint
**Priority:** Medium  
**Description:** Verify admin dashboard statistics API returns correct data

**Endpoint:** `GET /admin/dashboard/stats`

**Steps:**
1. Login as admin user
2. Navigate to admin dashboard
3. Access the dashboard stats endpoint

**Expected Result:**
- Returns JSON with following structure:
  ```json
  {
    "summary": {
      "totalActiveUsers": <number>,
      "pendingRegistrations": <number>,
      "totalActiveProducts": <number>,
      "totalSoldProducts": <number>,
      "totalPendingProducts": <number>
    },
    "charts": {
      "activeUsersByDate": [{"date": "YYYY-MM-DD", "count": <number>}],
      "productsByDate": [{"date": "YYYY-MM-DD", "activeCount": <number>, "soldCount": <number>}]
    },
    "dateRange": {
      "days": 30,
      "startDate": "ISO date",
      "endDate": "ISO date"
    }
  }
  ```
- All counts are accurate
- Charts data is properly formatted
- Date range defaults to last 30 days or uses query parameter

**Test with Query Parameters:**
- `?days=7` - Should return last 7 days
- `?days=30` - Should return last 30 days
- `?days=90` - Should return last 90 days

**Actual Result:** [To be filled by tester]

---

## 4. Product Listing - Edit Functionality

### Test Case 4.1: Edit Description
**Priority:** High  
**Description:** Verify that description edit functionality works

**Steps:**
1. Navigate to product listing review page (`review_listing.dart`)
2. Click on the edit icon next to description
3. Modify the description text
4. Save the changes

**Expected Result:**
- Edit icon is clickable
- Dialog opens with text field showing current description
- User can modify the description
- Changes are saved and reflected in the UI
- Cancel button closes dialog without saving

**Actual Result:** [To be filled by tester]

---

### Test Case 4.2: Edit Pickup Location
**Priority:** High  
**Description:** Verify that location edit functionality works

**Steps:**
1. Navigate to product listing review page
2. Click on the edit icon next to pickup location
3. Navigate to location selection page
4. Search for a new location or select from map
5. Confirm the selection

**Expected Result:**
- Edit icon is clickable
- Location selection page opens with "Confirm" button (instead of "Next")
- User can search for location
- User can select location from map
- Selected location is updated in the review page
- Changes are saved

**Actual Result:** [To be filled by tester]

---

## 5. Location Search Functionality

### Test Case 5.1: Location Search in Product Creation
**Priority:** High  
**Description:** Verify location search works during product creation

**Steps:**
1. Navigate to product creation flow
2. Reach the location selection page (`select_location.dart`)
3. Use the search bar to search for a location
4. Select a location from search results
5. Verify map moves to selected location

**Expected Result:**
- Search bar is visible and functional
- Search results appear after typing
- Debouncing works (doesn't search on every keystroke)
- Map automatically moves to selected location
- Selected location is displayed correctly
- User can still drag and drop map pin if needed
- "Next" button appears for initial selection, "Confirm" for editing

**Test Scenarios:**
- Search for "Mumbai"
- Search for "Bangalore"
- Search for specific address
- Tap on map after searching (should clear search)

**Actual Result:** [To be filled by tester]

---

## 6. Notification Icon Dynamic Display

### Test Case 6.1: Notification Icon Based on Notifications
**Priority:** Medium  
**Description:** Verify notification icon changes based on unread notifications

**Location:** `logo_icons_widget.dart`

**Steps:**
1. Open the app home screen
2. Check the notification icon in the header
3. Send a notification to the user
4. Check if icon changes
5. Read all notifications
6. Check if icon changes back

**Expected Result:**
- When unread notifications exist: Shows `Notification.png`
- When no unread notifications: Shows `Nonotification.png`
- Icon updates in real-time when notifications are received/read
- Orange dot indicator appears when notifications exist

**Actual Result:** [To be filled by tester]

---

## 7. Document Deletion on Onboarding Approval/Rejection

### Test Case 7.1: Document Deletion on Approval
**Priority:** High  
**Description:** Verify that user documents are deleted when onboarding is approved

**Backend Endpoint:** `POST /admin/approve-onboarding`

**Steps:**
1. Login as admin
2. Navigate to pending registrations
3. Find a user with uploaded documents (selfie, college ID, Aadhaar, other docs)
4. Approve the onboarding
5. Check user record in database
6. Check S3 bucket

**Expected Result:**
- User documents deleted from S3:
  - `selfieUrl` file deleted
  - `collegeIdUrl` file deleted
  - `aadhaarUrl` file deleted
  - `otherDocsUrl` file deleted
- Database fields cleared:
  - `selfieUrl` = null
  - `collegeIdUrl` = null
  - `aadhaarUrl` = null
  - `otherDocsUrl` = null
- User status updated to "Active"
- User is onboarded successfully

**Actual Result:** [To be filled by tester]

---

### Test Case 7.2: Document Deletion on Rejection
**Priority:** High  
**Description:** Verify that user documents are deleted when onboarding is rejected

**Backend Endpoint:** `POST /admin/reject-onboarding`

**Steps:**
1. Login as admin
2. Navigate to pending registrations
3. Find a user with uploaded documents
4. Reject the onboarding with a reason
5. Check user record in database
6. Check S3 bucket

**Expected Result:**
- User documents deleted from S3 (same as Test Case 7.1)
- Database fields cleared (same as Test Case 7.1)
- User status updated to "Rejected"
- Rejection reason saved
- User is NOT onboarded

**Actual Result:** [To be filled by tester]

---

## 8. Chat Page - Rate the Buyer Feature

### Test Case 8.1: Rate the Buyer Button (Seller View)
**Priority:** High  
**Description:** Verify seller can rate the buyer after product is sold

**Steps:**
1. Login as seller
2. Open a chat where product was sold to this buyer (has orderId)
3. Verify product status is "Sold" or dealStatus is "locked"
4. Check action buttons area

**Expected Result:**
- "Rate the Buyer" button is visible for seller
- Button appears only if:
  - Product is sold (status = "Sold" or dealStatus = "locked")
  - AND this buyer purchased it (orderId exists)
- Clicking button navigates to rating screen
- Rating screen shows buyer as the user being rated

**Actual Result:** [To be filled by tester]

---

### Test Case 8.2: Rate the Buyer Not Shown for Other Chats
**Priority:** High  
**Description:** Verify seller doesn't see rate button for buyers who didn't purchase

**Steps:**
1. Login as seller
2. Open a chat where product was sold to a DIFFERENT buyer
3. Check action buttons area

**Expected Result:**
- "Rate the Buyer" button is NOT visible
- No action buttons shown (or only appropriate buttons for that chat state)
- This ensures seller only rates the actual buyer

**Actual Result:** [To be filled by tester]

---

### Test Case 8.3: Rate the Buyer for Sold Products
**Priority:** High  
**Description:** Verify seller can rate buyer even if product status is "Sold" (not just "locked")

**Steps:**
1. Login as seller
2. Product status is "Sold" (not necessarily dealStatus "locked")
3. Open chat with buyer who purchased (has orderId)
4. Check for "Rate the Buyer" button

**Expected Result:**
- "Rate the Buyer" button is visible
- Works even if dealStatus is not "locked" but orderId exists
- Seller can rate the buyer successfully

**Actual Result:** [To be filled by tester]

---

## 9. Product Detail Page - Mark as Sold Flow

### Test Case 9.1: Chat Button Disabled for Buyer (Sold Product)
**Priority:** High  
**Description:** Verify chat button is disabled for buyers when product is sold

**Steps:**
1. Login as buyer (not the seller)
2. Navigate to a product detail page
3. Product status is "Sold" or "Deal Locked" or "Locked"
4. Check the bottom navigation bar

**Expected Result:**
- Chat button is disabled (grayed out)
- Button cannot be clicked
- Visual indication that button is disabled
- Seller can still use chat button (not disabled for seller)

**Actual Result:** [To be filled by tester]

---

### Test Case 9.2: Mark as Sold Button Enable/Disable
**Priority:** High  
**Description:** Verify Mark as Sold button is only enabled for "For Sale" products

**Steps:**
1. Login as seller
2. Navigate to product detail page for your product
3. Test with different product statuses:

**Test Scenarios:**
- **Status = "For Sale":**
  - Expected: "Mark as Sold" button is visible and enabled

- **Status = "Sold":**
  - Expected: "Mark as Sold" button is NOT visible

- **Status = "Deal Locked" or "Locked":**
  - Expected: "Mark as Sold" button is NOT visible

**Actual Result:** [To be filled by tester]

---

### Test Case 9.3: Mark as Sold - Questionnaire Bottom Sheet
**Priority:** High  
**Description:** Verify questionnaire appears when clicking "Mark as Sold"

**Steps:**
1. Login as seller
2. Navigate to product detail page
3. Product status is "For Sale"
4. Click "Mark as Sold" button

**Expected Result:**
- Bottom sheet slides up with question: "Did you sell the Product in Junction or Outside?"
- Two radio button options:
  - "Junction"
  - "Outside Junction"
- "Cancel" button (left side)
- "Mark as Sold" button (right side, initially disabled)
- User can select either option
- Selecting an option enables "Mark as Sold" button

**Actual Result:** [To be filled by tester]

---

### Test Case 9.4: Mark as Sold - Inside Junction Flow
**Priority:** High  
**Description:** Verify Inside Junction flow with chat selection

**Steps:**
1. Follow steps from Test Case 9.3
2. Select "Junction" radio button
3. Wait for chats to load
4. Select a buyer from dropdown
5. Click "Mark as Sold"

**Expected Result:**
- After selecting "Junction":
  - Loading indicator appears
  - Dropdown appears below radio buttons
  - Dropdown shows list of buyers with locked deals (orderId exists)
  - Each dropdown item shows:
    - Buyer name
    - Order ID (if available)
- If no locked deals: Shows message "No locked deals found. Please lock a deal with a buyer first."
- After selecting buyer:
  - "Mark as Sold" button becomes enabled
- After clicking "Mark as Sold":
  - Product marked as sold with selected buyer
  - Product status updated to "Sold"
  - Order status updated
  - Buyer and seller history updated

**Test Scenarios:**
- Product with multiple chats (should show all buyers with orders)
- Product with no chats (should show error message)
- Product with chats but no locked deals (should show message)

**Actual Result:** [To be filled by tester]

---

### Test Case 9.5: Mark as Sold - Outside Junction Flow
**Priority:** High  
**Description:** Verify Outside Junction flow

**Steps:**
1. Follow steps from Test Case 9.3
2. Select "Outside Junction" radio button
3. Click "Mark as Sold"

**Expected Result:**
- After selecting "Outside Junction":
  - No dropdown appears
  - "Mark as Sold" button becomes enabled immediately
- After clicking "Mark as Sold":
  - Product marked as sold
  - Product status updated to "Sold"
  - buyerId set to null in database
  - Only seller history updated (no buyer history)
  - Success message displayed

**Actual Result:** [To be filled by tester]

---

### Test Case 9.6: Mark as Sold - Cancel Flow
**Priority:** Medium  
**Description:** Verify cancel button works correctly

**Steps:**
1. Open "Mark as Sold" bottom sheet
2. Click "Cancel" button at any point

**Expected Result:**
- Bottom sheet closes
- No changes made to product
- User can click "Mark as Sold" again later
- Product status remains unchanged

**Actual Result:** [To be filled by tester]

---

## 10. Backend API - Get Chats by Product ID

### Test Case 10.1: Get Product Chats API
**Priority:** Medium  
**Description:** Verify API returns chats for a specific product

**Endpoint:** `GET /chat/product-chats?productId={productId}`

**Steps:**
1. Login as seller
2. Call API with productId parameter
3. Verify response

**Expected Result:**
- Returns JSON with structure:
  ```json
  {
    "success": true,
    "chats": [
      {
        "chatId": "<uuid>",
        "buyerId": "<uuid>",
        "buyerName": "<name>",
        "orderId": "<orderId or null>",
        "orderStatus": "<status or null>"
      }
    ]
  }
  ```
- Only returns chats for the authenticated seller
- Includes buyer information
- Includes orderId if deal is locked
- Ordered by creation date (descending)

**Test Scenarios:**
- Product with multiple chats
- Product with no chats (returns empty array)
- Product with chats but no orders (orderId = null)
- Product with chats and locked deals (orderId exists)

**Actual Result:** [To be filled by tester]

---

## 11. Backend API - Mark Product as Sold (Updated)

### Test Case 11.1: Mark as Sold - Inside Junction
**Priority:** High  
**Description:** Verify API handles Inside Junction sale correctly

**Endpoint:** `POST /product/mark-sold`

**Request Body:**
```json
{
  "orderId": "<orderId>",
  "soldInJunction": true
}
```

**Steps:**
1. Ensure order exists with status "Deal Locked"
2. Call API as seller with orderId
3. Verify database updates

**Expected Result:**
- Order status updated to "Sold"
- Product status updated to "Sold"
- Product buyerId set to order.buyerId
- Seller history updated (sold array)
- Buyer history updated (purchased array)
- Returns success response with orderId and productId

**Validation Checks:**
- Seller must be authorized (order.sellerId matches authenticated user)
- Order status must be "Deal Locked"
- Order must exist

**Actual Result:** [To be filled by tester]

---

### Test Case 11.2: Mark as Sold - Outside Junction
**Priority:** High  
**Description:** Verify API handles Outside Junction sale correctly

**Request Body:**
```json
{
  "productId": "<productId>",
  "soldInJunction": false
}
```

**Steps:**
1. Ensure product exists with status "For Sale"
2. Call API as seller with productId and soldInJunction: false
3. Verify database updates

**Expected Result:**
- Product status updated to "Sold"
- Product buyerId set to null
- Seller history updated (sold array)
- Buyer history NOT updated (no buyer)
- Returns success response with productId and soldInJunction: false

**Validation Checks:**
- Seller must be authorized (product.sellerId matches authenticated user)
- Product must exist

**Actual Result:** [To be filled by tester]

---

### Test Case 11.3: Mark as Sold - Error Cases
**Priority:** Medium  
**Description:** Verify error handling for invalid requests

**Test Scenarios:**

1. **Missing orderId for Inside Junction:**
   - Request: `{"soldInJunction": true}`
   - Expected: 400 error - "orderId is required for inside Junction sale"

2. **Missing productId for Outside Junction:**
   - Request: `{"soldInJunction": false}`
   - Expected: 400 error - "productId is required for outside sale"

3. **Unauthorized Seller:**
   - Request with orderId/productId that doesn't belong to seller
   - Expected: 403 error - "Not authorized to mark this as sold"

4. **Invalid Order Status:**
   - Request with orderId that is not "Deal Locked"
   - Expected: 400 error - "Only locked deals can be marked as sold"

5. **Order Not Found:**
   - Request with non-existent orderId
   - Expected: 404 error - "Order not found"

**Actual Result:** [To be filled by tester]

---

## 12. Chat Page - Confirm Deal (Price Lock)

### Test Case 12.1: Confirm Deal - Price Cannot Be Modified
**Priority:** High  
**Description:** Verify that price cannot be modified during deal confirmation

**Steps:**
1. Open a chat conversation
2. Receive or send a price quote
3. Click "Confirm" button on the quote
4. Check the confirm deal bottom sheet

**Expected Result:**
- Bottom sheet shows "Confirm Deal"
- Price is displayed as READ-ONLY (not editable text field)
- Price displayed matches the quoted price exactly
- No text field to modify price
- Note displayed: "The deal will be locked at this exact price. To change the price, send a new quote instead."
- "Lock Deal" button locks the deal at the exact quoted price

**Actual Result:** [To be filled by tester]

---

### Test Case 12.2: Confirm Deal - Uses Exact Quoted Price
**Priority:** High  
**Description:** Verify deal is locked at exact quoted price

**Steps:**
1. Quote a price (e.g., ₹5000)
2. Click "Confirm" on that quote
3. Verify the locked deal price

**Expected Result:**
- Deal is locked at exactly ₹5000 (or whatever was quoted)
- No price modification occurs
- Order created with exact quoted price
- Deal status updated to "confirmed"

**Test Scenarios:**
- Quote ₹1000, confirm → Should lock at ₹1000
- Quote ₹50000, confirm → Should lock at ₹50000
- Quote with decimals, confirm → Should lock at exact amount

**Actual Result:** [To be filled by tester]

---

### Test Case 12.3: Price Modification Requires New Quote
**Priority:** High  
**Description:** Verify that to change price, user must send new quote

**Steps:**
1. Quote a price (e.g., ₹5000)
2. Realize you want different price (e.g., ₹6000)
3. Try to modify during confirmation

**Expected Result:**
- Cannot modify price in confirm dialog
- User must:
  1. Cancel the confirm dialog
  2. Send a new quote with different price
  3. Then confirm the new quote

**Actual Result:** [To be filled by tester]

---

## 13. Integration Tests

### Test Case 13.1: Complete Mark as Sold Flow - Inside Junction
**Priority:** High  
**Description:** End-to-end test of Inside Junction flow

**Steps:**
1. Create a product listing
2. Buyer creates chat and sends quote
3. Seller confirms quote (deal locked)
4. Seller navigates to product detail page
5. Clicks "Mark as Sold"
6. Selects "Junction"
7. Selects buyer from dropdown
8. Clicks "Mark as Sold"
9. Verify in chat page that seller can now rate buyer

**Expected Result:**
- All steps complete successfully
- Product status: "Sold"
- Order status: "Sold"
- Chat shows "Rate the Buyer" button for seller
- No errors in flow

**Actual Result:** [To be filled by tester]

---

### Test Case 13.2: Complete Mark as Sold Flow - Outside Junction
**Priority:** High  
**Description:** End-to-end test of Outside Junction flow

**Steps:**
1. Create a product listing
2. Seller navigates to product detail page
3. Clicks "Mark as Sold"
4. Selects "Outside Junction"
5. Clicks "Mark as Sold"
6. Verify product status

**Expected Result:**
- All steps complete successfully
- Product status: "Sold"
- Product buyerId: null
- No order created
- Chat button disabled for buyers
- Seller can still access chat history

**Actual Result:** [To be filled by tester]

---

## 14. Edge Cases and Error Scenarios

### Test Case 14.1: Multiple Chats for Same Product
**Priority:** Medium  
**Description:** Verify handling when product has multiple chats

**Steps:**
1. Create a product
2. Multiple buyers create chats
3. Lock deals with different buyers
4. Seller marks as sold - Inside Junction
5. Verify dropdown shows all buyers with orders

**Expected Result:**
- Dropdown shows all buyers who have locked deals
- Each buyer listed with their order ID
- Seller can select correct buyer
- Only selected buyer's order is marked as sold

**Actual Result:** [To be filled by tester]

---

### Test Case 14.2: Product Sold Outside - Chat Access
**Priority:** Medium  
**Description:** Verify chat behavior when product sold outside

**Steps:**
1. Buyer creates chat with seller
2. Some messages exchanged
3. Seller marks product as sold - Outside Junction
4. Buyer tries to access chat
5. Seller tries to access chat

**Expected Result:**
- Buyer: Chat button disabled on product detail page
- Seller: Can still access chat (button not disabled)
- Chat history preserved
- No new messages can be sent by buyer (if restriction applies)

**Actual Result:** [To be filled by tester]

---

### Test Case 14.3: Rapid Quote and Confirm
**Priority:** Low  
**Description:** Verify system handles rapid quote/confirm actions

**Steps:**
1. Send quote quickly
2. Immediately click confirm
3. Try to send another quote before first confirm completes

**Expected Result:**
- System handles requests gracefully
- No race conditions
- Each quote/confirm processed correctly
- Cooldown timer works (if applicable)

**Actual Result:** [To be filled by tester]

---

## Test Summary

### Critical Paths (Must Test):
1. ✅ Mark as Sold - Inside Junction flow
2. ✅ Mark as Sold - Outside Junction flow
3. ✅ Confirm Deal - Price cannot be modified
4. ✅ Chat button disabled for buyers (sold products)
5. ✅ Rate the Buyer functionality
6. ✅ Document deletion on approval/rejection

### High Priority:
1. ✅ Error handling - User-friendly messages
2. ✅ Location search functionality
3. ✅ Edit description and location in product listing
4. ✅ Product card deduplication in chat

### Medium Priority:
1. ✅ Admin dashboard stats API
2. ✅ Notification icon dynamic display
3. ✅ Get product chats API

---

## Notes for Tester:

1. **Test Environment:** Ensure you're testing on the latest build with all changes
2. **Backend:** Verify backend APIs are deployed with latest changes
3. **Database:** Some tests require existing data (products, chats, orders)
4. **S3 Access:** Document deletion tests require S3 bucket access verification
5. **Network:** Test error handling with various network conditions
6. **Permissions:** Ensure admin access for admin-related tests

---

## Test Sign-off

**Tester Name:** ________________  
**Date:** ________________  
**Build Version:** ________________  
**Overall Status:** ☐ Pass / ☐ Fail / ☐ Partial  

**Comments:**
_________________________________________________
_________________________________________________
_________________________________________________

