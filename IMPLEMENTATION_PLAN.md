# N8N Node Functions Implementation Plan

This document provides a detailed node planning.

---

## 📋 Module 1: Message Processing Functions

### 1.1 Webhook Entry Function
```javascript
// Function: handleLineWebhook()
// Purpose: Receive and validate LINE webhook messages
// Implementation Requirements:
```

**Function Signature:**
```javascript
async function handleLineWebhook(req, res) {
  // Input: HTTP request from LINE webhook
  // Output: Validated webhook payload
}
```

**Implementation Steps:**
1. **Webhook Validation**
   - Verify LINE signature
   - Validate request structure
   - Check event types

2. **Request Processing**
   - Extract event data
   - Parse message content
   - Handle multiple events

3. **Error Handling**
   - Invalid signatures
   - Malformed requests
   - Rate limiting

**Key Features to Implement:**
- Signature verification using LINE Channel Secret
- Request validation and sanitization
- Webhook response acknowledgment
- Error logging and monitoring

---

### 1.2 Message Filter Function
```javascript
// Function: filterMessageEvents()
// Purpose: Filter only text message events from LINE webhooks
```

**Function Signature:**
```javascript
function filterMessageEvents(webhookPayload) {
  // Input: Raw webhook payload
  // Output: Filtered message events or null
}
```

**Implementation Steps:**
1. **Event Type Validation**
   - Check `events[0].type === "message"`
   - Verify message subtype is "text"
   - Filter out system messages

2. **Content Validation**
   - Ensure message has text content
   - Check message is not empty
   - Validate encoding

3. **Flow Control**
   - Return valid events
   - Log filtered events
   - Handle edge cases

---

### 1.3 Message Processor Function
```javascript
// Function: processLineMessage()
// Purpose: Extract and structure message data with quote handling
```

**Function Signature:**
```javascript
function processLineMessage(messageEvent) {
  // Input: LINE message event
  // Output: Structured message object
}
```

**Implementation Steps:**
1. **Data Extraction**
   ```javascript
   const messageObj = {
     userId: event.source.userId,
     messageId: event.message.id,
     messageText: event.message.text,
     replyToken: event.replyToken,
     timestamp: event.timestamp,
     quoteToken: event.message.quoteToken || null,
     quotedMessageId: event.message.quotedMessageId || null
   };
   ```

2. **Quote Handling**
   - Detect quoted messages
   - Format threaded conversations
   - Preserve message context

3. **Message Processing**
   - Text sanitization
   - Length validation
   - Metadata enrichment

**Key Features:**
- Quote token management for threaded replies
- Message threading support
- User session tracking
- Timestamp processing

---

### 1.4 Loading Animation Function
```javascript
// Function: startLoadingAnimation()
// Purpose: Show typing indicator while processing
```

**Function Signature:**
```javascript
async function startLoadingAnimation(chatId, accessToken) {
  // Input: Chat ID and LINE access token
  // Output: Loading animation status
}
```

**Implementation Steps:**
1. **API Call Setup**
   - Prepare LINE API request
   - Set proper headers
   - Format chat ID

2. **Animation Request**
   ```javascript
   const response = await fetch('https://api.line.me/v2/bot/chat/loading/start', {
     method: 'POST',
     headers: {
       'Authorization': `Bearer ${accessToken}`,
       'Content-Type': 'application/json'
     },
     body: JSON.stringify({ chatId })
   });
   ```

3. **Error Handling**
   - Network failures
   - API errors
   - Timeout handling

---

### 1.5 Response Processing Function
```javascript
// Function: processAIResponse()
// Purpose: Format AI response for LINE messaging
```

**Function Signature:**
```javascript
function processAIResponse(aiOutput, messageMetadata) {
  // Input: AI response text and message metadata
  // Output: LINE-formatted message object
}
```

