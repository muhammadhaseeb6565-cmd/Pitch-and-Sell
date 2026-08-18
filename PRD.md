# PITCH AND SELL
## Complete Product Requirements & Build Specification
### Emulgic's First Platform

**Purpose:** Master blueprint for Haseeb and Antigravity  
**Current product name:** Pitch and Sell  
**Parent startup:** Emulgic  
**Branding note:** Keep the name **Pitch and Sell** throughout V1. It may be renamed later without changing the core architecture.

---

## 1. PRODUCT VISION

Pitch and Sell is Emulgic's short-form video commerce and business-discovery platform.

The core journey is:

**Discover → Watch → Interact → Chat → Negotiate → Order → Pay/COD → Deliver → Confirm → Settle → Payout**

Businesses can showcase products through short videos. Customers can discover products, communicate with sellers inside the app, negotiate bulk orders, place orders, choose Pay Now or COD, receive delivery updates, and review purchases.

Emulgic earns small, transparent fees from qualifying transactions and optional promotional placements.

---

## 2. BRANDING AND VISUAL IDENTITY

### Product name

# PITCH AND SELL

Do not rename the product during development.

### Parent startup

# EMULGIC

Pitch and Sell is Emulgic's first platform/project.

### Theme

Use the uploaded Emulgic startup branding/logo as the visual reference.

The UI should use:

- Coral/orange as the main accent
- Charcoal/dark tones
- Warm cream/off-white surfaces
- White/light typography where appropriate
- Clean modern technology/startup styling
- Premium but approachable presentation
- Subtle geometric/diagonal elements where appropriate
- Emulgic logo/robot visual identity where appropriate

Do not introduce random colors that conflict with the Emulgic identity.

The app should look like a product belonging to Emulgic while the visible product name remains **Pitch and Sell**.

---

## 3. WELCOME AND AUTHENTICATION

The first screen must say:

# Welcome to Pitch and Sell

Suggested tagline:

> Discover. Showcase. Sell.

Primary actions:

- **Sign Up**
- **Log In**
- **Continue with Google**

Support proper Google/Gmail OAuth/OpenID authentication.

Do not create a fake Google login.

Support:
- New account creation
- Returning-user login
- Secure sessions
- Logout
- Account recovery where applicable

---

## 4. DUAL USER MODES

One account can operate in two modes.

### Customer Mode

Users can:

- Watch videos
- Search products/businesses
- Browse categories
- Like
- Comment
- Share
- Save/favorite
- Chat with sellers
- Place orders
- View order history
- View deals and bank-card offers

### Selling Mode

Users with a business profile can switch to:

- Seller dashboard
- Upload videos
- Manage products
- Manage chats
- Create offers
- Manage orders
- Track sales
- Track engagement
- View earnings
- Request payouts
- Promote products
- View promotion results

Provide a clear:

> **Switch to Selling Mode**

and, in selling mode:

> **Switch to Customer Mode**

Do not force a person to create two accounts simply to buy and sell.

---

## 5. BUSINESS/SELLER ONBOARDING

When a customer first enters Selling Mode, provide:

### Create Business Profile

Fields:

- Business name
- Category
- Business description
- Contact name
- Phone
- Email
- Logo
- City/location
- Address where needed
- Optional website/social links
- Payout method/details
- Verification information where required

Business statuses:

- Pending
- Verified
- Rejected
- Suspended

Admin can manage these statuses.

---

## 6. CUSTOMER HOME FEED

Use a vertical short-form video feed.

The experience can be familiar to modern short-video apps, but must retain Pitch and Sell's own identity.

### Video rules

**Maximum video duration: 60 seconds.**

The backend MUST enforce this limit. Frontend validation alone is not sufficient.

Each video should show:

- Product information
- Seller/business
- Price
- Discount where applicable
- Relevant actions

---

## 7. VIDEO ACTIONS

Every video should support:

- Like
- Comment
- Share
- Download
- Save/Favorite
- Chat with Seller
- Order Now

### Download control

Seller chooses during upload:

> Allow viewers to download this video: ON/OFF

If disabled, the download option should not be presented.

Future enhancement: watermark downloaded videos.

---

## 8. SELLER VIDEO UPLOAD

Selling Mode must have a prominent:

# + Upload Video

button.

Flow:

**Select Video → Validate → Add Product → Title → Description → Price → Category → Discount → Download Permission → Preview → Publish**

