-- Add billboard scheduling columns to promotions table
ALTER TABLE public.promotions 
ADD COLUMN IF NOT EXISTS schedule JSONB,
ADD COLUMN IF NOT EXISTS timezone TEXT DEFAULT 'Asia/Karachi';
