#!/usr/bin/env python3
"""
Simple script to send a test push notification via FCM REST API
Usage: python3 test_notification.py
"""
import requests
import json
from datetime import datetime
import time

# Configuration - REPLACE WITH YOUR VALUES
FCM_SERVER_KEY = "YOUR_FCM_SERVER_KEY_HERE"  # Get from Firebase Console > Project Settings > Cloud Messaging
PROJECT_ID = "mezmuredawit-b7b19"  # Your Firebase project ID

def send_notification_to_topic(topic="daily_reminder", title="Test Notification", body="This is a test notification"):
    """Send a push notification to a topic"""
    
    url = f"https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send"
    
    headers = {
        "Authorization": f"Bearer {FCM_SERVER_KEY}",
        "Content-Type": "application/json"
    }
    
    # For legacy API (easier, but requires server key)
    # Using legacy API endpoint
    legacy_url = "https://fcm.googleapis.com/fcm/send"
    
    payload = {
        "to": f"/topics/{topic}",
        "notification": {
            "title": title,
            "body": body,
            "sound": "default"
        },
        "data": {
            "type": "test",
            "timestamp": datetime.now().isoformat()
        },
        "priority": "high"
    }
    
    response = requests.post(legacy_url, headers={
        "Authorization": f"key={FCM_SERVER_KEY}",
        "Content-Type": "application/json"
    }, data=json.dumps(payload))
    
    if response.status_code == 200:
        print(f"✅ Notification sent successfully!")
        print(f"Response: {response.json()}")
        return True
    else:
        print(f"❌ Failed to send notification")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        return False

def send_at_time(target_hour=11, target_minute=15):
    """Wait until target time and send notification"""
    while True:
        now = datetime.now()
        current_time = now.strftime("%H:%M")
        target_time = f"{target_hour:02d}:{target_minute:02d}"
        
        print(f"Current time: {current_time}, Target: {target_time}")
        
        if current_time >= target_time:
            print(f"\n🎯 Target time reached! Sending notification...")
            send_notification_to_topic(
                title="Daily Reading Reminder",
                body="Remember to read your daily Psalms today"
            )
            break
        else:
            # Wait 30 seconds before checking again
            time.sleep(30)

if __name__ == "__main__":
    print("=" * 50)
    print("FCM Push Notification Test Script")
    print("=" * 50)
    print("\n⚠️  IMPORTANT: You need to configure this script first!")
    print("\n1. Get your FCM Server Key from:")
    print("   Firebase Console > Project Settings > Cloud Messaging > Server Key")
    print("\n2. Get your Project ID from:")
    print("   Firebase Console > Project Settings > General")
    print("\n3. Replace the values in this script")
    print("\n" + "=" * 50)
    
    # Check if configured
    if FCM_SERVER_KEY == "YOUR_FCM_SERVER_KEY_HERE" or PROJECT_ID == "YOUR_PROJECT_ID_HERE":
        print("\n❌ Please configure FCM_SERVER_KEY and PROJECT_ID first!")
        print("\nTo send immediately, uncomment the line below:")
        print("# send_notification_to_topic()")
        exit(1)
    
    # Send immediately for testing
    print("\nSending test notification now...")
    send_notification_to_topic()
    
    # Or schedule for 11:15 AM
    # print("\nWaiting until 11:15 AM to send notification...")
    # send_at_time(11, 15)

