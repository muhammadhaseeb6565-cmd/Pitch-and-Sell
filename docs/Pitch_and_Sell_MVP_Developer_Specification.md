**EMULGIC**

**PITCH AND SELL**

**MVP DEVELOPER SPECIFICATION**

*Complete product, user-flow, business-model, payment, seller, and admin
requirements*

**Prepared for Haseeb → Antigravity Development**

  -----------------------------------------------------------------------
  **Core rule**                       **MVP requirement**
  ----------------------------------- -----------------------------------
  Product name                        Pitch and Sell (must remain
                                      unchanged for MVP)

  Company                             Emulgic (Pvt.) Ltd.

  Experience                          Mobile-first short-form video
                                      marketplace

  Video limit                         Maximum 60 seconds

  Account model                       One account: Normal User Mode +
                                      Selling Mode

  Payments                            Pay Now + Cash on Delivery (COD)

  Minimum seller payout               PKR 500

  Paid showcase                       PKR 100 per product for
                                      approximately 3 days
  -----------------------------------------------------------------------

# 1. Product Overview

Pitch and Sell is Emulgic\'s first startup platform. Businesses and
sellers showcase products through short-form videos. Customers discover
products, communicate with sellers inside the app, and place orders
through the platform.

The MVP must feel like a real professional mobile application, not a
desktop website squeezed into a phone.

## MVP goals

-   Discover products through a scrollable short-video feed.

-   Create seller/business profiles and upload product videos.

-   Use one account for Normal User Mode and Selling Mode.

-   Like, comment, share, download and save product videos.

-   Keep customer-seller communication inside Pitch and Sell through
    in-app chat.

-   Place orders using Pay Now or COD.

-   Track every order, payment type, seller fee, balance and payout.

-   Give Emulgic a separate secure admin portal for platform-wide
    monitoring.

-   Show a small rotating billboard above the feed.

-   Show business discounts and bank-card deals in a separate section.

# 2. Branding and UI Direction

Use the uploaded Emulgic branding artwork as the visual reference.

-   Coral/orange, dark charcoal, warm off-white/cream, white typography
    and restrained muted-gray elements.

-   Use the Emulgic logo/robot mark appropriately.

-   Use the diagonal orange/charcoal motif subtly.

-   Modern cards, buttons, typography, spacing and icons.

-   Mobile-first, thumb-friendly controls and clean navigation.

-   Professional/premium appearance. Do not make it look like a cheap
    desktop HTML mockup.

# 3. Authentication and Account Modes

## First screen

-   Welcome to Pitch and Sell.

-   Sign up.

-   Log in.

-   Sign in with Gmail/Google.

-   Returning users must be able to log back into their existing
    account.

## Normal User Mode

-   Browse/search

-   Watch videos

-   Like/comment/share/download/save

-   Chat with sellers

-   Place orders

-   View own orders

## Selling Mode

-   Create/manage business profile

-   Upload/manage products and videos

-   Seller dashboard

-   View seller orders

-   View earnings and Emulgic fees

-   Request payout

-   View payout history

One account must be able to switch between Normal User Mode and Selling
Mode. A user who has not completed seller setup should be guided through
business profile creation.

# 4. Seller / Business Experience

## Business profile

-   Business name

-   Business category

-   Contact information

-   Business logo/profile image

-   Basic business information visible to customers

## Product/video upload

-   Upload a product video.

-   Maximum duration is 60 seconds.

-   Reject/validate videos longer than 60 seconds.

-   Product title, description, price and category.

-   Associate product with seller/business.

-   Publish, edit and manage product content.

## Seller dashboard

-   Views

-   Engagement

-   Likes/comments where tracked

-   Orders/sales

-   Pay Now count/value

-   COD count/value

-   Earnings

-   Amount owed to Emulgic

-   Available/pending balance

-   Payout history

-   Request payout

# 5. Customer / Viewer Experience

## Home feed

-   Scrollable short-form product videos

-   Seller/business identity

-   Product title/price

-   Like

-   Comment

-   Share

-   Download

-   Save/Favorite

## Search/category browsing

-   Search products

-   Search businesses

-   Browse categories

## Product/video page

-   Video

-   Title

