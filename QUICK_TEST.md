# Quick Test - Send Notification at 11:15 AM

## ⚡ Fastest Method: Firebase Console (Recommended)

Since it's currently 11:11 AM, here's how to send a test notification at 11:15 AM:

### Steps:

1. **Open Firebase Console**:
   - Go to: https://console.firebase.google.com/project/mezmuredawit-b7b19

2. **Navigate to Cloud Messaging**:
   - Click **"Cloud Messaging"** in the left sidebar
   - Click **"New notification"** or **"Send your first message"**

3. **Compose Notification**:
   - **Notification title**: `Daily Reading Reminder`
   - **Notification text**: `Remember to read your daily Psalms today`

4. **Select Target**:
   - Click **"Next"**
   - Select **"Topic"**
   - Enter: `daily_reminder`
   - Click **"Next"**

5. **Schedule for 11:15 AM**:
   - Select **"Schedule for later"**
   - Set date to **Today**
   - Set time to **11:15 AM**
   - Click **"Next"**

6. **Send**:
   - Click **"Review"**
   - Click **"Publish"**

That's it! The notification will be sent at 11:15 AM to all devices subscribed to `daily_reminder` topic.

---

## Alternative: Send Immediately (For Testing)

If you want to test right now instead of waiting:

1. Follow steps 1-4 above
2. Instead of "Schedule for later", select **"Now"**
3. Click **"Review"** > **"Publish"**

---

## Verify Your App is Ready

Before sending, make sure:
1. ✅ App is installed and running
2. ✅ User is logged in
3. ✅ App has subscribed to `daily_reminder` topic (happens automatically on app start)

You can check the app console/logs for:
- `FCM Token: ...`
- `Subscribed to topic: daily_reminder`

---

## If You Want to Use Python Script

1. Get your FCM Server Key:
   - Firebase Console > Project Settings > Cloud Messaging > **Server key** (Legacy)

2. Edit `test_notification.py`:
   - Replace `YOUR_FCM_SERVER_KEY_HERE` with your server key

3. Run:
   ```bash
   python3 test_notification.py
   ```

The script will wait until 11:15 AM and send automatically.

---

**Note**: Make sure your app is running and the user is logged in to receive the notification!

