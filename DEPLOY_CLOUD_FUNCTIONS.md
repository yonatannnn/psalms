# Deploy Cloud Functions for Daily 6 AM Reminder

## Overview

Cloud Functions will send daily push notifications at 6 AM in Amharic to all users subscribed to the `daily_reminder` topic.

## Prerequisites

1. **Node.js** installed (version 18 or higher)
   - Check: `node --version`
   - Install: https://nodejs.org/

2. **Firebase CLI** installed
   - Install: `npm install -g firebase-tools`
   - Login: `firebase login`

3. **Firebase Blaze Plan** (required for Cloud Functions)
   - Go to Firebase Console > Usage and billing
   - Upgrade to Blaze plan (pay-as-you-go, free tier available)

## Setup Steps

### 1. Initialize Firebase Functions (if not already done)

```bash
cd /home/yonatan/Desktop/mezmure_dawit
firebase init functions
```

When prompted:
- Select **JavaScript** (or TypeScript if you prefer)
- Install dependencies? **Yes**
- Use ESLint? **Yes** (optional)

### 2. Install Dependencies

```bash
cd functions
npm install
```

### 3. Deploy Functions

```bash
# From project root
firebase deploy --only functions
```

Or deploy specific function:
```bash
firebase deploy --only functions:sendDailyReminder
```

### 4. Verify Deployment

1. Go to Firebase Console > Functions
2. You should see `sendDailyReminder` function listed
3. Check the logs: `firebase functions:log`

## What Gets Deployed

### 1. `sendDailyReminder`
- **Schedule**: Daily at 6:00 AM (Ethiopia timezone)
- **Target**: All users subscribed to `daily_reminder` topic
- **Language**: Amharic
- **Message**:
  - Title: `የዕለታዊ ንባብ ማስታወሻ`
  - Body: `ዛሬ የመዝሙረ ዳዊት ንባብዎን ያስታውሱ`

### 2. `sendMessageNotification`
- **Trigger**: When a new message is created in Firestore
- **Target**: Specific user (using their FCM token)
- **Language**: Based on user's language preference

## Testing

### Test Daily Reminder Function

1. **Manual trigger** (for testing):
   ```bash
   firebase functions:shell
   sendDailyReminder()
   ```

2. **Test via Firebase Console**:
   - Go to Functions > `sendDailyReminder`
   - Click "Test" button
   - Run the function

### Test Message Notification

1. Send a message from one user to another in the app
2. The receiver should receive a push notification
3. Check function logs for any errors

## Timezone Configuration

The function is set to Ethiopia timezone (`Africa/Addis_Ababa`). To change:

Edit `functions/index.js`:
```javascript
.timeZone('Africa/Addis_Ababa') // Change to your timezone
```

Common timezones:
- `Africa/Addis_Ababa` - Ethiopia
- `America/New_York` - EST
- `Europe/London` - GMT
- `Asia/Dubai` - UAE

## Monitoring

### View Logs
```bash
firebase functions:log
```

### View in Console
- Firebase Console > Functions > Select function > Logs tab

### Set Up Alerts
- Firebase Console > Functions > Select function > Monitoring
- Set up alerts for errors

## Troubleshooting

### Function not running
- Check Firebase Blaze plan is active
- Verify function is deployed: `firebase functions:list`
- Check logs for errors

### Notifications not received
- Verify users are subscribed to `daily_reminder` topic
- Check FCM tokens are saved in Firestore
- Verify notification permissions are granted

### Timezone issues
- Check function timezone matches your location
- Verify cron schedule: `0 6 * * *` (6 AM daily)

## Cost Considerations

- **Free Tier**: 2 million function invocations/month
- **After Free Tier**: $0.40 per million invocations
- Daily reminder = ~30 invocations/month per user
- Very affordable for most apps

## Next Steps

1. Deploy the functions
2. Test with a manual trigger
3. Wait for first 6 AM reminder
4. Monitor logs for any issues

---

**Note**: The daily reminder will be sent in **Amharic** as requested. All users will receive the same message in Amharic.

