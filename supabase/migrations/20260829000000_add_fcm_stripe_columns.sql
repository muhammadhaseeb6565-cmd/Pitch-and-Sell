-- Add new columns for Phase 2 and Phase 3
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token text;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS stripe_account_id text;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS stripe_onboarding_complete boolean DEFAULT false;

-- Create a Database Webhook for Push Notifications
CREATE OR REPLACE FUNCTION notify_push() RETURNS trigger AS $$
BEGIN
  -- Calls the Supabase Edge Function whenever a new order or message is inserted
  PERFORM net.http_post(
    url := 'https://tqntacunedilwtofqycw.supabase.co/functions/v1/send-notification',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb,
    body := json_build_object('record', row_to_json(NEW), 'type', TG_TABLE_NAME)::jsonb
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS push_order ON orders;
CREATE TRIGGER push_order
AFTER INSERT ON orders
FOR EACH ROW EXECUTE FUNCTION notify_push();

DROP TRIGGER IF EXISTS push_message ON messages;
CREATE TRIGGER push_message
AFTER INSERT ON messages
FOR EACH ROW EXECUTE FUNCTION notify_push();
