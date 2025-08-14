create table public.line_messages (
  id bigserial not null,
  message_id character varying(255) not null,
  session_id character varying(255) not null,
  message_text text not null,
  message_type character varying(20) null default 'human'::character varying,
  reply_token character varying(255) null,
  timestamp timestamp with time zone not null,
  quote_token text null,
  quoted_message_id character varying(255) null,
  quoted_message_text text null,
  raw_message jsonb null,
  chat_message jsonb null,
  created_at timestamp with time zone null default now(),
  processed boolean null default false,
  updated_at timestamp with time zone null default now(),
  constraint line_messages_pkey primary key (id),
  constraint line_messages_message_id_key unique (message_id)
) TABLESPACE pg_default;

create index IF not exists idx_line_messages_message_id on public.line_messages using btree (message_id) TABLESPACE pg_default;

create index IF not exists idx_line_messages_session_id on public.line_messages using btree (session_id) TABLESPACE pg_default;

create index IF not exists idx_line_messages_quoted_message_id on public.line_messages using btree (quoted_message_id) TABLESPACE pg_default;

create index IF not exists idx_line_messages_timestamp on public.line_messages using btree ("timestamp") TABLESPACE pg_default;

create index IF not exists idx_line_messages_type on public.line_messages using btree (message_type) TABLESPACE pg_default;

create index IF not exists idx_line_messages_processed on public.line_messages using btree (processed) TABLESPACE pg_default;

create trigger update_line_messages_updated_at BEFORE
update on line_messages for EACH row
execute FUNCTION update_updated_at_column ();