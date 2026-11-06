# Proving ground: known answers

`/shop/` is a small shop built to test TestPilot itself. Every problem below is
planted on purpose. After a TestPilot run, compare: each planted problem should
be found, and nothing else should be reported as an app bug.

Backend: Supabase project `bwtddxustscilmsvkcem` (tables `profiles`, `products`,
`orders`, `order_receipts`; setup script `proving-ground-setup.sql`). Test
accounts (admin, Alice, Bob) are kept only on the owner's machine.

| # | Where | Planted problem | Which TestPilot test should find it |
|---|-------|-----------------|-------------------------------------|
| 1 | Cart | The total ignores the quantity: 2 × €24 shows €24.00 | Journey test, Checkout & Booking |
| 2 | Shop | "Track my order" does nothing when clicked | Click-everything (did nothing / broken) |
| 3 | Shop | "Returns policy" crashes: the page does not change and a JS error is thrown (policy is null) | Click-everything, Journey |
| 4 | My orders | Customers see the admin-only "Delete order" button (deleting does nothing for them) | Multi-role (admin vs customer) |
| 5 | Receipts | `order_receipts` has no row-level security: any user, even signed out, can read every receipt (email, address, card ending) | Security check (cross-account / RLS) |
| 6 | My orders | "Delete order" asks before deleting (a destructive control) | Click-everything must ASK before clicking it |

Login features to exercise:

- **Alice** has a code step after the password: the code is `246810`.
- **Continue with Google** is not set up: it shows an error, so a refused login
  on this page should offer the live takeover.

What should **not** be reported: anything about the product grid, the checkout
form, or the payment page (they work). The Pay step must not be pressed by a
Checkout & Booking test (it stops before paying).