-   Description

-   Price

-   Business information

-   Order/Buy

-   Chat/contact seller

-   Like/comment/share/download/save

## Saved/Favorites

-   Save products/videos

-   Access saved content later

# 6. Social and In-App Communication

-   Like, comment, share, download and save actions on product videos.

-   In-app customer ↔ seller chat. Do not force users to WhatsApp.

-   Keep product context in conversations where possible.

-   Support pre-purchase questions and bulk-order discussions.

-   Keep conversation/order context inside the platform to improve order
    attribution and tracking.

# 7. Ordering and Order Tracking

Every order must receive a unique Pitch and Sell Order ID and remain
linked to the customer, seller, product, payment and settlement
information.

## Order flow

1.  Customer clicks Order/Buy.

2.  Order form opens.

3.  Collect required customer details.

4.  Collect product, quantity, price and total.

5.  Customer chooses Pay Now or COD.

6.  Create the Pitch and Sell order record.

7.  Seller receives the order.

8.  Emulgic admin sees the same authoritative order.

## Order lifecycle

-   Created/Pending confirmation

-   Confirmed

-   Shipped/Dispatched

-   Delivered/Completed

-   Cancelled

-   Returned

An order submission is not automatically a completed sale. The system
must distinguish successful delivery/settlement from cancellation or
return.

# 8. COD

-   COD is a first-class tracked payment method.

-   Create a Pitch and Sell Order ID when COD is selected.

-   Send the order to the seller and record it for Emulgic admin.

-   Track delivery/settlement state.

-   Associate courier/shipment information where available. Leopards may
    be used for delivery.

-   Cancelled/returned COD orders should not be treated as normal
    completed sales.

-   COD platform fee: PKR 10 per qualifying COD order.

# 9. Pay Now, Seller Balance and Payout

-   Customer chooses Pay Now.

-   Payment is tied to the specific Order ID.

-   Seller-attributable funds are reflected in the platform
    balance/wallet according to the payment provider flow.

-   Emulgic fee is recorded against the order.

-   Seller cannot directly withdraw money.

-   Seller requests a payout.

-   Minimum payout is PKR 500.

## Payout workflow

9.  Seller opens earnings/wallet.

10. Seller sees available balance.

11. Seller requests payout (minimum PKR 500).

12. Emulgic admin sees the request.

13. Admin approves or rejects.

14. Approved payout is processed to the configured seller destination.

15. Payout status/history is stored.

  -----------------------------------------------------------------------
  **Revenue source**                  **MVP rule**
  ----------------------------------- -----------------------------------
  Pay Now order                       PKR 20 Emulgic fee per qualifying
                                      order

  COD order                           PKR 10 Emulgic fee per qualifying
                                      order

  Billboard/product showcase          PKR 100 per product for
                                      approximately 3 days

  Card/deal purchase                  PKR 5 Emulgic fee per qualifying
                                      transaction

  Minimum seller payout               PKR 500
  -----------------------------------------------------------------------

# 10. Rotating Billboard / Sponsored Products

Place a small billboard/banner above the video feed. It should not cover
a large portion of the feed.

-   Automatically rotate from one promotion to another.

-   Possible content: top seller of the month, new products, best
    products, limited-time offers, 50%/70% sales and other featured
    products.

-   Seller can pay to showcase a selected product.

-   Price: PKR 100 per product for approximately 3 days.

-   Store seller, product, start/end time and active/expired status.

-   Admin can manage promotions.

-   Expired promotions stop appearing.

-   Sponsored content should be clearly labeled.

# 11. Bank-Card Discounts and Deals

-   Separate deals/card-offers section.

-   Support restaurants, cafés, malls, cosmetics/beauty, clothing, food
    outlets and other participating businesses.

-   Show business, discount/offer, participating card/bank where
    applicable, and validity.

-   Examples discussed include Meezan/Meezan Bank, HBL, UBL and Allied
    Bank offers, subject to actual partnerships/data.

-   Track qualifying card/deal transactions.

-   Platform fee: PKR 5 per qualifying transaction.

# 12. Separate Emulgic Admin Portal

Build the admin portal as a separate secure interface, but connect it to
the same backend/database/source of truth as the Pitch and Sell app. Do
not create a second disconnected data system.

