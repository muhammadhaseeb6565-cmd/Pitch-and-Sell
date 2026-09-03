-- Copy and paste this into your Supabase SQL Editor to create the missing tables

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT,
    email TEXT,
    avatar TEXT,
    is_business BOOLEAN DEFAULT false,
    business_name TEXT,
    business_description TEXT,
    role TEXT DEFAULT 'buyer',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Products Table
CREATE TABLE IF NOT EXISTS public.products (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    seller_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC NOT NULL,
    category TEXT,
    stock INT DEFAULT 0,
    video_url TEXT,
    allow_download BOOLEAN DEFAULT false,
    sizes TEXT[],
    colors TEXT[],
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Orders Table
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    buyer_id UUID REFERENCES public.profiles(id),
    seller_id UUID REFERENCES public.profiles(id),
    product_id UUID REFERENCES public.products(id),
    quantity INT DEFAULT 1,
    total_price NUMERIC,
    payment_method TEXT,
    status TEXT DEFAULT 'pending',
    tracking_number TEXT,
    courier_name TEXT,
    shipped_at TIMESTAMPTZ,
    selected_size TEXT,
    selected_color TEXT,
    platform_fee NUMERIC DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Offers Table
CREATE TABLE IF NOT EXISTS public.offers (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    buyer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    seller_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    offer_amount NUMERIC NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. Promotions Table
CREATE TABLE IF NOT EXISTS public.promotions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    seller_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan_name TEXT NOT NULL,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'pending')),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. Chats Table
CREATE TABLE IF NOT EXISTS public.chats (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user1_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    user2_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user1_id, user2_id)
);

-- 7. Messages Table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    chat_id UUID REFERENCES public.chats(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 8. Reviews Table
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    buyer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    rating NUMERIC NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 9. Comments Table
CREATE TABLE IF NOT EXISTS public.comments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 10. Likes Table
CREATE TABLE IF NOT EXISTS public.likes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(product_id, user_id)
);

-- 11. Saved Videos Table
CREATE TABLE IF NOT EXISTS public.saved_videos (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(product_id, user_id)
);

-- 12. Deals Table
CREATE TABLE IF NOT EXISTS public.deals (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    bank_name TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 13. Deal Transactions Table
CREATE TABLE IF NOT EXISTS public.deal_transactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    deal_id UUID REFERENCES public.deals(id) ON DELETE CASCADE,
    platform_fee NUMERIC DEFAULT 5.0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 14. Payouts Table
CREATE TABLE IF NOT EXISTS public.payouts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC NOT NULL,
    method TEXT NOT NULL,
    details TEXT,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Set up Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deal_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payouts ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Products Policies
CREATE POLICY "Products are viewable by everyone" ON public.products FOR SELECT USING (true);
CREATE POLICY "Sellers can insert own products" ON public.products FOR INSERT WITH CHECK (auth.uid() = seller_id);
CREATE POLICY "Sellers can update own products" ON public.products FOR UPDATE USING (auth.uid() = seller_id);
CREATE POLICY "Sellers can delete own products" ON public.products FOR DELETE USING (auth.uid() = seller_id);

-- Orders Policies
CREATE POLICY "Users can view own orders" ON public.orders FOR SELECT USING (auth.uid() = buyer_id OR auth.uid() = seller_id);
CREATE POLICY "Buyers can insert orders" ON public.orders FOR INSERT WITH CHECK (auth.uid() = buyer_id);
CREATE POLICY "Users can update own orders" ON public.orders FOR UPDATE USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

-- Offers Policies
CREATE POLICY "Users can view own offers" ON public.offers FOR SELECT USING (auth.uid() = buyer_id OR auth.uid() = seller_id);
CREATE POLICY "Users can insert own offers" ON public.offers FOR INSERT WITH CHECK (auth.uid() = buyer_id OR auth.uid() = seller_id);
CREATE POLICY "Users can update own offers" ON public.offers FOR UPDATE USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

-- Promotions Policies
CREATE POLICY "Promotions are viewable by everyone" ON public.promotions FOR SELECT USING (true);
CREATE POLICY "Sellers can insert own promotions" ON public.promotions FOR INSERT WITH CHECK (auth.uid() = seller_id);

-- Chats Policies
CREATE POLICY "Users can view own chats" ON public.chats FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);
CREATE POLICY "Users can insert own chats" ON public.chats FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Messages Policies
CREATE POLICY "Users can view own messages" ON public.messages FOR SELECT USING (EXISTS (SELECT 1 FROM public.chats c WHERE c.id = messages.chat_id AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid())));
CREATE POLICY "Users can insert own messages" ON public.messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Reviews Policies
CREATE POLICY "Reviews are viewable by everyone" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "Buyers can insert own reviews" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = buyer_id);

-- Comments Policies
CREATE POLICY "Comments are viewable by everyone" ON public.comments FOR SELECT USING (true);
CREATE POLICY "Users can insert own comments" ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own comments" ON public.comments FOR DELETE USING (auth.uid() = user_id);

-- Likes Policies
CREATE POLICY "Likes are viewable by everyone" ON public.likes FOR SELECT USING (true);
CREATE POLICY "Users can insert own likes" ON public.likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own likes" ON public.likes FOR DELETE USING (auth.uid() = user_id);

-- Saved Videos Policies
CREATE POLICY "Saved videos are viewable by owner" ON public.saved_videos FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own saved videos" ON public.saved_videos FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own saved videos" ON public.saved_videos FOR DELETE USING (auth.uid() = user_id);

-- Deals Policies
CREATE POLICY "Deals are viewable by everyone" ON public.deals FOR SELECT USING (true);

-- Deal Transactions Policies
CREATE POLICY "Deal transactions are viewable by owner" ON public.deal_transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own deal transactions" ON public.deal_transactions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Payouts Policies
CREATE POLICY "Payouts are viewable by owner" ON public.payouts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can request own payouts" ON public.payouts FOR INSERT WITH CHECK (auth.uid() = user_id);


-- Indexes
CREATE INDEX IF NOT EXISTS idx_orders_seller_id ON public.orders(seller_id);
CREATE INDEX IF NOT EXISTS idx_orders_buyer_id ON public.orders(buyer_id);
CREATE INDEX IF NOT EXISTS idx_comments_product_id ON public.comments(product_id);
CREATE INDEX IF NOT EXISTS idx_likes_product_id ON public.likes(product_id);
CREATE INDEX IF NOT EXISTS idx_messages_chat_id_created_at ON public.messages(chat_id, created_at);
CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON public.reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_promotions_seller_id ON public.promotions(seller_id);
CREATE INDEX IF NOT EXISTS idx_saved_videos_user_id ON public.saved_videos(user_id);


-- Trigger to automatically create a profile when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