Upload validation:

- Maximum duration: 60 seconds
- Supported formats
- File-size limit
- File integrity
- Safe upload validation

The backend performs final validation.

### Video infrastructure

Architecture should support:

- Object storage
- Video compression/transcoding
- Thumbnail generation
- Multiple playback resolutions
- CDN/video delivery
- Fast mobile playback

Do not store large video files directly in the main relational database.

---

## 9. PRODUCT CREATION

Every commercial video should be associated with a product/service.

Fields:

- Product name
- Description
- Price
- Optional old price
- Discount
- Category
- Stock/availability
- Product images
- Video
- Seller
- Delivery information
- Return information
- Download permission
- Status

Statuses:

- Draft
- Published
- Out of stock
- Paused
- Archived
- Removed

---

## 10. PRODUCT PAGE

Show:

- Video
- Product name
- Price
- Discount
- Seller/business
- Description
- Availability
- Delivery information
- Return information
- Like
- Comment
- Share
- Save
- Download if allowed
- Chat with Seller
- Order Now

---

## 11. COMMENTS

Each video has a public comment section.

Customers can:

- Comment
- Reply
- Delete their own comments
- Report comments

Sellers can:

- Reply to comments on their own videos
- Moderate inappropriate comments on their own content
- Report abusive users

Add basic moderation:
- Report
- Block
- Spam detection
- Abuse detection

---

## 12. IN-APP CHAT

Product discussions should primarily happen inside Pitch and Sell.

Do not immediately push customers to WhatsApp.

Chat supports:

- Text messages
- Product references
- Order references
- Offer creation
- Quantity discussion
- Bulk/wholesale negotiation
- Delivery discussion
- Payment discussion

Future options may include images, documents and voice messages.

---

## 13. STRUCTURED OFFERS AND BULK ORDERS

Sellers can convert negotiations into a structured offer.

Example:

### Wholesale Offer

Product: XYZ  
Quantity: 50  
Unit price: PKR 1,600  
Product total: PKR 80,000  
Delivery: PKR 500  
Payment: COD / Pay Now  
Offer expiry: 24 hours

Seller selects:

> **Send Offer**

Customer selects:

> **Accept Offer**

Acceptance creates an official order.

---

## 14. AI ORDER ASSISTANCE

AI may analyze chat to detect commercial intent and extract:

- Product
- Quantity
- Price
- Location
- Payment preference
- Potential confirmation

Example:

> "Confirmed. Send 100 units to Lahore."

AI can show:

> **Potential order confirmation detected**

The user confirms the structured information.

### Critical rule

AI MUST NOT independently declare a legally/financially binding sale.

AI may detect, extract, summarize and suggest.

The official order/payment/delivery system remains the source of truth.

---

## 15. ORDER SYSTEM

Every order receives a unique ID.

Example:

`EMU-ORD-000001`

Store:

- Order ID
- Customer ID
- Seller ID
- Business ID
- Product ID
- Video ID that generated the order
- Quantity
- Unit price
- Product total
- Delivery fee
- Total
- Payment method
- Payment status
- Order status
- Courier
- Tracking number
- Emulgic fee
- Seller earnings
- Payout eligibility
- Created timestamp
- Updated timestamp
- Completion timestamp

### Order statuses

- Pending
- Accepted
- Processing
- Shipped
- Out for delivery
- Delivered
- Completed
- Cancelled
- Returned
- Refunded

Important:

> **Order created does not automatically mean completed sale.**

---

## 16. ORDER FORM

When customer clicks **Order Now**, show:

- Customer name
- Phone
- Delivery address
- City
- Product
- Quantity
- Price
- Delivery fee
- Total
- Payment method

Payment choices:

### Pay Now
### Cash on Delivery

The official order must be recorded in Pitch and Sell.

Seller and Emulgic's system must receive the order event.

---

## 17. PAY NOW

Use a real supported payment gateway in production.

Do not treat a personal bank account, Easypaisa account or JazzCash account as a production marketplace wallet.

Recommended architecture:

**Customer → Payment Gateway → Transaction → Emulgic Ledger → Seller Balance → Payout**

Payment states:

- Pending
- Processing
- Paid
- Failed
- Refunded
- Partially refunded where supported

Use secure webhook verification and idempotency.

---

## 18. CASH ON DELIVERY

Customer selects COD.