Normal users and sellers must never see platform-wide admin data.
Security must be enforced by backend role authorization, not only by
hiding a button.

## Admin authentication

-   Dedicated admin login

-   Role-based authorization

-   Only authorized Emulgic administrators

-   Protected sessions

-   Audit important financial/admin actions

## Admin dashboard

-   Total/active sellers

-   Total customers

-   Total products

-   Total orders

-   Today\'s orders

-   Pay Now orders

-   COD orders

-   Completed/delivered orders

-   Cancelled/returned orders

-   Gross transaction value

-   Emulgic fees

-   Pending payouts

-   Billboard revenue

-   Card/deal revenue

## Admin: Sellers

-   Search sellers

-   Seller profile

-   Products

-   Total orders

-   Pay Now vs COD

-   Completed/cancelled/returned orders

-   Gross sales

-   Emulgic fees

-   Seller balance

-   Payout requests/history

-   Seller status

## Admin: Orders

-   Order ID

-   Seller

-   Customer

-   Product

-   Quantity

-   Amount

-   Payment method/status

-   Order status

-   Delivery/shipment status where available

-   Platform fee

-   Seller earning/balance impact

-   Date/time

-   Payout/settlement status

-   Filters by seller, customer, payment type, status and date

## Admin: Customers

-   Search

-   Required account information

-   Order history

-   Pay Now/COD history

-   Completed/cancelled/returned orders

-   Relevant support information

## Admin: Payments and payouts

-   Pay Now payments

-   COD settlement state

-   Platform fees

-   Seller balances

-   Payout requests

-   Approve/reject

-   Payout status

-   Payout history

## Admin: Promotions

-   Promotion requests

-   Seller/product

-   Start/end

-   Price

-   Status

-   Active/expired promotions

-   PKR 100 promotion revenue

## Admin: Deals

-   Create/manage deals

-   Offer details

-   Card/bank information where applicable

-   Validity

-   Status

-   Qualifying transactions

-   PKR 5 fee tracking

## Admin: Reports

-   Sales

-   Orders

-   Sellers

-   Customers

-   COD vs Pay Now

-   Platform revenue

-   Payouts

-   Promotions

-   Card/deal revenue

# 13. Minimum Data That Must Be Trackable

  -----------------------------------------------------------------------
  **Record**                          **Minimum business information**
  ----------------------------------- -----------------------------------
  User                                User ID, name, contact/auth
                                      information, roles/mode

  Seller                              Seller ID, business name, category,
                                      contact, logo, status

  Product                             Product ID, seller, title,
                                      description, price, category,
                                      video, status

  Order                               Order ID, customer, seller,
                                      product, quantity, amount, payment
                                      method/status, order status, dates

  COD                                 Order, delivery/settlement state,
                                      fee status

  Payment                             Order, amount, method, status,
                                      transaction/reference

  Seller balance                      Credits, fees, available/pending
                                      balance

  Payout                              Seller, amount, date, status,
                                      processed amount/reference

  Promotion                           Seller, product, start/end, price,
                                      status

  Deal                                Business, offer, card/bank,
                                      validity, status, transaction

  Engagement                          Views, likes, comments, shares,
                                      saves

  Chat                                Customer, seller, conversation,
                                      timestamps, product/order context
  -----------------------------------------------------------------------

# 14. Example Financial Logic

  -----------------------------------------------------------------------
  **Scenario**      **Order value**   **Emulgic fee**   **Seller-side
                                                        result**
  ----------------- ----------------- ----------------- -----------------
  Pay Now           PKR 2,000         PKR 20            PKR 1,980 before
                                                        other agreed
                                                        costs

  COD               PKR 2,000         PKR 10            PKR 1,990 subject
                                                        to COD/delivery
                                                        settlement
  -----------------------------------------------------------------------

The exact implementation should keep fees configurable where practical.
Do not count an order as completed revenue merely because an order form
was submitted.

# 15. Suggested MVP Navigation

-   Home/Feed

-   Search/Categories

-   Deals/Card Offers

-   Saved/Favorites

-   Profile

-   Chat

-   Order history/details

-   Selling Mode tools when switched on

