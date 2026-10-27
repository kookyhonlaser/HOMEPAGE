-- Run this in the Supabase SQL Editor before publishing the matching index.html.
-- The public board receives only these fields. Private rows are anonymized on the
-- database side; only customer-approved public rows return fields individually
-- marked public. Contact details are never returned.

DROP FUNCTION IF EXISTS public.get_inquiry_board_summaries();

CREATE FUNCTION public.get_inquiry_board_summaries()
RETURNS TABLE (
    created_at timestamptz,
    visibility text,
    inquiry_type text,
    nickname text,
    company text,
    name text,
    public_code text,
    message text,
    admin_reply text,
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
                AND split_part(COALESCE(i.message, ''), E'\n', 1) LIKE '%상담유형=공개%'
                THEN NULLIF(split_part(split_part(i.message, '[상담 유형] ', 2), E'\n', 1), '')
            ELSE NULL
        END AS inquiry_type,
        CASE
            WHEN i.visibility = 'public' AND i.is_public_approved IS TRUE
                AND split_part(COALESCE(i.message, ''), E'\n', 1) LIKE '%닉네임=공개%'
                THEN NULLIF(i.nickname, '')
            ELSE NULL
        END AS nickname,
        CASE
            WHEN i.visibility = 'public' AND i.is_public_approved IS TRUE
                AND split_part(COALESCE(i.message, ''), E'\n', 1) LIKE '%업체명=공개%'
                THEN NULLIF(i.company, '')
            ELSE NULL
        END AS company,
        CASE
            WHEN i.visibility = 'public' AND i.is_public_approved IS TRUE
                AND split_part(COALESCE(i.message, ''), E'\n', 1) LIKE '%성함=공개%'
                THEN NULLIF(i.name, '')
            ELSE NULL
        END AS name,
        CASE
            WHEN i.visibility = 'public' AND i.is_public_approved IS TRUE
                THEN i.public_code
            ELSE NULL
        END AS public_code,
        CASE
            WHEN i.visibility = 'public' AND i.is_public_approved IS TRUE
                AND left(COALESCE(i.message, ''), length('[공개항목]')) = '[공개항목]'
                AND position(E'\n' in i.message) > 0
                THEN substring(i.message from position(E'\n' in i.message) + 1)
            WHEN i.visibility = 'public' AND i.is_public_approved IS TRUE
                THEN i.message
            ELSE NULL
        END AS message,
        CASE
            WHEN i.visibility = 'public' AND i.is_public_approved IS TRUE
                THEN NULLIF(i.admin_reply, '')
            ELSE NULL
        END AS admin_reply,
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

-- Prevent older broad listing RPCs from bypassing the field-level choices.
DO $block$
BEGIN
    IF to_regprocedure('public.get_public_inquiries()') IS NOT NULL THEN
        REVOKE ALL ON FUNCTION public.get_public_inquiries() FROM PUBLIC, anon, authenticated;
    END IF;
    IF to_regprocedure('public.get_inquiry_board_items()') IS NOT NULL THEN
        REVOKE ALL ON FUNCTION public.get_inquiry_board_items() FROM PUBLIC, anon, authenticated;
    END IF;
END;
$block$;
