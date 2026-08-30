CREATE TABLE IF NOT EXISTS chats (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user1_id uuid REFERENCES auth.users(id) NOT NULL,
  user2_id uuid REFERENCES auth.users(id) NOT NULL,
  created_at timestamp with time zone DEFAULT now()
);

ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_read boolean DEFAULT false;