Navigation can be adjusted during UI work, but every required feature
must remain easy to reach.

# 16. Security and Abuse Prevention

-   Admin portal isolated by backend role authorization.

-   Sellers see only their own seller data.

-   Customers see only their own private account/order data and
    conversations.

-   Do not rely on hidden UI buttons for security.

-   Validate the 60-second video limit server-side.

-   Validate order totals and fees server-side.

-   Prevent duplicate order/payment records where possible.

-   Audit important admin/payout changes.

-   Protect customer and seller personal information.

# 17. MVP Build Priority

  --------------------------------------------------------------------------
  **Priority**                        **Must be working**
  ----------------------------------- --------------------------------------
  P0                                  Gmail/Google authentication

  P0                                  Normal User + Selling Mode

  P0                                  Seller/business profile

  P0                                  Product/video upload + 60-second limit

  P0                                  Short-video feed

  P0                                  Search/categories

  P0                                  Product detail + ordering

  P0                                  Like/comment/share/download/save

  P0                                  In-app chat

  P0                                  Pay Now + COD

  P0                                  Unique Order IDs + full order records

  P0                                  Seller earnings/fee tracking

  P0                                  PKR 500 minimum payout + payout
                                      request

  P0                                  Separate secure Emulgic admin portal

  P0                                  Admin
                                      seller/customer/order/payment/payout
                                      tracking

  P0                                  Rotating billboard + PKR 100/3-day
                                      promotion

  P0                                  Deals/card offers + PKR 5 transaction
                                      tracking

  P1                                  Advanced analytics/reports

  P1                                  Deeper courier automation

  P1                                  Advanced AI-assisted
                                      order/conversation detection
  --------------------------------------------------------------------------

# 18. MVP Acceptance Checklist

-   [ ] Welcome screen and sign-up/login work.

-   [ ] Gmail/Google sign-in works.

-   [ ] One account can switch between Normal User and Selling Mode.

-   [ ] Seller can create a business profile.

-   [ ] Videos longer than 60 seconds are rejected.

-   [ ] Customer can scroll the product video feed.

-   [ ] Each video has like, comment, share, download and save.

-   [ ] Search and categories work.

-   [ ] Product detail page works.

-   [ ] Customer can chat with seller in-app.

-   [ ] Customer can place Pay Now or COD order.

-   [ ] Every order gets a unique Order ID.

-   [ ] Seller and authorized admin see the same order record.

-   [ ] Pay Now and COD are clearly distinguished.

-   [ ] Platform fees are correctly recorded.

-   [ ] Seller cannot directly withdraw.

-   [ ] Payout request requires at least PKR 500.

-   [ ] COD lifecycle distinguishes delivery/completion from
    cancellation/return.

-   [ ] Billboard automatically rotates.

-   [ ] Seller can purchase PKR 100 / approximately 3-day showcase.

-   [ ] Deals/card offers have a dedicated section.

-   [ ] Qualifying card/deal transactions can be tracked for PKR 5 fee.

-   [ ] Admin cannot be accessed by normal users/sellers.

-   [ ] Admin can track sellers, customers, orders, payments, fees and
    payouts.

-   [ ] App is mobile-first and follows Emulgic branding.

# 19. Keep Out of MVP Unless Already Easy

-   Large-scale recommendation algorithms.

-   Complex AI automation beyond required order/chat context.

-   Advanced ad targeting.

-   Full logistics management if courier integration is not ready.

-   Complex loyalty/rewards systems.

-   Large multi-country/multi-currency support.

-   Anything that delays the core customer → order → payment/COD →
    seller balance → admin tracking loop.

# 20. Final Developer Principle

**Build one Pitch and Sell platform with one source of truth for
business data, multiple secure user experiences, and a separate Emulgic
admin control room.**

The critical chain is: Customer → Product → Order → Payment/COD → Seller
Balance → Emulgic Fee → Payout → Admin Record.

If a customer places an order, the seller and authorized Emulgic admin
must see the same authoritative order. If Pay Now occurs, it is tied to
that order. If COD is delivered, the order reflects delivery/settlement.
If a seller requests payout, the admin sees the request and the seller
balance/history reflects the result.
