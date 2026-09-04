-- ============================================================================
-- PITCH & SELL — Complete Supabase Database Schema
-- Run this ONCE in the Supabase SQL Editor (Dashboard > SQL Editor > New Query)
-- Safe to re-run: uses IF NOT EXISTS / CREATE OR REPLACE everywhere.
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ============================================================================
-- 1. PROFILES
-- Central user table, auto-created on sign-up via trigger.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name            TEXT,
    email           TEXT,
    phone           TEXT,
    avatar          TEXT,
    role            TEXT NOT NULL DEFAULT 'customer'
                        CHECK (role IN ('customer', 'seller', 'admin')),
    is_business     BOOLEAN NOT NULL DEFAULT false,
    business_name   TEXT,
    business_description TEXT,
    address         TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Auto-update updated_at on every row change
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ============================================================================
-- 2. PRODUCTS
-- Every product has a seller, a pitch video, and optional variants.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.products (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    seller_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    description     TEXT,
    price           NUMERIC NOT NULL CHECK (price >= 0),
    category        TEXT,
    stock           INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    video_url       TEXT,
    allow_download  BOOLEAN NOT NULL DEFAULT false,
    sizes           TEXT[] DEFAULT '{}',
    colors          TEXT[] DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_products_updated_at ON public.products;
CREATE TRIGGER trg_products_updated_at
    BEFORE UPDATE ON public.products
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ============================================================================
-- 3. ORDERS
-- Tracks purchases from buyer → seller, with shipping info and escrow status.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.orders (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    buyer_id        UUID NOT NULL REFERENCES public.profiles(id),
    seller_id       UUID NOT NULL REFERENCES public.profiles(id),
    product_id      UUID NOT NULL REFERENCES public.products(id),
    quantity        INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    total_price     NUMERIC NOT NULL CHECK (total_price >= 0),
    platform_fee    NUMERIC NOT NULL DEFAULT 0 CHECK (platform_fee >= 0),
    payment_method  TEXT NOT NULL DEFAULT 'COD',
    status          TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN (
                            'pending', 'processing', 'shipped',
                            'delivered', 'completed', 'cancelled',
                            'refunded', 'paid', 'cart_abandoned'
                        )),
    delivery_address TEXT,
    tracking_number TEXT,
    courier_name    TEXT,
    shipped_at      TIMESTAMPTZ,
    selected_size   TEXT,
    selected_color  TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_orders_updated_at ON public.orders;
CREATE TRIGGER trg_orders_updated_at
    BEFORE UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ============================================================================
-- 4. OFFERS (Price Negotiation)
-- Buyer can make an offer on a product; seller accepts or rejects.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.offers (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id      UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    buyer_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    seller_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    offer_amount    NUMERIC NOT NULL CHECK (offer_amount > 0),
    status          TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'accepted', 'rejected', 'declined')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ============================================================================
-- 5. PROMOTIONS
-- Sellers pay to promote their products in the Featured Pitches carousel.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.promotions (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id      UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    seller_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan_name       TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active', 'expired', 'pending')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ============================================================================
-- 6. CHATS
-- One chat room per unique pair of users.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.chats (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user1_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    user2_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user1_id, user2_id)
);


-- ============================================================================
-- 7. MESSAGES
-- Individual messages within a chat. Supports read receipts.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.messages (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    chat_id         UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
    sender_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content         TEXT NOT NULL,
    is_read         BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ============================================================================
-- 8. REVIEWS
-- Buyers rate and review products (1–5 stars).
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.reviews (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id      UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    buyer_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    rating          NUMERIC NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment         TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(product_id, buyer_id)
);


-- ============================================================================
-- 9. COMMENTS
-- Users comment on product pitch videos.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.comments (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id      UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    text            TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ============================================================================
-- 10. LIKES
-- Users like product pitch videos (one like per user per product).
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.likes (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id      UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(product_id, user_id)
);


-- ============================================================================
-- 11. SAVED VIDEOS (Bookmarks)
-- Users bookmark product videos for later viewing.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.saved_videos (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id      UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(product_id, user_id)
);


-- ============================================================================
-- 12. DEALS
-- Platform-wide promotional deals (bank offers, seasonal sales, etc.)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.deals (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    bank_name       TEXT NOT NULL,
    title           TEXT NOT NULL,
    description     TEXT,
    status          TEXT NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active', 'expired')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ============================================================================
-- 13. DEAL TRANSACTIONS
-- Tracks which users redeemed which deals.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.deal_transactions (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    deal_id         UUID NOT NULL REFERENCES public.deals(id) ON DELETE CASCADE,
    platform_fee    NUMERIC NOT NULL DEFAULT 5.0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ============================================================================
-- 14. PAYOUTS
-- Sellers request payouts of their available earnings.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.payouts (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount          NUMERIC NOT NULL CHECK (amount > 0),
    method          TEXT NOT NULL,
    details         TEXT,
    status          TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'processing', 'completed', 'rejected')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ============================================================================
-- 15. NOTIFICATIONS
-- Stores in-app notifications for users (order updates, offers, etc.)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title           TEXT NOT NULL,
    body            TEXT,
    type            TEXT DEFAULT 'general'
                        CHECK (type IN ('order', 'offer', 'message', 'promotion', 'general')),
    is_read         BOOLEAN NOT NULL DEFAULT false,
    metadata        JSONB DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offers            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotions        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_videos      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deals             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deal_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payouts           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications     ENABLE ROW LEVEL SECURITY;


-- ── Profiles ────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Profiles: public read"          ON public.profiles;
DROP POLICY IF EXISTS "Profiles: owner update"         ON public.profiles;
DROP POLICY IF EXISTS "Profiles: owner insert"         ON public.profiles;

CREATE POLICY "Profiles: public read"
    ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Profiles: owner update"
    ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Profiles: owner insert"
    ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);


-- ── Products ────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Products: public read"          ON public.products;
DROP POLICY IF EXISTS "Products: seller insert"        ON public.products;
DROP POLICY IF EXISTS "Products: seller update"        ON public.products;
DROP POLICY IF EXISTS "Products: seller delete"        ON public.products;

CREATE POLICY "Products: public read"
    ON public.products FOR SELECT USING (true);
CREATE POLICY "Products: seller insert"
    ON public.products FOR INSERT WITH CHECK (auth.uid() = seller_id);
CREATE POLICY "Products: seller update"
    ON public.products FOR UPDATE USING (auth.uid() = seller_id);
CREATE POLICY "Products: seller delete"
    ON public.products FOR DELETE USING (auth.uid() = seller_id);


-- ── Orders ──────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Orders: participant read"       ON public.orders;
DROP POLICY IF EXISTS "Orders: buyer insert"           ON public.orders;
DROP POLICY IF EXISTS "Orders: participant update"     ON public.orders;

CREATE POLICY "Orders: participant read"
    ON public.orders FOR SELECT
    USING (auth.uid() = buyer_id OR auth.uid() = seller_id);
CREATE POLICY "Orders: buyer insert"
    ON public.orders FOR INSERT
    WITH CHECK (auth.uid() = buyer_id);
CREATE POLICY "Orders: participant update"
    ON public.orders FOR UPDATE
    USING (auth.uid() = buyer_id OR auth.uid() = seller_id);


-- ── Offers ──────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Offers: participant read"       ON public.offers;
DROP POLICY IF EXISTS "Offers: participant insert"     ON public.offers;
DROP POLICY IF EXISTS "Offers: participant update"     ON public.offers;

CREATE POLICY "Offers: participant read"
    ON public.offers FOR SELECT
    USING (auth.uid() = buyer_id OR auth.uid() = seller_id);
CREATE POLICY "Offers: participant insert"
    ON public.offers FOR INSERT
    WITH CHECK (auth.uid() = buyer_id OR auth.uid() = seller_id);
CREATE POLICY "Offers: participant update"
    ON public.offers FOR UPDATE
    USING (auth.uid() = buyer_id OR auth.uid() = seller_id);


-- ── Promotions ──────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Promotions: public read"        ON public.promotions;
DROP POLICY IF EXISTS "Promotions: seller insert"      ON public.promotions;

CREATE POLICY "Promotions: public read"
    ON public.promotions FOR SELECT USING (true);
CREATE POLICY "Promotions: seller insert"
    ON public.promotions FOR INSERT
    WITH CHECK (auth.uid() = seller_id);


-- ── Chats ───────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Chats: participant read"        ON public.chats;
DROP POLICY IF EXISTS "Chats: participant insert"      ON public.chats;

CREATE POLICY "Chats: participant read"
    ON public.chats FOR SELECT
    USING (auth.uid() = user1_id OR auth.uid() = user2_id);
CREATE POLICY "Chats: participant insert"
    ON public.chats FOR INSERT
    WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);


-- ── Messages ────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Messages: chat participant read"  ON public.messages;
DROP POLICY IF EXISTS "Messages: sender insert"          ON public.messages;
DROP POLICY IF EXISTS "Messages: participant update"      ON public.messages;

CREATE POLICY "Messages: chat participant read"
    ON public.messages FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.chats c
        WHERE c.id = messages.chat_id
          AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid())
    ));
