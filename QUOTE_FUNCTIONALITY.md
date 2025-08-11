# Quote Message Implementation

## Overview
I've implemented the LINE quote message functionality so your bot can now quote the user's original message when responding. This creates a visual reference in the chat showing which message the bot is replying to.

## How Quote Messages Work in LINE

### Visual Appearance
When the bot quotes a user message, it appears in LINE like this:
```
User: "How do I make sushi?"

Bot: [Quotes: "How do I make sushi?"]
     "To make sushi, you'll need sushi rice, nori seaweed..."
```

### LINE API Implementation
```javascript
// Response with quote
{
  "replyToken": "...",
  "messages": [
    {
      "type": "text",
      "text": "To make sushi, you'll need...",
      "quoteToken": "vHttfmWVAP7tpEeSDmZQ..."  // This creates the quote
    }
  ]
}
```

## Implementation Details

### 1. Message Processor Enhancement
**Added quote configuration:**
```javascript
const messageObj = {
  // ... existing fields
  shouldQuoteInResponse: true  // Controls whether to quote user messages
};
```

### 2. Process AI Response Enhancement
**Added quote token handling:**
```javascript
// Add quote token to quote the user's original message in the response
if (messageProcessor.json.shouldQuoteInResponse && messageProcessor.json.quoteToken) {
  lineMessage.quoteToken = messageProcessor.json.quoteToken;
}
```

### 3. Quote Token Flow
```
User Message → Webhook → Contains quoteToken → Message Processor → 
Process AI Response → Adds quoteToken to response → LINE API → 
Displays quoted message in chat
```

## Configuration Options

### Option 1: Quote Every Message (Current Setting)
```javascript
shouldQuoteInResponse: true
```
- **Result**: Every bot response quotes the user's message
- **Use Case**: Clear conversation threading, great for support bots
- **Visual**: Every response shows what it's replying to

### Option 2: No Quoting
```javascript
shouldQuoteInResponse: false
```
- **Result**: Clean responses without quotes
- **Use Case**: Casual conversation, cleaner chat appearance
- **Visual**: Standard chat without quote references

### Option 3: Conditional Quoting (Future Enhancement)
```javascript
// Example: Only quote long messages or complex questions
shouldQuoteInResponse: messageText.length > 50 || messageText.includes('?')
```

## Benefits of Quote Implementation

### ✅ **Better Context**
- Users can see exactly which message the bot is responding to
- Helpful in rapid conversation with multiple questions
- Clear conversation threading

### ✅ **Professional Appearance**
- Mimics human conversation patterns
- Standard in modern chat applications
- Better user experience

### ✅ **Multi-Message Support**
When users send multiple messages:
```
User: "How are you?"
User: "What's the weather?"
User: "Can you help me?"

Bot: [Quotes: "How are you?"] "I'm doing well, thanks!"
Bot: [Quotes: "What's the weather?"] "I can't check weather, but..."
Bot: [Quotes: "Can you help me?"] "Of course! What do you need help with?"
```

## Testing the Quote Functionality

### Test Case 1: Simple Message
**Send:** "Hello"
**Expected:** Bot response with "Hello" quoted above it

### Test Case 2: Question
**Send:** "What's your favorite food?"
**Expected:** Bot response with the question quoted above the answer

### Test Case 3: Long Message
**Send:** "Can you please explain to me in detail how to make traditional Japanese sushi rice?"
**Expected:** Bot response with the long question quoted (may be truncated in display)

### Test Case 4: Multiple Messages
**Send rapidly:**
1. "Hi there"
2. "How are you?"
3. "What can you do?"

**Expected:** Three separate responses, each quoting its respective message

## Quote Token Details

### What is a Quote Token?
- **Unique identifier** for each message sent in LINE
- **Provided by LINE** in webhook events
- **Used to reference** that specific message in responses
- **No expiration** - can be used multiple times

### Example Quote Token:
```
"quoteToken": "vHttfmWVAP7tpEeSDmZQhoXRn7D_oQ9u6hJiMvwf4MgDR51TXj-OtLNNDozZHInPy7U_kd7enDq4dgeBbY_Lm7WKaIwO8qY7rdIVhol8bHkXVK8Aeao4bW5zlv1zOYR3WgAlOvuZ4z0T2iK3SqB90g"
```

### Data Flow:
```
LINE User Message → Webhook (contains quoteToken) → 
Message Processor (stores quoteToken) → 
Process AI Response (adds to LINE message) → 
LINE API (creates visual quote) → 
User sees quoted message
```

## Customization Options

### To Disable Quoting:
Change in Message Processor:
```javascript
shouldQuoteInResponse: false
```

### To Enable Smart Quoting:
```javascript
// Only quote questions or long messages
shouldQuoteInResponse: messageText.includes('?') || messageText.length > 100
```

### To Quote Only Specific Keywords:
```javascript
// Only quote messages containing certain words
const keywordsToQuote = ['help', 'question', 'explain', 'how to'];
shouldQuoteInResponse: keywordsToQuote.some(keyword => 
  messageText.toLowerCase().includes(keyword)
);
```

## Integration with Existing Features

### ✅ **Compatible with Multi-Message Handling**
- Each message gets quoted individually
- Maintains conversation context

### ✅ **Compatible with Text Length Limits**
- Quote tokens don't count toward text length
- Bot response can still be truncated if needed

### ✅ **Compatible with Loading Animation**
- Quote appears after loading animation completes
- Normal workflow timing preserved

### ✅ **Compatible with Chat Memory**
- Quoted messages still stored in conversation history
- Memory system unchanged

## Troubleshooting

### If Quotes Don't Appear:
1. **Check webhook data** - ensure `quoteToken` is present
2. **Verify configuration** - `shouldQuoteInResponse: true`
3. **Check LINE app version** - quotes may not work on very old versions
4. **Test with different message types** - some messages may not have quote tokens

### If Quotes Appear Incorrectly:
1. **Check message timing** - rapid messages may have token conflicts
2. **Verify LINE API response** - check for errors in Send Response node
3. **Test different message lengths** - very long messages may behave differently

Your bot now supports full quote functionality! Users will see their original message quoted above each bot response, creating a much clearer and more professional conversation experience.