The order is created and seller is notified.

Courier architecture should support providers such as Leopards.

Store:

- Courier
- Tracking number
- COD amount
- Shipment status
- Delivery status
- COD settlement status

COD earnings become payout-eligible according to confirmed delivery/settlement rules.

Courier charges remain separate from the Emulgic platform fee.

---

## 19. SALE ATTRIBUTION

Every order must preserve its source.

Example:

**Video V-1024 → Product P-501 → Seller S-44 → Order EMU-ORD-000184**

This enables:

> This video generated 27 orders.

and:

> This product generated PKR 135,000 in sales.

Never lose the originating product/video relationship.

---

## 20. SELLER DASHBOARD

### Overview

Show:

- Views
- Likes
- Comments
- Shares
- Saves
- Downloads
- Product clicks
- Orders
- Completed sales
- Gross sales
- Emulgic fees
- Net earnings
- Pending earnings
- Available for payout

### Products

- Published
- Draft
- Out of stock
- Archived

### Videos

- Upload
- Manage
- Performance

### Orders

- New
- Processing
- Shipped
- Delivered
- Completed
- Cancelled
- Returned

### Chats

- Active
- Offers
- Customer conversations

### Promotions

- Active
- Completed
- Results

### Payouts

- Available balance
- Request payout
- History

---

## 21. SELLER LEDGER

Do not use a simple editable balance.

Use a transaction ledger.

Display:

- Gross Sales
- Emulgic Fees
- Net Earnings
- Pending Earnings
- Available for Payout
- Paid Out

Example:

Gross sales: PKR 100,000  
Emulgic fees: PKR 2,000  
Net earnings: PKR 98,000  
Paid out: PKR 60,000  
Available: PKR 38,000

Every amount must trace back to individual transactions.

---

## 22. EMULGIC FEES

Proposed launch pricing:

### Pay Now
**PKR 20 per qualifying completed order**

### COD
**PKR 10 per qualifying completed order**

### Featured Product
**PKR 100 per product / 3 days**

### Bank-card/deal transaction
**PKR 5 per qualifying completed transaction**

All fee values should be configurable from the admin panel, not hard-coded throughout the application.

---

## 23. PAYMENT PROCESSING COST

The PKR 20 Pay Now fee is a platform fee, not guaranteed profit.

Track payment-provider costs separately.

Ledger should support:

- Gross transaction
- Payment processing cost
- Emulgic platform fee
- Seller net amount

---

## 24. SELLER PAYOUTS

Seller cannot instantly transfer funds themselves.

Show:

# Available for Payout

and:

# Request Payout

### Minimum payout

# PKR 500

If below PKR 500:

> Minimum payout is PKR 500.

### Flow

**Requested → Approved → Processing → Completed**

Possible failure states:

- Rejected
- Failed

Payout methods:

- Bank account
- Easypaisa
- JazzCash

Payout information must be protected.

---

## 25. PAYOUT HISTORY

Every payout remains permanently recorded.

Example:

`PAY-000127`

Amount: PKR 38,450  
Method: Bank  
Status: Completed

Never erase financial history after payout.

---

## 26. PROMOTIONAL BILLBOARD

Place a small billboard/banner/carousel at the top of the feed.

It must be compact and must not cover a large portion of the video.

Possible content:

- Top Seller of the Month
- New Arrival
- Trending Product
- Featured Business
- 50% Sale
- 70% Sale
- Limited-time deal
- Paid featured product

Clicking opens the relevant product/business/deal.

Paid placements must be distinguishable from organic labels.

---

## 27. PAID FEATURED PRODUCT

Seller can select:

> Promote this Product

Launch price:

# PKR 100 / 3 days / product

Flow:

**Select Product → Promote → Pay PKR 100 → Campaign Starts → 3 Days → Campaign Ends**

Show:

- Impressions
- Product views
- Clicks
- Orders generated

Do not falsely present paid placement as organic ranking.

---

## 28. DEALS AND BANK-CARD OFFERS

Create a separate Deals section.

Examples:

> 50% OFF at Restaurant X  
> HBL Cards  
> Limited Time

> 40% OFF at Store Y  
> Meezan Bank Cards

Support:
- Restaurants
- Cafes
- Pizza shops
- Food corners
- Clothing
- Cosmetics
- Beauty
- Shopping
- Other participating businesses

Deal fields:

