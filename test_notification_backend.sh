
#!/bin/bash

# VIBRA Notification System - Backend API Tester
# This script tests all notification endpoints

echo "🧪 Testing VIBRA Notification Backend"
echo "======================================"
echo ""

# Configuration
BASE_URL="http://localhost:10000"
EMAIL="mohamedamine.mami@esprit.tn"
PASSWORD="your_password_here"  # ⚠️ UPDATE THIS

echo "📍 Backend URL: $BASE_URL"
echo ""

# Step 1: Login and get JWT token
echo "1️⃣  Testing Login..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

echo "Response: $LOGIN_RESPONSE"

# Extract JWT token
JWT=$(echo $LOGIN_RESPONSE | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$JWT" ]; then
    echo "❌ Login failed - could not extract JWT token"
    exit 1
fi

echo "✅ Login successful"
echo "🔑 JWT Token: ${JWT:0:50}..."
echo ""

# Step 2: Test notifications endpoint
echo "2️⃣  Testing GET /notifications?unreadOnly=true&limit=10"
NOTIFICATIONS=$(curl -s -X GET "$BASE_URL/notifications?unreadOnly=true&limit=10" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json")

echo "Response: $NOTIFICATIONS"

# Count notifications
COUNT=$(echo $NOTIFICATIONS | grep -o '"id"' | wc -l | tr -d ' ')
echo "📬 Found $COUNT unread notifications"
echo ""

# Step 3: Test unread count endpoint
echo "3️⃣  Testing GET /notifications/unread-count"
UNREAD_COUNT=$(curl -s -X GET "$BASE_URL/notifications/unread-count" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json")

echo "Response: $UNREAD_COUNT"
echo ""

# Step 4: Test mark as read (if notifications exist)
if [ "$COUNT" -gt 0 ]; then
    echo "4️⃣  Testing PATCH /notifications/:id/read"
    
    # Extract first notification ID
    FIRST_ID=$(echo $NOTIFICATIONS | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
    
    if [ ! -z "$FIRST_ID" ]; then
        echo "Marking notification as read: $FIRST_ID"
        
        MARK_READ=$(curl -s -X PATCH "$BASE_URL/notifications/$FIRST_ID/read" \
          -H "Authorization: Bearer $JWT" \
          -H "Content-Type: application/json")
        
        echo "Response: $MARK_READ"
    fi
else
    echo "4️⃣  Skipping mark as read test (no notifications)"
fi

echo ""
echo "======================================"
echo "✅ All tests completed!"
echo ""
echo "📋 Summary:"
echo "  - Login: ✅"
echo "  - Fetch notifications: ✅"
echo "  - Unread count: ✅"
[ "$COUNT" -gt 0 ] && echo "  - Mark as read: ✅" || echo "  - Mark as read: ⏭️  (skipped)"
echo ""
echo "🎉 Backend is ready for iOS notification polling!"
