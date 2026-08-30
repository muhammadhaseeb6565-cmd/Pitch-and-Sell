-- Copy and paste this into your Supabase SQL Editor to create the missing tables

-- 1. Offers Table
CREATE TABLE IF NOT EXISTS public.offers (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    buyer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    seller_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    offer_amount NUMERIC NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Promotions Table
CREATE TABLE IF NOT EXISTS public.promotions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    seller_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_name TEXT NOT NULL,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'pending')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Chats Table
CREATE TABLE IF NOT EXISTS public.chats (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user1_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    user2_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user1_id, user2_id)
);

-- 4. Messages Table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    chat_id UUID REFERENCES public.chats(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Order Tracking Updates
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS tracking_number TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_name TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS shipped_at TIMESTAMP WITH TIME ZONE;

-- 6. Product Variations Updates
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS sizes TEXT[];
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS colors TEXT[];
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS selected_size TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS selected_color TEXT;

-- 7. Reviews Table
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    buyer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    rating NUMERIC NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Set up Row Level Security (RLS) if needed
ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Basic Policies (allowing authenticated users full access for now)
CREATE POLICY "Enable all for authenticated users" ON public.offers FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable all for authenticated users" ON public.promotions FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable all for authenticated users" ON public.chats FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable all for authenticated users" ON public.messages FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable all for authenticated users" ON public.reviews FOR ALL TO authenticated USING (true) WITH CHECK (true);
