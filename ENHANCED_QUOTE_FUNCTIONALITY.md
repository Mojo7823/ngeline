# Enhanced Quote Message Functionality

## Overview

The enhanced quote message functionality has been implemented to properly handle LINE chat message quoting with full context retrieval. This solution addresses the three main requirements:

1. **Save message ID into database**
2. **Return initial message content instead of just ID**
3. **Update nodes to understand these requirements**

## Architecture Changes

### New Components Added

1. **Prepare Message Data** - Formats message data for database storage
2. **Save Message to Database** - Stores messages in Supabase
3. **Check If Quoted Message** - Determines if current message is quoting another
4. **Get Quoted Message** - Retrieves original quoted message content
5. **Enhanced Message Processor** - Updated processor with quote context

### Database Schema

A new table `line_messages` has been created with the following structure:

```sql
CREATE TABLE line_messages (
    id BIGSERIAL PRIMARY KEY,
    message_id VARCHAR(255) UNIQUE NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    message_text TEXT NOT NULL,
    reply_token VARCHAR(255),
    timestamp TIMESTAMPTZ NOT NULL,
    quote_token TEXT,
    quoted_message_id VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    processed BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Workflow Process

### 1. Message Reception
- Webhook receives LINE message event
- Filter ensures it's a message event
- Original Message Processor extracts basic data

### 2. Message Storage
- **Prepare Message Data**: Formats data for database
- **Save Message to Database**: Stores message in `line_messages` table with upsert logic

### 3. Quote Processing
- **Check If Quoted Message**: Determines if `quotedMessageId` exists
  - If YES: Routes to **Get Quoted Message**
  - If NO: Routes directly to **Enhanced Message Processor**

### 4. Quote Retrieval
- **Get Quoted Message**: Queries database for original message content using `quotedMessageId`
- Returns the full message record including `message_text`

### 5. Enhanced Processing
- **Enhanced Message Processor**: Creates enriched message object with:
  - Original message data
  - Quoted message content (if available)
  - Contextual processing text

### 6. AI Processing & Response
- Context-aware prompt includes quoted message content
- AI generates response with full context
- Response sent to LINE with proper quote token

## Key Features

### Before (Problems)
- Only message ID available: `[Replying to message ID: 574320679035076899]`
- No context for AI to understand what was being replied to
- Messages not stored for future reference

### After (Solutions)
- Full message content: `[Replying to message "Do you know about capital in Malaysia"]`
- AI has complete context of the conversation
- All messages stored for quote functionality and history

## Data Flow Example

### Input (LINE Webhook):
```json
{
  "message": {
    "id": "574320153420890507",
    "quoteToken": "1o6_3QXgMq3-b4UDwvX5gEt3N0PgxpPPWjHv2ByD7eJ...",
    "quotedMessageId": "574320679035076899",
    "text": "Okay, thank you"
  }
}
```

### Database Query Result:
```json
{
  "message_id": "574320679035076899",
  "message_text": "Do you know about capital in Malaysia",
  "user_id": "U4e24623df14cb937673f6d7c0ab55b43"
}
```

### Enhanced Processor Output:
```json
{
  "processedText": "[Replying to message \"Do you know about capital in Malaysia\"] Okay, thank you",
  "isQuotedMessage": true,
  "quotedMessageText": "Do you know about capital in Malaysia"
}
```

### AI Context:
```
Note: This message is a reply to a previous message: "Do you know about capital in Malaysia". Please consider this context when responding.

User message: Okay, thank you
```

## Setup Instructions

### 1. Database Setup
Run the SQL script in your Supabase SQL editor:
```bash
# The setup_line_messages_table.sql file contains all necessary DDL
```

### 2. n8n Workflow Configuration
The workflow has been updated with the following node connections:

```
Webhook Entry → Filter Message Events → Message Processor → Prepare Message Data → Save Message to Database → Check If Quoted Message
                                                                                                                    ↓
Enhanced Message Processor ← Get Quoted Message (if quoted) ←──────────────────────────────────────────────────┘
         ↓                         ↑
Start Loading Animation            │
         ↓                         │
AI Language Model ←────────────────┘ (if not quoted)
         ↓
Process AI Response
         ↓
Send Response to LINE
```

### 3. Node Configuration Details

#### Save Message to Database
- **Operation**: Insert
- **Table**: `line_messages`
- **Conflict Resolution**: Ignore (prevents duplicates)

#### Check If Quoted Message
- **Condition**: `quotedMessageId` is not empty
- **True Path**: Get Quoted Message
- **False Path**: Enhanced Message Processor

#### Get Quoted Message
- **Operation**: Get All
- **Filter**: `message_id=eq.{{ $json.quotedMessageId }}`
- **Limit**: 1

## Testing

### Test Case 1: Regular Message
1. Send: "Hello, how are you?"
2. Expected: Normal processing, message saved to database
3. AI Response: Regular response without quote context

### Test Case 2: Quoted Message
1. Quote previous message and send: "Can you elaborate?"
2. Expected: 
   - System retrieves original message content
   - AI gets full context: `[Replying to message "Hello, how are you?"] Can you elaborate?`
   - Response considers the quoted context

### Test Case 3: Quote Non-existent Message
1. Quote a message that's not in database
2. Expected: Falls back to ID-based processing
3. AI gets: `[Replying to message ID: xxxxx] Can you elaborate?`

## Error Handling

1. **Database Connection Issues**: Falls back to basic processing
2. **Missing Quoted Message**: Uses ID-based fallback
3. **Malformed Data**: Graceful error handling with user notification

## Performance Considerations

1. **Database Indexes**: Created on frequently queried columns
2. **Message Retention**: Consider implementing cleanup for old messages
3. **Connection Pooling**: Supabase handles connection management
4. **Query Optimization**: Single query per quote lookup

## Security

1. **Row Level Security**: Enabled on `line_messages` table
2. **Data Validation**: Input sanitization in processing nodes
3. **Access Control**: Supabase API credentials managed securely

## Monitoring

Monitor the following metrics:
- Message processing success rate
- Quote retrieval success rate
- Database connection health
- Response time for quoted vs non-quoted messages

## Future Enhancements

1. **Message Threading**: Support for conversation threads
2. **Media Message Quotes**: Handle image/video quotes
3. **Quote Analytics**: Track quote usage patterns
4. **Batch Processing**: Handle multiple messages efficiently
5. **Message Search**: Allow users to search conversation history
