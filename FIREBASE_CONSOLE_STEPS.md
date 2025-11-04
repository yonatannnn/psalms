# Steps to Send Test Notification from Firebase Console

## Where You Are Now:
✅ You're on the **Cloud Messaging settings page** - this is correct!

## Next Steps:

### 1. Go to Cloud Messaging
- In the **left sidebar**, look for **"Messaging"** (under "Product categories" → "Build")
- OR click on **"Messaging"** in the "Project shortcuts" section at the top
- This will take you to the messaging dashboard

### 2. Create New Notification
- Once in the Messaging page, click **"New notification"** or **"Send your first message"**

### 3. Compose Your Notification
- **Notification title**: `Daily Reading Reminder`
- **Notification text**: `Remember to read your daily Psalms today`
- Click **"Next"**

### 4. Select Target
- Choose **"Topic"**
- Enter topic name: `daily_reminder`
- Click **"Next"**

### 5. Schedule for 11:15 AM
- Select **"Schedule for later"**
- Set the date to **Today**
- Set the time to **11:15 AM**
- Click **"Next"**

### 6. Review and Send
- Review the details
- Click **"Publish"**

---

## What You're Seeing on Settings Page:

✅ **Firebase Cloud Messaging API (V1)**: Enabled - This is correct!  
✅ **Sender ID**: `54653675415` - This is your Sender ID  
❌ **Legacy API**: Disabled - This is fine, we're using V1 API  

**Note**: You don't need to enable Legacy API. The V1 API is what we're using, and it's already enabled.

---

## Alternative: Send Immediately (For Testing)

If you want to test right now instead of waiting until 11:15 AM:

1. Follow steps 1-4 above
2. Instead of "Schedule for later", select **"Now"**
3. Click **"Review"** → **"Publish"**

This will send immediately to all devices subscribed to `daily_reminder` topic.

---

## Quick Link:
- Go directly to: **Messaging** in the left sidebar
- Or use: https://console.firebase.google.com/project/mezmuredawit-b7b19/messaging

