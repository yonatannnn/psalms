# How to Send a Test Push Notification

## Option 1: Using Firebase Console (Easiest - Recommended for Testing)

1. **Go to Firebase Console**:
   - Visit [https://console.firebase.google.com/](https://console.firebase.google.com/)
   - Select your project

2. **Navigate to Cloud Messaging**:
   - Click on **"Cloud Messaging"** in the left sidebar
   - Click **"Send your first message"** or **"New notification"**

3. **Compose Your Notification**:
   - **Notification title**: `Daily Reading Reminder` or `Test Notification`
   - **Notification text**: `Remember to read your daily Psalms today` or `This is a test notification`

4. **Select Target**:
   - Click **"Next"**
   - Under **"Target"**, select **"Topic"**
   - Enter topic name: `daily_reminder`
   - Click **"Next"**

5. **Schedule (Optional)**:
   - For immediate send: Click **"Now"**
   - For scheduled: Select **"Schedule for later"** and choose date/time

6. **Send**:
   - Click **"Review"** > **"Publish"**

Your notification will be sent to all devices subscribed to the `daily_reminder` topic!

---

## Option 2: Using Python Script (For Scheduled Notifications)

### Setup:

1. **Install Python requests library** (if not installed):
   ```bash
   pip3 install requests
   ```

2. **Get your FCM Server Key**:
   - Go to Firebase Console > **Project Settings** > **Cloud Messaging**
   - Copy the **Server key** (Legacy server key)

3. **Get your Project ID**:
   - Go to Firebase Console > **Project Settings** > **General**
   - Copy the **Project ID**

4. **Edit the script** (`test_notification.py`):
   - Replace `YOUR_FCM_SERVER_KEY_HERE` with your server key
   - Replace `YOUR_PROJECT_ID_HERE` with your project ID

5. **Run the script**:
   ```bash
   python3 test_notification.py
   ```

### To Schedule for 11:15 AM:

Edit `test_notification.py` and uncomment the last line:
```python
# send_at_time(11, 15)
```

Then run:
```bash
python3 test_notification.py
```

The script will wait until 11:15 AM and then send the notification.

---

## Option 3: Using cURL (Quick Test)

Replace `YOUR_SERVER_KEY` with your FCM Server Key:

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "/topics/daily_reminder",
    "notification": {
      "title": "Daily Reading Reminder",
      "body": "Remember to read your daily Psalms today"
    },
    "data": {
      "type": "daily_reminder"
    }
  }'
```

---

## Quick Test Right Now (Firebase Console)

**Fastest way to test**:

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **Cloud Messaging** > **New notification**
4. Enter:
   - Title: `Test Notification`
   - Text: `Testing push notifications at 11:15 AM`
5. Click **Next**
6. Select **Topic** → `daily_reminder`
7. Click **Next** > **Schedule for later**
8. Set time to **11:15 AM** (today or tomorrow)
9. Click **Review** > **Publish**

---

## Verify It Works

1. **Check the app console** for:
   - `FCM Token: ...` (when app starts)
   - `Subscribed to topic: daily_reminder`
   - `Received foreground message: ...` (when notification arrives)

2. **Check Firestore**:
   - Go to Firestore Database
   - Check `users/{userId}/fcmToken` exists

3. **Test on device**:
   - Make sure the app is installed and logged in
   - Send a test notification
   - You should see the notification appear

---

## Troubleshooting

- **No notification received**: 
  - Check that notification permissions are granted
  - Verify the app is subscribed to `daily_reminder` topic
  - Check device is connected to internet

- **Token not saved**:
  - Check Firestore security rules
  - Verify user is authenticated

- **Script errors**:
  - Make sure you copied the Server Key correctly
  - Verify Python requests library is installed