**Implementation Steps:**
1. **Text Processing**
   ```javascript
   function stripMarkdown(text) {
     return text
       .replace(/\*\*([^*]+)\*\*/g, '$1')  // Bold
       .replace(/__([^_]+)__/g, '$1')      // Bold alt
       .replace(/\*([^*]+)\*/g, '$1')      // Italic
       .replace(/_([^_]+)_/g, '$1')        // Italic alt
       .replace(/`([^`]+)`/g, '$1')        // Code
       .replace(/^\\s*[-*+]\\s+/gm, '')   // Lists
       .replace(/^\\s*\\d+\\.\\s+/gm, ''); // Numbered lists
   }
   ```

2. **Length Management**
   ```javascript
   function truncateText(text, maxLength = 4900) {
     if (text.length <= maxLength) return text;
     
     // Smart truncation at sentence boundaries
     const truncated = text.substring(0, maxLength);
     const lastPunctuation = Math.max(
       truncated.lastIndexOf('.'),
       truncated.lastIndexOf('?'),
       truncated.lastIndexOf('!')
     );
     
     if (lastPunctuation > maxLength * 0.8) {
       return truncated.substring(0, lastPunctuation + 1);
     }
     
     const lastSpace = truncated.lastIndexOf(' ');
     return truncated.substring(0, lastSpace) + '...';
   }
   ```

3. **Quote Integration**
   - Add quote tokens for threaded replies
   - Handle quoted message references
   - Format message objects

---

### 1.6 LINE Response Function
```javascript
// Function: sendLineResponse()
// Purpose: Send formatted response to LINE API
```

**Function Signature:**
```javascript
async function sendLineResponse(replyToken, messageText, accessToken, quoteToken = null) {
  // Input: Reply token, message text, access token, optional quote token
  // Output: LINE API response
}
```

**Implementation Steps:**
1. **Message Object Creation**
   ```javascript
   const message = {
     type: "text",
     text: messageText
   };
   
   if (quoteToken) {
     message.quoteToken = quoteToken;
   }
   ```

2. **API Request**
   ```javascript
   const response = await fetch('https://api.line.me/v2/bot/message/reply', {
     method: 'POST',
     headers: {
       'Authorization': `Bearer ${accessToken}`,
       'Content-Type': 'application/json'
     },
     body: JSON.stringify({
       replyToken,
       messages: [message]
     })
   });
   ```

3. **Response Handling**
   - Success confirmation
   - Error logging
   - Retry logic

---

## 📋 Module 2: Database Functions

### 2.1 Database Initialization Functions

#### Create Documents Table Function
```javascript
// Function: createDocumentsTable()
// Purpose: Initialize vector storage with pgvector
```

**Implementation Steps:**
1. **Extension Setup**
   ```sql
   CREATE EXTENSION IF NOT EXISTS vector;
   ```

2. **Table Creation**
   ```sql
   CREATE TABLE IF NOT EXISTS documents (
     id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
     content text NOT NULL,
     metadata jsonb NOT NULL DEFAULT '{}',
     embedding vector(1536), -- Adjust dimension based on model
     created_at timestamp DEFAULT CURRENT_TIMESTAMP
   );
   ```

3. **Index Creation**
   ```sql
   CREATE INDEX IF NOT EXISTS documents_embedding_idx 
   ON documents USING ivfflat (embedding vector_cosine_ops)
   WITH (lists = 100);
   ```

#### Create Metadata Table Function
```javascript
// Function: createDocumentMetadataTable()
// Purpose: Store file metadata and schema information
```

**Table Schema:**
```sql
CREATE TABLE IF NOT EXISTS document_metadata (
  id varchar(255) PRIMARY KEY,
  title varchar(500) NOT NULL,
  url text,
  file_type varchar(50),
  schema text, -- JSON schema for tabular files
  created_at timestamp DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp DEFAULT CURRENT_TIMESTAMP
);
```

#### Create Document Rows Table Function
```javascript
// Function: createDocumentRowsTable()
// Purpose: Store tabular data for SQL queries
```

**Table Schema:**
```sql
CREATE TABLE IF NOT EXISTS document_rows (
  id serial PRIMARY KEY,
  dataset_id varchar(255) NOT NULL,
  row_data jsonb NOT NULL,
  created_at timestamp DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dataset_id) REFERENCES document_metadata(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS document_rows_dataset_idx ON document_rows(dataset_id);
CREATE INDEX IF NOT EXISTS document_rows_data_idx ON document_rows USING GIN(row_data);
```

### 2.2 Data Insertion Functions

#### Insert Document Metadata Function
```javascript
// Function: insertDocumentMetadata()
// Purpose: Store file metadata
```

**Function Signature:**
```javascript
async function insertDocumentMetadata(fileData) {
  // Input: File metadata object
  // Output: Insertion result
}
```

**Implementation:**
```sql
INSERT INTO document_metadata (id, title, url, file_type, schema, created_at)
VALUES ($1, $2, $3, $4, $5, $6)
ON CONFLICT (id) 
DO UPDATE SET 
  title = EXCLUDED.title,
  url = EXCLUDED.url,
  file_type = EXCLUDED.file_type,
  schema = EXCLUDED.schema,
  updated_at = CURRENT_TIMESTAMP;
```

#### Insert Table Rows Function
```javascript
// Function: insertTableRows()
// Purpose: Store tabular data with batch processing
```

**Function Signature:**
```javascript
async function insertTableRows(datasetId, rowsData) {
  // Input: Dataset ID and array of row data
  // Output: Insertion result
}
```

**Implementation:**
```javascript
const insertQuery = `
  INSERT INTO document_rows (dataset_id, row_data)
  VALUES ($1, $2)
`;

// Batch processing for large datasets
for (const rowData of rowsData) {
  await pool.query(insertQuery, [datasetId, JSON.stringify(rowData)]);
}
```

---

## 📋 Module 3: File Processing Functions

### 3.1 Google Drive Integration Functions

#### File Monitor Function
```javascript
// Function: monitorGoogleDriveFiles()
// Purpose: Monitor for file changes in Google Drive
```

**Implementation Steps:**
1. **Drive API Setup**
   - OAuth2 authentication
   - API client initialization
   - Webhook subscription

2. **File Change Detection**
   ```javascript
   async function watchDriveChanges(folderId, webhookUrl) {
     const response = await drive.files.watch({
       fileId: folderId,
       resource: {
         id: uuidv4(),
         type: 'web_hook',
         address: webhookUrl
       }
     });
     return response.data;
   }
   ```

3. **Change Processing**
   - File metadata extraction
   - Change type detection
   - Queue for processing

#### File Download Function
```javascript
// Function: downloadGoogleDriveFile()
// Purpose: Download files from Google Drive
```

**Function Signature:**
```javascript
async function downloadGoogleDriveFile(fileId, accessToken) {
  // Input: File ID and access token
  // Output: File content and metadata
}
```

**Implementation:**
```javascript
async function downloadFile(fileId) {
  const response = await drive.files.get({
    fileId: fileId,
    alt: 'media'
  });
  
  const metadata = await drive.files.get({
    fileId: fileId,
    fields: 'id,name,mimeType,modifiedTime,webViewLink'
  });
  
  return {
    content: response.data,
    metadata: metadata.data
  };
}
```

### 3.2 Content Extraction Functions

#### PDF Text Extraction Function
```javascript
// Function: extractPDFText()
// Purpose: Extract text from PDF files
```

**Implementation:**
```javascript
const pdf = require('pdf-parse');

async function extractPDFText(pdfBuffer) {
  try {
    const data = await pdf(pdfBuffer);
    return {
      text: data.text,
      pages: data.numpages,
      metadata: data.metadata
    };
  } catch (error) {
    throw new Error(`PDF extraction failed: ${error.message}`);
  }
}
```

#### Excel/CSV Extraction Function
```javascript
// Function: extractSpreadsheetData()
// Purpose: Extract data from Excel and CSV files
```

**Implementation:**
```javascript
const XLSX = require('xlsx');

async function extractSpreadsheetData(fileBuffer, fileType) {
  const workbook = XLSX.read(fileBuffer, { type: 'buffer' });
  const sheetName = workbook.SheetNames[0];
  const worksheet = workbook.Sheets[sheetName];
  
  // Extract data as JSON
  const jsonData = XLSX.utils.sheet_to_json(worksheet);
  
  // Extract schema
  const schema = Object.keys(jsonData[0] || {});
  
  return {
    data: jsonData,
    schema: schema,
    sheetNames: workbook.SheetNames
  };
}
```

#### HTML/Docs Extraction Function
```javascript
// Function: extractHTMLText()
// Purpose: Extract text from HTML and Google Docs
```

**Implementation:**
```javascript
const cheerio = require('cheerio');

function extractHTMLText(htmlContent) {
  const $ = cheerio.load(htmlContent);
  
  // Remove script and style elements
  $('script, style').remove();
  
  // Extract text content
  const text = $('body').text() || $.text();
  
  return {
    text: text.replace(/\s+/g, ' ').trim(),
    title: $('title').text() || '',
    headings: $('h1, h2, h3').map((i, el) => $(el).text()).get()
  };
}
```

---

## 📋 Module 4: AI & RAG Functions

### 4.1 Embeddings Functions

#### Generate Embeddings Function
```javascript
// Function: generateEmbeddings()
// Purpose: Create vector embeddings using Google Gemini
```

**Function Signature:**
```javascript
async function generateEmbeddings(textChunks, apiKey) {
  // Input: Array of text chunks and API key
  // Output: Array of vector embeddings
}
```

**Implementation:**
```javascript
const { GoogleGenerativeAI } = require('@google/generative-ai');

async function generateEmbeddings(texts, apiKey) {
  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({ model: 'embedding-001' });
  
  const embeddings = [];
  for (const text of texts) {
    const result = await model.embedContent(text);
    embeddings.push(result.embedding.values);
  }
  
  return embeddings;
}
```

#### Text Splitting Function
```javascript
// Function: splitTextIntoChunks()
// Purpose: Split documents into optimal chunks for embeddings
```

**Implementation:**
```javascript
function splitTextIntoChunks(text, chunkSize = 1000, overlap = 200) {
  const chunks = [];
  let start = 0;
  
  while (start < text.length) {
    let end = start + chunkSize;
    
    // Find sentence boundary
    if (end < text.length) {
      const sentenceEnd = text.lastIndexOf('.', end);
      if (sentenceEnd > start + chunkSize * 0.8) {
        end = sentenceEnd + 1;
      }
    }
    
    chunks.push({
      text: text.substring(start, end).trim(),
      start: start,
      end: end
    });
    
    start = end - overlap;
  }
  
  return chunks;
}
```

### 4.2 Vector Search Functions

#### Semantic Search Function
```javascript
// Function: performSemanticSearch()
// Purpose: Search documents using vector similarity
```

**Function Signature:**
```javascript
async function performSemanticSearch(query, limit = 5, threshold = 0.7) {
  // Input: Search query, result limit, similarity threshold
  // Output: Relevant document chunks with scores
}
```

**Implementation:**
```javascript
async function performSemanticSearch(query, apiKey, limit = 5) {
  // Generate query embedding
  const queryEmbedding = await generateEmbeddings([query], apiKey);
  
  // Perform vector similarity search
  const searchQuery = `
    SELECT 
      content,
      metadata,
      1 - (embedding <=> $1::vector) as similarity
    FROM documents
    WHERE 1 - (embedding <=> $1::vector) > $2
    ORDER BY embedding <=> $1::vector
    LIMIT $3
  `;
  
  const results = await pool.query(searchQuery, [
    JSON.stringify(queryEmbedding[0]),
    0.7, // similarity threshold
    limit
  ]);
  
  return results.rows;
}
```

### 4.3 AI Agent Tools

#### Document Listing Tool
```javascript
// Function: listAvailableDocuments()
// Purpose: AI tool to list available documents
```

**Implementation:**
```javascript
async function listAvailableDocuments() {
  const query = `
    SELECT id, title, file_type, created_at
    FROM document_metadata
    ORDER BY created_at DESC
  `;
  
  const result = await pool.query(query);
  return result.rows;
}
```

#### File Content Tool
```javascript
// Function: getFileContent()
// Purpose: AI tool to get full content of a specific file
```

**Implementation:**
```javascript
async function getFileContent(fileId) {
  const query = `
    SELECT string_agg(content, ' ' ORDER BY metadata->>'chunk_index') as document_text
    FROM documents
    WHERE metadata->>'file_id' = $1
  `;
  
  const result = await pool.query(query, [fileId]);
  return result.rows[0]?.document_text || '';
}
```

#### SQL Query Tool
```javascript
// Function: executeDataQuery()
// Purpose: AI tool to query tabular data
```

**Implementation:**
```javascript
async function executeDataQuery(datasetId, sqlQuery) {
  // Validate query for safety
  if (!isSafeQuery(sqlQuery)) {
    throw new Error('Query contains unsafe operations');
  }
  
  // Execute query on document_rows
  const query = `
    WITH dataset AS (
      SELECT row_data FROM document_rows WHERE dataset_id = $1
    )
    ${sqlQuery}
  `;
  
  const result = await pool.query(query, [datasetId]);
  return result.rows;
}

function isSafeQuery(query) {
  const dangerousKeywords = ['DELETE', 'DROP', 'INSERT', 'UPDATE', 'ALTER'];
  const upperQuery = query.toUpperCase();
  return !dangerousKeywords.some(keyword => upperQuery.includes(keyword));
}
```

---

## 🚀 Implementation Roadmap

### Week 1: Foundation Setup
- [ ] Database schema creation
- [ ] Basic webhook handling
- [ ] Message processing pipeline
- [ ] Error handling framework

### Week 2: Core Features
- [ ] AI agent integration
- [ ] Basic RAG functionality
- [ ] File upload handling
- [ ] Text extraction

### Week 3: Advanced Features
- [ ] Vector embeddings
- [ ] Semantic search
- [ ] SQL query tools
- [ ] File monitoring

### Week 4: Integration & Testing
- [ ] End-to-end testing
- [ ] Performance optimization
- [ ] Security hardening
- [ ] Documentation completion

### Week 5: Deployment & Monitoring
- [ ] Production deployment
- [ ] Monitoring setup
- [ ] User acceptance testing
- [ ] Performance tuning

---

This implementation plan provides the detailed technical specifications needed to build each function. Each function should be implemented with proper error handling, logging, and test coverage.