- Merchant
- Category
- Bank
- Card type
- Discount
- Maximum discount
- Minimum spend
- Valid dates
- Valid days/times
- Location
- Redemption method
- Terms
- Expiry

Do not hide important conditions.

---

## 29. DEAL MONETIZATION

For deals actually purchased through Pitch and Sell:

**PKR 5 per qualifying completed transaction**

For discovery-only deals where the purchase happens completely outside Pitch and Sell, do not falsely claim that a transaction occurred inside the platform.

---

## 30. SEARCH AND DISCOVERY

Search:

- Products
- Businesses
- Categories
- Deals

Filters can include:

- Category
- Price
- Discount
- Location
- Seller
- Availability

---

## 31. SAVED / FAVORITES

Users can save:

- Products
- Videos
- Businesses
- Deals

Provide a dedicated:

# Saved

section.

---

## 32. CUSTOMER ORDER HISTORY

Customer has:

# My Orders

Each order shows:

- Order ID
- Product
- Seller
- Amount
- Payment method
- Status
- Delivery status
- Tracking number
- Date
- Contact seller where appropriate

---

## 33. SELLER ORDER MANAGEMENT

Seller filters:

- New
- Pending
- Accepted
- Processing
- Shipped
- Out for delivery
- Delivered
- Completed
- Cancelled
- Returned

Seller can view all required fulfillment information.

---

## 34. RATINGS AND REVIEWS

Recommended V1 feature.

After a completed order, customers can rate:

- Product
- Seller
- Purchase experience

Use:

**1–5 stars**

Only verified/completed purchasers should be able to leave verified purchase reviews.

---

## 35. INVENTORY

Seller can optionally track:

- Stock quantity
- Low stock
- Out of stock
- Unlimited/service product

When stock reaches zero, disable ordering or show:

> Out of Stock

Simple inventory is sufficient for V1.

---

## 36. RETURNS / REFUNDS / CANCELLATIONS

Support:

- Customer cancellation
- Seller cancellation
- Failed payment
- Failed delivery
- COD return
- Refund
- Partial refund where supported

Financial adjustments must be made through auditable ledger entries, not by silently editing historical transactions.

---

## 37. DELIVERY SETTINGS

Seller can define:

- Delivery areas
- Estimated delivery time
- Delivery fee
- Free-delivery threshold
- Pickup availability if supported

Architecture should allow future courier integrations.

---

## 38. NOTIFICATIONS

### Customer

- New message
- Offer received
- Offer accepted
- Order created
- Order accepted
- Shipment created
- Out for delivery
- Delivered
- Refund
- Seller reply

### Seller

- New order
- New message
- New comment
- Offer accepted
- Order update
- Delivery update
- Earnings update
- Payout status
- Promotion started/ended

### Admin

- New seller
- Payout request
- Reported content
- Payment issue
- Order exception

---

## 39. ADMIN PANEL

Emulgic needs a secure admin panel.

### Users
- Search
- View
- Suspend
- Activate
- Manage roles

### Businesses
- Review
- Verify
- Suspend
- Categories

### Products/Videos
- Moderate
- Remove
- Review reports
- Manage featured content

### Orders
- Search by ID
- View all orders
- Payment status
- Delivery status
- Refund/return workflow

### Financial
- View ledger
- Configure fees
- View transactions
- View balances
- View payout requests

### Payouts
- Approve
- Reject
- Mark processing
- Mark completed

### Promotions
- Manage campaigns
- Approve placements
- View analytics

### Deals
- Create/edit/expire offers
- Manage banks
- Manage merchants

### Analytics
- Users
- Sellers
- Videos
- Engagement
- Orders
- Sales/GMV
- Fees
- Promotions
- Deals
- Payouts

---

## 40. MODERATION AND TRUST

Implement:

- Report video
- Report seller
- Report product
- Report comment
- Block user
- Admin moderation
- Seller verification
- Suspicious activity monitoring

Support moderation for:
- Spam
- Fraud
- Scams
- Misleading claims
- Inappropriate content
- Prohibited products

---

## 41. SECURITY

Implement:

- Secure authentication
- Google OAuth security
- Role-based authorization
- Secure sessions/tokens
- Input validation
- Rate limiting
- File validation
- Secure video uploads
- Protected payout data
- API authorization
- Audit logging
- Payment webhook verification
- Duplicate order/payment protection

Never trust frontend values for:

