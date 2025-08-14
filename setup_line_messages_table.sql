-- SQL script to create the line_messages table compatible with n8n_chat_dev structure
-- Run this in your Supabase SQL editor

CREATE TABLE IF NOT EXISTS line_messages (
    id BIGSERIAL PRIMARY KEY,
    message_id VARCHAR(255) UNIQUE NOT NULL,
    session_id VARCHAR(255) NOT NULL, -- Matches your n8n_chat_dev.session_id (user_id)
    message_text TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'human', -- 'human' or 'ai' to match your chat structure
    reply_token VARCHAR(255),
    timestamp TIMESTAMPTZ NOT NULL,
    quote_token TEXT,
    quoted_message_id VARCHAR(255),
    quoted_message_text TEXT, -- Store the actual quoted message content for faster access
    raw_message JSONB, -- Store the full LINE message data for compatibility
    chat_message JSONB, -- Store in the same format as n8n_chat_dev.message column
    created_at TIMESTAMPTZ DEFAULT NOW(),
    processed BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_line_messages_message_id ON line_messages(message_id);
CREATE INDEX IF NOT EXISTS idx_line_messages_session_id ON line_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_line_messages_quoted_message_id ON line_messages(quoted_message_id);
CREATE INDEX IF NOT EXISTS idx_line_messages_timestamp ON line_messages(timestamp);
CREATE INDEX IF NOT EXISTS idx_line_messages_type ON line_messages(message_type);
CREATE INDEX IF NOT EXISTS idx_line_messages_processed ON line_messages(processed);

-- Enable Row Level Security (RLS)
ALTER TABLE line_messages ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows all operations (adjust as needed for your security requirements)
CREATE POLICY "Allow all operations on line_messages" 
ON line_messages 
FOR ALL 
USING (true) 
WITH CHECK (true);

-- Create a function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create a trigger to automatically update the updated_at column
CREATE TRIGGER update_line_messages_updated_at 
    BEFORE UPDATE ON line_messages 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Add comments for documentation
COMMENT ON TABLE line_messages IS 'Stores LINE chat messages for quote functionality, compatible with n8n_chat_dev structure';
COMMENT ON COLUMN line_messages.message_id IS 'Unique LINE message ID';
COMMENT ON COLUMN line_messages.session_id IS 'User session ID (matches n8n_chat_dev.session_id)';
COMMENT ON COLUMN line_messages.message_text IS 'The actual message content (plain text)';
COMMENT ON COLUMN line_messages.message_type IS 'Type of message: human or ai';
COMMENT ON COLUMN line_messages.reply_token IS 'LINE reply token for responding';
COMMENT ON COLUMN line_messages.timestamp IS 'When the message was sent (from LINE)';
COMMENT ON COLUMN line_messages.quote_token IS 'LINE quote token for quoting this message';
COMMENT ON COLUMN line_messages.quoted_message_id IS 'ID of the message being quoted (if this is a reply)';
COMMENT ON COLUMN line_messages.quoted_message_text IS 'Text content of the quoted message (for quick access)';
COMMENT ON COLUMN line_messages.raw_message IS 'Full LINE webhook message data (JSONB)';
COMMENT ON COLUMN line_messages.chat_message IS 'Message in n8n_chat_dev format (JSONB)';
COMMENT ON COLUMN line_messages.created_at IS 'When this record was created in our database';
COMMENT ON COLUMN line_messages.processed IS 'Whether this message has been processed by the AI';
COMMENT ON COLUMN line_messages.updated_at IS 'When this record was last updated';

-- Function to extract message text from chat_message JSONB
CREATE OR REPLACE FUNCTION extract_message_content(chat_msg JSONB)
RETURNS TEXT AS $$
BEGIN
    -- Extract content from the JSON structure like your n8n_chat_dev format
    IF chat_msg ? 'content' THEN
        RETURN chat_msg->>'content';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to search for quoted messages with fallback to n8n_chat_dev
CREATE OR REPLACE FUNCTION get_quoted_message_content(quoted_msg_id VARCHAR)
RETURNS TABLE(
    message_text TEXT,
    source_table VARCHAR
) AS $$
BEGIN
    -- First try to find in line_messages table
    RETURN QUERY
    SELECT 
        lm.message_text,
        'line_messages'::VARCHAR as source_table
    FROM line_messages lm 
    WHERE lm.message_id = quoted_msg_id 
    LIMIT 1;
    
    -- If not found, you could extend this to search other tables if needed
    -- For now, we'll just return the direct lookup result
    
    RETURN;
END;
$$ LANGUAGE plpgsql;
