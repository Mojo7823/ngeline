# N8N Workflow Node Functions Documentation

This document provides a comprehensive breakdown of all node functions in the ngeline n8n workflow, organized by functional modules.

## 📋 Table of Contents

1. [Message Processing Module](#message-processing-module)
2. [AI & RAG Processing Module](#ai--rag-processing-module)
3. [Document Management Module](#document-management-module)
4. [Database Operations Module](#database-operations-module)
5. [File Processing Module](#file-processing-module)
6. [Integration & Communication Module](#integration--communication-module)
7. [Utility & Support Nodes](#utility--support-nodes)

---

## 🔄 Message Processing Module

### Core Message Flow Nodes

#### 1. **Webhook Entry** (`n8n-nodes-base.webhook`)
- **Purpose**: Entry point for LINE webhook messages
- **Function**: Receives incoming LINE message events via HTTP POST
- **Configuration**: 
  - Path: `line-message`
  - Method: POST
- **Output**: Raw LINE webhook payload

#### 2. **Filter Message Events** (`n8n-nodes-base.if`)
- **Purpose**: Filter only text message events
- **Function**: Checks if event type equals "message"
- **Logic**: `$json.body.events[0].type === "message"`
- **Flow**: Only passes text messages to next nodes

#### 3. **Message Processor** (`n8n-nodes-base.code`)
- **Purpose**: Extract and structure message data
- **Functions**:
  - Extract user ID, message text, reply token
  - Handle quoted messages and quote tokens
  - Process message threading
  - Add timestamp and metadata
- **Key Features**:
  - Quote handling for threaded conversations
  - Message ID tracking
  - User session management
- **Output**: Structured message object

#### 4. **Start Loading Animation** (`n8n-nodes-base.httpRequest`)
- **Purpose**: Show typing indicator to user
- **Function**: Send loading animation via LINE API
- **API**: `https://api.line.me/v2/bot/chat/loading/start`
- **UX**: Provides immediate feedback while AI processes

#### 5. **Process AI Response** (`n8n-nodes-base.code`)
- **Purpose**: Format AI response for LINE messaging
- **Functions**:
  - Strip markdown formatting for mobile
  - Truncate messages to 5000 char limit
  - Handle quote tokens for replies
  - Validate message format
- **Features**:
  - Smart truncation at sentence boundaries
  - Markdown-to-plain-text conversion
  - Character limit compliance

#### 6. **Send Response to LINE** (`n8n-nodes-base.httpRequest`)
- **Purpose**: Send final response to user via LINE API
- **Function**: POST formatted message to LINE reply endpoint
- **API**: `https://api.line.me/v2/bot/message/reply`
- **Headers**: Authorization with LINE Channel Access Token

---

## 🤖 AI & RAG Processing Module

### AI Language Model & Tools

#### 7. **AI Language Model** (`@n8n/n8n-nodes-langchain.agent`)
- **Purpose**: Core AI agent with RAG capabilities
- **Functions**:
  - Natural language understanding
  - Tool selection and execution
  - Multi-language support
  - Context-aware responses
- **Tools Available**:
  - Document search (RAG)
  - Document listing
  - File content extraction
  - SQL data analysis
- **System Prompt**: Prioritizes RAG search, handles quoted messages

#### 8. **AI Guardian (Topic Classifier)** (`@n8n/n8n-nodes-langchain.agent`)
- **Purpose**: To filter user queries and ensure they are on-topic before being passed to the main AI model.
- **Function**: Uses a few-shot prompt to classify if a user's question is related to "cybersecurity", "robotics", "vendor products", or "standardization".
- **Logic**:
  - The prompt contains examples of in-scope and out-of-scope questions to guide the model.
  - It receives the `messageText` from the `Message Processor` node.
  - It outputs "true" if the topic is relevant, and "false" otherwise.
- **Flow**: The output is used by a switch node to either pass the query to the main AI agent or to respond with a message indicating the question is out of scope.

#### 9. **OpenAI Chat Model** (`@n8n/n8n-nodes-langchain.lmChatOpenAi`)
- **Purpose**: OpenAI GPT integration for the AI agent
- **Function**: Provides natural language processing capabilities
- **Configuration**: Connected to OpenAI API with model selection

#### 10. **Postgres Chat Memory** (`@n8n/n8n-nodes-langchain.memoryPostgresChat`)
- **Purpose**: Conversation memory management
- **Function**: Stores and retrieves chat history for context
- **Features**:
  - 50 message history limit
  - User session isolation
  - Persistent storage in PostgreSQL

### AI Tools for Data Access

#### 10. **List Documents** (`n8n-nodes-base.postgresTool`)
- **Purpose**: AI tool to list available documents
- **Function**: Query `document_metadata` table
- **SQL**: `SELECT * FROM document_metadata`
- **Usage**: When user asks "What documents do you have?"

#### 11. **Get File Contents** (`n8n-nodes-base.postgresTool`)
- **Purpose**: AI tool to extract full text from specific document
- **Function**: Aggregate document chunks by file ID
- **SQL**: 
  ```sql
  SELECT string_agg(content, ' ') as document_text
  FROM documents
  WHERE metadata->>'file_id' = $1
  ```
- **Usage**: When RAG search is insufficient

#### 12. **Query Document Rows** (`n8n-nodes-base.postgresTool`)
- **Purpose**: AI tool for SQL queries on tabular data
- **Function**: Execute SQL on `document_rows` table
- **Features**:
  - Data aggregation
  - Filtering and sorting
  - Statistical analysis
- **Usage**: "What were total sales last quarter?"

### Vector Search Components

#### 13. **Postgres PGVector Store4** (`@n8n/n8n-nodes-langchain.vectorStorePGVector`)
- **Purpose**: RAG vector search for AI agent
- **Function**: Semantic search through document embeddings
- **Features**:
  - Similarity search
  - Relevance scoring
  - Source citation
- **Usage**: Primary tool for document Q&A

#### 14. **Embeddings Google Gemini3** (`@n8n/n8n-nodes-langchain.embeddingsGoogleGemini`)
- **Purpose**: Generate embeddings for search queries
- **Function**: Convert user questions to vector embeddings
- **Model**: Google Gemini embeddings API

---

## 📁 Document Management Module

### Document Processing Pipeline

#### 15. **File Created2** (`n8n-nodes-base.googleDriveTrigger`)
- **Purpose**: Monitor Google Drive for new files
- **Function**: Trigger workflow when files are added
- **Configuration**: Watches specific folder(s)
- **Event**: File creation in monitored directories

#### 16. **File Updated2** (`n8n-nodes-base.googleDriveTrigger`)
- **Purpose**: Monitor Google Drive for file updates
- **Function**: Trigger workflow when files are modified
- **Configuration**: Watches for file modifications
- **Event**: File updates in monitored directories

#### 17. **Download File1** (`n8n-nodes-base.googleDrive`)
- **Purpose**: Download files from Google Drive
- **Function**: Fetch file content for processing
- **Features**:
  - Multiple format support
  - Binary and text files
  - Metadata extraction

#### 18. **Set File ID1** (`n8n-nodes-base.set`)
- **Purpose**: Structure file metadata
- **Function**: Extract and set file information
- **Fields**:
  - `file_id`: Unique identifier
  - `file_type`: File format
  - `file_title`: Document name
  - `file_url`: Google Drive URL

### Document Text Extraction

#### 19. **Extract Document Text1** (`n8n-nodes-base.extractFromFile`)
- **Purpose**: Extract text from Google Docs
- **Function**: Convert HTML to plain text
- **Supported**: Google Docs files
- **Output**: Clean text content

#### 20. **Extract HTML** (`n8n-nodes-base.extractFromFile`)
- **Purpose**: Extract content from HTML files
- **Function**: Parse HTML and extract text
- **Supported**: HTML documents
- **Output**: Structured text content

#### 21. **Extract PDF Text1** (`n8n-nodes-base.extractFromFile`)
- **Purpose**: Extract text from PDF files
- **Function**: PDF text extraction
- **Supported**: PDF documents
- **Features**: Page-aware extraction

#### 22. **Extract from Excel1** (`n8n-nodes-base.extractFromFile`)
- **Purpose**: Extract data from Excel files
- **Function**: Parse spreadsheet data
- **Supported**: .xlsx, .xls files
- **Output**: Tabular data with schema

#### 23. **Extract from CSV** (`n8n-nodes-base.extractFromFile`)
- **Purpose**: Extract data from CSV files
- **Function**: Parse comma-separated values
- **Supported**: .csv files
- **Output**: Structured tabular data

---

## 🗄️ Database Operations Module

### Table Creation & Management

#### 24. **Create Documents Table and Match Function** (`n8n-nodes-base.postgres`)
- **Purpose**: Initialize vector storage table
- **Function**: Create `documents` table with pgvector support
- **Schema**:
  ```sql
  CREATE TABLE documents (
    id uuid PRIMARY KEY,
    content text,
    metadata jsonb,
    embedding vector
  );
  ```

#### 25. **Create Document Metadata Table** (`n8n-nodes-base.postgres`)
- **Purpose**: Initialize file metadata storage
- **Function**: Create `document_metadata` table
- **Schema**:
  ```sql
  CREATE TABLE document_metadata (
    id string PRIMARY KEY,
    title string,
    url string,
    schema string,
    created_at timestamp
  );
  ```

#### 26. **Create Document Rows Table (for Tabular Data)** (`n8n-nodes-base.postgres`)
- **Purpose**: Initialize tabular data storage
- **Function**: Create `document_rows` table
- **Schema**:
  ```sql
  CREATE TABLE document_rows (
    id serial PRIMARY KEY,
    dataset_id string,
    row_data jsonb
  );
  ```

### Data Insertion & Updates

#### 27. **Insert Document Metadata** (`n8n-nodes-base.postgres`)
- **Purpose**: Store file metadata
- **Function**: Insert file information into metadata table
- **Data**: File ID, title, URL, type, creation date

#### 28. **Insert Table Rows** (`n8n-nodes-base.postgres`)
- **Purpose**: Store tabular data rows
- **Function**: Insert CSV/Excel data into rows table
- **Features**:
  - Batch insertion
  - JSON column storage
  - Dataset association

#### 29. **Update Schema for Document Metadata** (`n8n-nodes-base.postgres`)
- **Purpose**: Update schema information for tabular files
- **Function**: Add column schema to metadata
- **Usage**: After Excel/CSV processing

### Data Cleanup

#### 30. **Delete Doc Rows (Postgres)1** (`n8n-nodes-base.postgres`)
- **Purpose**: Clean up old document data
- **Function**: Remove existing rows before re-processing
- **Usage**: File update scenarios

#### 31. **Delete Old Data Rows (Postgres)** (`n8n-nodes-base.postgres`)
- **Purpose**: Clean up old tabular data
- **Function**: Remove existing table rows before re-import
- **Usage**: Spreadsheet update scenarios

---

## 🔄 File Processing Module

### Content Processing Flow

#### 32. **Switch1** (`n8n-nodes-base.switch`)
- **Purpose**: Route files by type for appropriate processing
- **Function**: Direct files to correct extraction method
- **Routes**:
  - PDF → PDF text extraction
  - Excel → Excel data extraction
  - CSV → CSV data extraction
  - HTML/Docs → HTML extraction

#### 33. **Loop Over Items** (`n8n-nodes-base.splitInBatches`)
- **Purpose**: Process multiple items in batches
- **Function**: Split large datasets for efficient processing
- **Usage**: Handle multiple files or large datasets

#### 34. **Set Schema** (`n8n-nodes-base.set`)
- **Purpose**: Structure tabular data schema
- **Function**: Extract and format column information
- **Output**: Schema metadata for SQL queries

### Data Aggregation

#### 35. **Aggregate1** (`n8n-nodes-base.aggregate`)
- **Purpose**: Combine tabular data
- **Function**: Aggregate extracted spreadsheet data
- **Features**: Data consolidation and formatting

#### 36. **Summarize1** (`n8n-nodes-base.summarize`)
- **Purpose**: Summarize processed data
- **Function**: Create data summaries for large datasets
- **Usage**: Large Excel files or complex datasets

---

## 🔧 Integration & Communication Module

### Vector Storage & Search

#### 37. **Postgres PGVector Store3** (`@n8n/n8n-nodes-langchain.vectorStorePGVector`)
- **Purpose**: Store document embeddings
- **Function**: Insert vector embeddings into database
- **Features**:
  - Document chunking
  - Metadata preservation
  - Efficient storage

#### 38. **Embeddings Google Gemini2** (`@n8n/n8n-nodes-langchain.embeddingsGoogleGemini`)
- **Purpose**: Generate embeddings for documents
- **Function**: Convert document chunks to vectors
- **Model**: Google Gemini embeddings API

#### 39. **Default Data Loader3** (`@n8n/n8n-nodes-langchain.documentDefaultDataLoader`)
- **Purpose**: Load documents for vectorization
- **Function**: Prepare documents for embedding generation
- **Features**: Document formatting and preparation

#### 40. **Character Text Splitter2** (`@n8n/n8n-nodes-langchain.textSplitterCharacterTextSplitter`)
- **Purpose**: Split documents into chunks
- **Function**: Create optimal-sized text chunks for embeddings
- **Configuration**:
  - Chunk size optimization
  - Overlap settings
  - Boundary preservation

---

## 📝 Utility & Support Nodes

### Documentation & Notes

#### 41. **Sticky Note** (`n8n-nodes-base.stickyNote`)
- **Purpose**: Workflow documentation
- **Content**: "Message Processing and AI Response Flow"
- **Usage**: Visual workflow documentation

#### 42. **Sticky Note3** (`n8n-nodes-base.stickyNote`)
- **Purpose**: Database setup documentation
- **Content**: Database initialization instructions
- **Usage**: Setup guidance

#### 43. **Sticky Note4** (`n8n-nodes-base.stickyNote`)
- **Purpose**: File processing documentation
- **Content**: File handling workflow notes
- **Usage**: Process documentation

---

## 🔄 Workflow Execution Flow

### 1. Message Processing Flow
```
Webhook Entry → Filter Message Events → Message Processor → Start Loading Animation → AI Language Model → Process AI Response → Send Response to LINE
```

### 2. File Processing Flow
```
File Created/Updated → Download File → Switch (by type) → Extract Content → Insert to Database → Generate Embeddings → Store Vectors
```

### 3. AI Query Flow
```
User Message → AI Agent → Tool Selection (RAG/SQL) → Execute Query → Format Response → Send to User
```