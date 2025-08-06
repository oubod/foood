-- This migration adds a function to confirm an order's payment.
CREATE OR REPLACE FUNCTION public.confirm_order(p_order_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  restaurant_owner_id uuid;
  is_admin boolean;
BEGIN
  -- Check if the current user is an admin
  SELECT (role = 'admin') INTO is_admin FROM public.profiles WHERE id = auth.uid();

  -- Get the owner of the restaurant associated with the order
  SELECT r.owner_id INTO restaurant_owner_id
  FROM public.orders o
  JOIN public.restaurants r ON o.restaurant_id = r.id
  WHERE o.id = p_order_id;

  -- Check if the current user is the owner of the restaurant or an admin.
  IF is_admin OR auth.uid() = restaurant_owner_id THEN
    UPDATE public.orders
    SET status = 'preparing'
    WHERE id = p_order_id AND status = 'pending_payment';

    RETURN FOUND; -- Returns true if the UPDATE was successful
  ELSE
    -- User is not authorized
    RAISE EXCEPTION 'User is not authorized to confirm this order';
  END IF;
END;
$$;
