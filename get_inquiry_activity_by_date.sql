-- Run this once in Supabase SQL Editor before deploying the matching website change.
-- This public RPC exposes only daily totals; it does not return names, contact details,
-- company names, inquiry text, receipt codes, or answers.
CREATE OR REPLACE FUNCTION public.get_inquiry_activity_by_date()
RETURNS TABLE(inquiry_date date, inquiry_count bigint)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
    SELECT
        (i.created_at AT TIME ZONE 'Asia/Seoul')::date AS inquiry_date,
        COUNT(*) AS inquiry_count
    FROM public.inquiries AS i
    GROUP BY 1
    ORDER BY 1 DESC;
$function$;

REVOKE ALL ON FUNCTION public.get_inquiry_activity_by_date() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_inquiry_activity_by_date() TO anon, authenticated;
