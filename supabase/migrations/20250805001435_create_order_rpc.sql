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
security definer -- <<< --- ADD THIS LINE
as $$
declare
  new_order_id uuid;
  item jsonb;
begin
  -- The rest of the function remains exactly the same
  -- 1. Insert the main order...
  insert into public.orders (
    customer_name, customer_phone, restaurant_id, total_price, payment_method, payment_proof_url
  ) values (
    create_order.customer_name, create_order.customer_phone, create_order.restaurant_id, create_order.total_price, create_order.payment_method, create_order.payment_proof_url
  ) returning id into new_order_id;

  -- 2. Loop through the JSON array of items...
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

  -- 3. Return the ID of the order...
  return new_order_id;
end;
$$;