CREATE POLICY "Messages: sender insert"
    ON public.messages FOR INSERT
    WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "Messages: participant update"
    ON public.messages FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM public.chats c
        WHERE c.id = messages.chat_id
          AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid())
    ));


-- ── Reviews ─────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Reviews: public read"           ON public.reviews;
DROP POLICY IF EXISTS "Reviews: buyer insert"          ON public.reviews;

CREATE POLICY "Reviews: public read"
    ON public.reviews FOR SELECT USING (true);
CREATE POLICY "Reviews: buyer insert"
    ON public.reviews FOR INSERT
    WITH CHECK (auth.uid() = buyer_id);


-- ── Comments ────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Comments: public read"          ON public.comments;
DROP POLICY IF EXISTS "Comments: user insert"          ON public.comments;
DROP POLICY IF EXISTS "Comments: owner delete"         ON public.comments;

CREATE POLICY "Comments: public read"
    ON public.comments FOR SELECT USING (true);
CREATE POLICY "Comments: user insert"
    ON public.comments FOR INSERT
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Comments: owner delete"
    ON public.comments FOR DELETE
    USING (auth.uid() = user_id);


-- ── Likes ───────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Likes: public read"             ON public.likes;
DROP POLICY IF EXISTS "Likes: user insert"             ON public.likes;
DROP POLICY IF EXISTS "Likes: owner delete"            ON public.likes;

