# Loading Animation Implementation

## Overview
I've successfully added a loading animation feature to your LINE chatbot workflow. When a user sends a message, the bot will now show a loading animation while processing the AI response.

## Changes Made

### 1. Added Filter Node
- **Node Name**: "Filter Message Events"
- **Type**: IF condition
- **Purpose**: Only process events that are message types (ignores follow/unfollow events)
- **Condition**: `$json.body.events[0].type` equals "message"

### 2. Added Loading Animation Node
- **Node Name**: "Start Loading Animation"
- **Type**: HTTP Request
- **Position**: Between Filter and AI Language Model
- **Purpose**: Triggers the LINE loading animation API when a user message is received

### 3. Node Configuration
```json
{
  "method": "POST",
  "url": "https://api.line.me/v2/bot/chat/loading/start",
  "headers": {
    "Content-Type": "application/json",
    "Authorization": "Bearer [YOUR_CHANNEL_ACCESS_TOKEN]"
  },
  "body": {
    "chatId": "[USER_ID_FROM_WEBHOOK]",
    "loadingSeconds": 30
  },
  "options": {
    "ignoreHttpStatusErrors": true
  }
}
```

### 4. Fixed AI Language Model Node
- Updated prompt reference to use `$('Webhook Entry').item.json.body.events[0].message.text`
- This ensures the AI model receives the correct message text from the webhook

### 5. Updated Workflow Flow
The new message flow is:
1. **Webhook Entry** - Receives user message
2. **Filter Message Events** - Only processes message events
3. **Start Loading Animation** - Shows loading animation (30 seconds max)
4. **AI Language Model** - Processes the message with Google Gemini
5. **Process AI Response** - Cleans the AI response
6. **Send Response to LINE** - Sends reply (automatically stops loading animation)

## Bug Fixes Applied

### Issue 1: "No prompt specified" Error
**Problem**: AI Language Model was expecting `chatInput` field from chat trigger
**Solution**: Updated prompt to reference webhook data: `$('Webhook Entry').item.json.body.events[0].message.text`

### Issue 2: Empty Loading Animation Response
**Problem**: Loading animation node was failing silently
**Solution**: 
- Added `ignoreHttpStatusErrors: true` to prevent workflow interruption
- Fixed data reference to use `$json.body.events[0].source.userId` instead of nested reference

### Issue 3: Non-message Events
**Problem**: Workflow would try to process follow/unfollow events
**Solution**: Added filter node to only process message type events

## Key Features

### Loading Duration
- Set to **30 seconds** maximum
- Animation automatically disappears when the bot sends a response
- If processing takes longer than 30 seconds, animation will stop but processing continues

### Error Handling
- Loading animation failures won't stop the workflow
- Only message events are processed (ignores follow/unfollow events)
- Proper data referencing prevents "undefined" errors

### User Experience
- Loading animation only shows when user is viewing the chat screen
- Animation provides immediate feedback that the message was received
- Professional appearance while waiting for AI response

### Technical Details
- Uses LINE's official chat loading API
- Extracts `userId` from the webhook event as `chatId`
- Leverages the same authorization token as your message reply API
- Proper error handling to ensure workflow continuity

## API Reference
Based on LINE's loading animation documentation:
- **Endpoint**: `POST https://api.line.me/v2/bot/chat/loading/start`
- **Duration**: 5-60 seconds (we use 30 seconds)
- **Auto-dismiss**: When new message arrives from bot
- **Visibility**: Only when user is viewing the chat screen

## Benefits
1. **Better UX**: Users see immediate feedback
2. **Professional Feel**: Indicates the bot is processing
3. **Reduced Confusion**: Users know their message was received
4. **Automatic Management**: No need to manually stop the animation
5. **Robust Error Handling**: Workflow continues even if loading animation fails
6. **Event Filtering**: Only processes relevant message events

The loading animation will now activate every time a user sends a message to your LINE chatbot, providing a smooth and professional user experience while the AI generates its response.