- Price
- Fees
- Seller earnings
- Payout amount
- Payment status
- Completed sale
- Available balance

These must be calculated and validated server-side.

---

## 42. VIDEO/PERFORMANCE INFRASTRUCTURE

Because this is video-first:

- Use object storage
- Use CDN/video delivery
- Generate thumbnails
- Compress/transcode
- Lazy-load feed content
- Paginate comments
- Paginate orders
- Optimize database queries
- Cache appropriate discovery data

The feed must remain usable on normal mobile internet.

---

## 43. ANALYTICS

### Video

- Views
- Completion rate
- Likes
- Comments
- Shares
- Saves
- Downloads

### Product

- Product views
- Order clicks
- Orders
- Conversion rate

### Seller

- Sales
- Earnings
- Fees
- Top products
- Top videos

### Promotion

- Impressions
- Views
- Clicks
- Orders
- Campaign duration

### Platform

- Users
- Active users
- Sellers
- Orders
- Sales
- Revenue
- Payouts
- Deals

---

## 44. FEED/RECOMMENDATION LOGIC

V1 can use simple ranking based on:

- Recent content
- Engagement
- User interests
- Category
- Location where appropriate
- Trending content
- Seller quality
- Availability

A sophisticated AI recommendation engine can be added later.

---

## 45. SHARE AND DEEP LINKS

Shared content should ideally open the exact Pitch and Sell product/video.

Future deep-link targets:

- Product
- Video
- Seller
- Promotion
- Deal

This is important for organic growth.

---

## 46. DATABASE CORE ENTITIES

Suggested entities:

- User
- BusinessProfile
- Product
- Video
- Category
- Like
- Comment
- CommentReply
- SavedItem
- Chat
- Message
- Offer
- Order
- OrderItem
- Payment
- Shipment
- TransactionLedger
- SellerBalance
- Fee
- Payout
- Promotion
- PromotionCampaign
- Deal
- Bank
- Notification
- Report
- Review
- Inventory
- AdminAction

Core relationships:

**User → BusinessProfile → Product → Video**

**Video → Likes/Comments/Shares/Saves**

**Video/Product → Chat → Offer → Order**

**Order → Payment/Shipment → Ledger → Payout**

**Product → Promotion → Campaign Analytics**

---

## 47. FINANCIAL INTEGRITY

Do not use a simple editable wallet balance.

Use an auditable transaction ledger.

Financial events should support:
- Transaction IDs
- Order IDs
- Fee entries
- Earnings entries
- Refund entries
- Payout entries
- Reversal entries

Use transaction-safe database operations.

Use idempotency for payments and order creation.

---

## 48. EDGE CASES

Handle at minimum:

- Payment fails
- Payment succeeds but webhook is delayed
- Duplicate payment webhook
- Customer closes checkout
- COD cancelled
- COD returned
- Seller rejects order
- Product goes out of stock
- Promotion payment fails
- Promotion expires
- Payout fails
- Invalid payout details
- Video upload fails
- Video exceeds 60 seconds
- Comment is reported
- Seller is suspended
- Customer is suspended
- Network interruption during order creation

Never create duplicate orders because a customer double-clicks.

---

## 49. ADMIN AUDIT LOG

For financial and moderation actions record:

- Admin
- Action
- Entity
- Previous status
- New status
- Timestamp
- Reason where applicable

Example:

> Admin approved payout PAY-000127 for PKR 38,450.

---

## 50. CONFIGURATION

Make these configurable from the admin/backend:

- Maximum video duration
- Pay Now fee
- COD fee
- Promotion price
- Deal fee
- Minimum payout
- Categories
- Banks
- Payment providers
- Courier providers
- Seller verification rules
- Moderation settings

Current launch values:

| Setting | Value |
|---|---:|
| Maximum video | 60 seconds |
| Pay Now fee | PKR 20 |
| COD fee | PKR 10 |
| Featured product | PKR 100 / 3 days |
| Deal transaction fee | PKR 5 |
| Minimum payout | PKR 500 |

---

## 51. MVP PHASE 1

Build first:

1. Welcome screen
2. Google/Gmail authentication
3. Customer signup/login
4. Dual customer/selling mode
5. Business profile
6. Seller video upload
7. 60-second backend video limit
8. Product creation
9. Vertical video feed
10. Like
11. Comments/replies
12. Share
13. Save
14. 