CREATE POLICY "Likes: public read"
    ON public.likes FOR SELECT USING (true);
CREATE POLICY "Likes: user insert"
    ON public.likes FOR INSERT
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Likes: owner delete"
    ON public.likes FOR DELETE
    USING (auth.uid() = user_id);


-- ── Saved Videos ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Saved: owner read"              ON public.saved_videos;
DROP POLICY IF EXISTS "Saved: owner insert"            ON public.saved_videos;
DROP POLICY IF EXISTS "Saved: owner delete"            ON public.saved_videos;

CREATE POLICY "Saved: owner read"
    ON public.saved_videos FOR SELECT
    USING (auth.uid() = user_id);
CREATE POLICY "Saved: owner insert"
    ON public.saved_videos FOR INSERT
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Saved: owner delete"
    ON public.saved_videos FOR DELETE
    USING (auth.uid() = user_id);


-- ── Deals ───────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Deals: public read"             ON public.deals;
CREATE POLICY "Deals: public read"
    ON public.deals FOR SELECT USING (true);


-- ── Deal Transactions ───────────────────────────────────────────────────────
DROP POLICY IF EXISTS "DealTx: owner read"             ON public.deal_transactions;
DROP POLICY IF EXISTS "DealTx: user insert"            ON public.deal_transactions;

CREATE POLICY "DealTx: owner read"
    ON public.deal_transactions FOR SELECT
    USING (auth.uid() = user_id);
CREATE POLICY "DealTx: user insert"
    ON public.deal_transactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);


