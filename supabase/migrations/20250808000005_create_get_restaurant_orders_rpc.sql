-- This migration creates a custom RPC function to fetch orders for a restaurant.
-- This approach uses explicit JOINs and JSON aggregation to avoid issues with
-- PostgREST's relationship detection and schema cache.
CREATE OR REPLACE FUNCTION public.get_restaurant_orders(p_restaurant_id uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER -- Use the permissions of the function owner
AS $$
BEGIN
  RETURN (
    SELECT json_agg(
      json_build_object(
        'id', o.id,
        'created_at', o.created_at,
        'status', o.status,
        'total_price', o.total_price,
        'payment_method', o.payment_method,
        'payment_proof_url', o.payment_proof_url,
        'customer_id', o.customer_id,
        'customer_name', o.customer_name, -- Keep for compatibility
        'customer_phone', o.customer_phone, -- Keep for compatibility
        'restaurant_id', o.restaurant_id,
        'profiles', json_build_object(
          'full_name', p.full_name,
          'phone', p.phone
        ),
        'order_items', (
          SELECT json_agg(
            json_build_object(
              'id', oi.id,
              'quantity', oi.quantity,
              'unit_price', oi.unit_price,
              'dish_id', oi.dish_id,
              'dishes', json_build_object(
                'name', d.name,
                'price', d.price
              )
            )
          )
          FROM public.order_items oi
          LEFT JOIN public.dishes d ON oi.dish_id = d.id
          WHERE oi.order_id = o.id
        )
      )
    )
    FROM public.orders o
    LEFT JOIN public.profiles p ON o.customer_id = p.id
    WHERE o.restaurant_id = p_restaurant_id
    ORDER BY o.created_at DESC
  );
END;
$$;
