-- Drop the old type (and any dependencies, which we'll recreate)
ALTER TYPE public.order_status RENAME TO order_status_old;

-- Create the new, more detailed type
CREATE TYPE public.order_status AS ENUM (
  'pending_payment', -- New: For electronic payments awaiting approval
  'preparing',
  'ready_for_pickup', -- New: Replaces 'ready'
  'delivering',       -- New: For when the driver is on the way
  'delivered',
  'cancelled'
);

-- Update the 'orders' table to use the new type
ALTER TABLE public.orders ALTER COLUMN status DROP DEFAULT;
ALTER TABLE public.orders ALTER COLUMN status SET DATA TYPE public.order_status USING status::text::public.order_status;

-- Drop the old, unused type
DROP TYPE public.order_status_old;

-- Also, let's update our create_order function to handle this new default status
-- This ensures new orders start in the correct state.
create or replace function create_order(
  customer_name text,
  customer_phone text,
  restaurant_id uuid,
  total_price numeric,
  payment_method text,
  payment_proof_url text,
  order_items jsonb
)
returns uuid
language plpgsql
security definer
as $$
declare
  new_order_id uuid;
  item jsonb;
  initial_status public.order_status;
begin
  -- Set initial status based on payment method
  if payment_method = 'electronic' then
    initial_status := 'pending_payment';
  else
    initial_status := 'preparing';
  end if;

  insert into public.orders (
    customer_name, customer_phone, restaurant_id, total_price, payment_method, payment_proof_url, status
  ) values (
    create_order.customer_name, create_order.customer_phone, create_order.restaurant_id, create_order.total_price, create_order.payment_method, create_order.payment_proof_url, initial_status
  ) returning id into new_order_id;

  for item in select * from jsonb_array_elements(create_order.order_items)
  loop
    insert into public.order_items (order_id, dish_id, quantity, unit_price)
    values (
      new_order_id,
      (item->>'dish_id')::uuid,
      (item->>'quantity')::int,
      (item->>'unit_price')::numeric
    );
  end loop;

  return new_order_id;
end;
$$;