-- ── Payouts ─────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Payouts: owner read"            ON public.payouts;
DROP POLICY IF EXISTS "Payouts: owner insert"          ON public.payouts;

CREATE POLICY "Payouts: owner read"
    ON public.payouts FOR SELECT
    USING (auth.uid() = user_id);
CREATE POLICY "Payouts: owner insert"
    ON public.payouts FOR INSERT
    WITH CHECK (auth.uid() = user_id);


-- ── Notifications ───────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Notifications: owner read"      ON public.notifications;
DROP POLICY IF EXISTS "Notifications: owner insert"    ON public.notifications;
DROP POLICY IF EXISTS "Notifications: owner update"    ON public.notifications;

CREATE POLICY "Notifications: owner read"
    ON public.notifications FOR SELECT
    USING (auth.uid() = user_id);
CREATE POLICY "Notifications: owner insert"
    ON public.notifications FOR INSERT
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Notifications: owner update"
    ON public.notifications FOR UPDATE
    USING (auth.uid() = user_id);


-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_products_seller          ON public.products(seller_id);
CREATE INDEX IF NOT EXISTS idx_products_category        ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_products_created         ON public.products(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_orders_buyer             ON public.orders(buyer_id);
CREATE INDEX IF NOT EXISTS idx_orders_seller            ON public.orders(seller_id);
CREATE INDEX IF NOT EXISTS idx_orders_status            ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created           ON public.orders(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_offers_buyer             ON public.offers(buyer_id);
CREATE INDEX IF NOT EXISTS idx_offers_seller            ON public.offers(seller_id);

CREATE INDEX IF NOT EXISTS idx_chats_user1              ON public.chats(user1_id);
CREATE INDEX IF NOT EXISTS idx_chats_user2              ON public.chats(user2_id);

CREATE INDEX IF NOT EXISTS idx_messages_chat_created    ON public.messages(chat_id, created_at);
CREATE INDEX IF NOT EXISTS idx_messages_sender          ON public.messages(sender_id);

CREATE INDEX IF NOT EXISTS idx_comments_product         ON public.comments(product_id);
CREATE INDEX IF NOT EXISTS idx_likes_product            ON public.likes(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_product          ON public.reviews(product_id);

CREATE INDEX IF NOT EXISTS idx_saved_user               ON public.saved_videos(user_id);
CREATE INDEX IF NOT EXISTS idx_promotions_seller        ON public.promotions(seller_id);
CREATE INDEX IF NOT EXISTS idx_promotions_status        ON public.promotions(status);

CREATE INDEX IF NOT EXISTS idx_notifications_user       ON public.notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payouts_user             ON public.payouts(user_id);


-- ============================================================================
-- TRIGGER: Auto-create profile on new user sign-up
-- Copies metadata (name, phone, role, business info) from auth.users into
-- the public.profiles table so the app can query it immediately.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    raw_meta  JSONB;
    user_name TEXT;
    user_role TEXT;
    is_biz    BOOLEAN;
BEGIN
    raw_meta  := COALESCE(NEW.raw_user_meta_data, '{}'::JSONB);
    user_name := COALESCE(
        raw_meta->>'full_name',
        raw_meta->>'name',
        split_part(NEW.email, '@', 1)
    );
    user_role := COALESCE(raw_meta->>'role', 'customer');
    is_biz    := COALESCE((raw_meta->>'is_business')::BOOLEAN, false);

    INSERT INTO public.profiles (
        id, email, name, phone, role, is_business,
        business_name, business_description
    ) VALUES (
        NEW.id,
        NEW.email,
        user_name,
        raw_meta->>'phone',
        user_role,
        is_biz,
        raw_meta->>'business_name',
        raw_meta->>'business_description'
    )
    ON CONFLICT (id) DO UPDATE SET
        email                = EXCLUDED.email,
        name                 = COALESCE(EXCLUDED.name, profiles.name),
        phone                = COALESCE(EXCLUDED.phone, profiles.phone),
        role                 = COALESCE(EXCLUDED.role, profiles.role),
        is_business          = COALESCE(EXCLUDED.is_business, profiles.is_business),
        business_name        = COALESCE(EXCLUDED.business_name, profiles.business_name),
        business_description = COALESCE(EXCLUDED.business_description, profiles.business_description);

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ============================================================================
-- TRIGGER: Auto-create notification on new order
-- When a new order is placed, automatically create a notification for the seller.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.notify_seller_on_order()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    product_name TEXT;
BEGIN
    SELECT name INTO product_name
    FROM public.products
    WHERE id = NEW.product_id;

    INSERT INTO public.notifications (user_id, title, body, type, metadata)
    VALUES (
        NEW.seller_id,
        'New Order Received! 🎉',
        'Someone just ordered ' || COALESCE(product_name, 'your product') || '.',
        'order',
        jsonb_build_object('order_id', NEW.id, 'product_id', NEW.product_id)
    );

    -- Also notify the buyer
    INSERT INTO public.notifications (user_id, title, body, type, metadata)
    VALUES (
        NEW.buyer_id,
        'Order Placed Successfully',
        'Your order for ' || COALESCE(product_name, 'a product') || ' is now pending.',
        'order',
        jsonb_build_object('order_id', NEW.id, 'product_id', NEW.product_id)
    );

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_seller_on_order ON public.orders;
CREATE TRIGGER trg_notify_seller_on_order
    AFTER INSERT ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.notify_seller_on_order();


-- ============================================================================
-- TRIGGER: Notify buyer when order status changes
-- ============================================================================
CREATE OR REPLACE FUNCTION public.notify_buyer_on_order_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    product_name TEXT;
    msg          TEXT;
BEGIN
    IF OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;

    SELECT name INTO product_name
    FROM public.products
    WHERE id = NEW.product_id;

    CASE NEW.status
        WHEN 'processing' THEN msg := 'Your order for ' || COALESCE(product_name, 'a product') || ' is being processed.';
        WHEN 'shipped'    THEN msg := 'Your order for ' || COALESCE(product_name, 'a product') || ' has been shipped! 🚚';
        WHEN 'delivered'  THEN msg := 'Your order for ' || COALESCE(product_name, 'a product') || ' has been delivered! ✅';
        WHEN 'cancelled'  THEN msg := 'Your order for ' || COALESCE(product_name, 'a product') || ' was cancelled.';
        WHEN 'refunded'   THEN msg := 'Your order for ' || COALESCE(product_name, 'a product') || ' has been refunded.';
        ELSE msg := 'Your order status changed to ' || NEW.status || '.';
    END CASE;

    INSERT INTO public.notifications (user_id, title, body, type, metadata)
    VALUES (
        NEW.buyer_id,
        'Order ' || initcap(NEW.status),
        msg,
        'order',
        jsonb_build_object('order_id', NEW.id, 'status', NEW.status)
    );

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_buyer_on_order_update ON public.orders;
CREATE TRIGGER trg_notify_buyer_on_order_update
    AFTER UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.notify_buyer_on_order_update();


-- ============================================================================
-- STORAGE BUCKETS
-- Create the 'videos' bucket for product pitch videos.
-- NOTE: Run this section only once. If it errors with "already exists", skip it.
-- ============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'videos',
    'videos',
    true,
    104857600,  -- 100 MB limit
    ARRAY['video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/webm']
)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: Anyone can read, authenticated users can upload
DROP POLICY IF EXISTS "Videos: public read"   ON storage.objects;
DROP POLICY IF EXISTS "Videos: auth upload"   ON storage.objects;
DROP POLICY IF EXISTS "Videos: owner delete"  ON storage.objects;

CREATE POLICY "Videos: public read"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'videos');

CREATE POLICY "Videos: auth upload"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'videos' AND auth.role() = 'authenticated');

CREATE POLICY "Videos: owner delete"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'videos' AND auth.uid()::text = (storage.foldername(name))[1]);


-- ============================================================================
-- REALTIME
-- Enable Supabase Realtime for tables that need live updates.
-- ============================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chats;


-- ============================================================================
-- DONE! Your Pitch & Sell database is fully configured.
-- ============================================================================
