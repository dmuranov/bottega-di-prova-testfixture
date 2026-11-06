-- TestPilot proving ground: wipes the old Mocount tables and creates a small
-- shop with known, deliberately planted problems. Run once in Supabase →
-- SQL Editor → Run. Safe to run again (it starts by dropping what it creates).

-- 1. Old Mocount tables (obsolete, confirmed by the owner 2026-11-06)
drop table if exists public.vln_catalog, public.audit_log, public.fees,
  public.number_price_history, public.number_operator_prices, public.numbers,
  public.daily_volume_operators, public.daily_volumes, public.slack_config,
  public.users, public.lvn_members, public.monthly_closes cascade;

-- 2. Proving ground (dropped first so the script can be rerun)
drop table if exists public.order_receipts, public.orders, public.products, public.profiles cascade;
drop function if exists public.is_admin();

create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  email text not null,
  role text not null default 'customer' check (role in ('admin', 'customer')),
  display_name text,
  requires_code boolean not null default false
);

create table public.products (
  id serial primary key,
  name text not null,
  price_cents int not null,
  description text,
  stock int not null default 10
);

create table public.orders (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  product_id int references public.products,
  qty int not null default 1,
  total_cents int not null,
  status text not null default 'placed',
  note text,
  created_at timestamptz not null default now()
);

create table public.order_receipts (
  id bigserial primary key,
  order_id bigint references public.orders on delete cascade,
  user_id uuid not null,
  customer_email text,
  address text,
  card_last4 text,
  created_at timestamptz not null default now()
);

create function public.is_admin() returns boolean
  language sql stable security definer set search_path = public
  as $$ select exists (select 1 from profiles where id = auth.uid() and role = 'admin') $$;

-- 3. Correct protection
alter table public.profiles enable row level security;
create policy "own profile or admin" on public.profiles for select using (id = auth.uid() or public.is_admin());

alter table public.products enable row level security;
create policy "anyone reads products" on public.products for select using (true);

alter table public.orders enable row level security;
create policy "read own orders or admin" on public.orders for select using (user_id = auth.uid() or public.is_admin());
create policy "insert own orders" on public.orders for insert with check (user_id = auth.uid());
create policy "admin deletes orders" on public.orders for delete using (public.is_admin());

-- 4. PLANTED PROBLEM (known answer #5): receipts have NO row-level security,
--    so any signed-in user can read every customer's receipt.
alter table public.order_receipts disable row level security;
grant select, insert on public.order_receipts to anon, authenticated;
grant usage, select on sequence public.order_receipts_id_seq to authenticated;
grant usage, select on sequence public.orders_id_seq to authenticated;
