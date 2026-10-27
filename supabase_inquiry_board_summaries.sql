-- Run this in the Supabase SQL Editor before publishing the matching index.html.
-- The public board receives only these fields. Private rows are anonymized on the
-- database side; only customer-approved public rows return a nickname, receipt code
-- and message summary source. Company and contact details are never returned.

DROP FUNCTION IF EXISTS public.get_inquiry_board_summaries();

CREATE FUNCTION public.get_inquiry_board_summaries()
RETURNS TABLE (
    created_at timestamptz,
    visibility text,
    nickname text,
    public_code text,
    message text,
    status text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $function$
    SELECT
        i.created_at,
        COALESCE(i.visibility, 'private')::text AS visibility,
        CASE
            WHEN i.visibility = 'public' AND i.is_public_approved IS TRUE
                THEN NULLIF(i.nickname, '')
            ELSE NULL
        END AS nickname,
        CASE
            WHEN i.visibility = 'public' AND i.is_public_approved IS TRUE
                THEN i.public_code
            ELSE NULL
        END AS public_code,
        CASE
            WHEN i.visibility = 'public' AND i.is_public_approved IS TRUE
                THEN i.message
            ELSE NULL
        END AS message,
        COALESCE(i.status::text, 'received') AS status
    FROM public.inquiries AS i
    WHERE
        COALESCE(i.visibility, 'private') = 'private'
        OR (i.visibility = 'public' AND i.is_public_approved IS TRUE)
    ORDER BY i.created_at DESC
    LIMIT 500;
$function$;

REVOKE ALL ON FUNCTION public.get_inquiry_board_summaries() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_inquiry_board_summaries() TO anon, authenticated;
