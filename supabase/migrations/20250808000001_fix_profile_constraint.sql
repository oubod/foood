-- Fix profile creation constraint issue
-- Ensure the trigger handles profile creation properly

-- Update the trigger function to handle edge cases
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY definer SET search_path = public
AS $$
BEGIN
  -- Check if NEW.id is not null before inserting
  IF NEW.id IS NOT NULL THEN
    INSERT INTO public.profiles (id, role, full_name, phone)
    VALUES (
      NEW.id,
      COALESCE(NEW.raw_user_meta_data->>'role', 'customer')::public.app_role,
      COALESCE(NEW.raw_user_meta_data->>'full_name', 'مستخدم'),
      NEW.raw_user_meta_data->>'phone'
    )
    ON CONFLICT (id) DO UPDATE SET
      full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
      phone = COALESCE(EXCLUDED.phone, profiles.phone),
      updated_at = now();
  END IF;
    
  RETURN NEW;
END;
$$;