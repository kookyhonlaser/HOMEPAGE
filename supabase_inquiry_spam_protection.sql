-- Run in the Supabase SQL Editor to add server-side throttling to every inquiry insert.
-- Allows at most 3 inquiries per source IP in a rolling 15-minute window.
-- The IP is stored only as a salted hash in a private schema and old buckets are purged.

CREATE SCHEMA IF NOT EXISTS inquiry_security;
REVOKE ALL ON SCHEMA inquiry_security FROM PUBLIC, anon, authenticated;

CREATE TABLE IF NOT EXISTS inquiry_security.rate_limit_config (
    singleton boolean PRIMARY KEY DEFAULT true CHECK (singleton),
    hash_salt uuid NOT NULL DEFAULT gen_random_uuid()
);

INSERT INTO inquiry_security.rate_limit_config DEFAULT VALUES
ON CONFLICT (singleton) DO NOTHING;

CREATE TABLE IF NOT EXISTS inquiry_security.inquiry_rate_limits (
    ip_hash text PRIMARY KEY,
    window_started_at timestamptz NOT NULL,
    attempt_count integer NOT NULL,
    updated_at timestamptz NOT NULL
);

CREATE INDEX IF NOT EXISTS inquiry_rate_limits_updated_at_idx
    ON inquiry_security.inquiry_rate_limits (updated_at);

REVOKE ALL ON ALL TABLES IN SCHEMA inquiry_security FROM PUBLIC, anon, authenticated;
ALTER TABLE inquiry_security.rate_limit_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE inquiry_security.inquiry_rate_limits ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION inquiry_security.guard_inquiry_submission_rate()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, inquiry_security
AS $function$
DECLARE
    request_headers jsonb;
    forwarded_for text;
    client_ip text;
    salt uuid;
    bucket_hash text;
    current_attempt_count integer;
BEGIN
    BEGIN
        request_headers := nullif(current_setting('request.headers', true), '')::jsonb;
    EXCEPTION WHEN OTHERS THEN
        request_headers := NULL;
    END;

    forwarded_for := request_headers ->> 'x-forwarded-for';
    client_ip := btrim(split_part(coalesce(forwarded_for, ''), ',', 1));

    -- SQL Editor/manual administrative inserts have no forwarded client IP and are not throttled.
    IF client_ip = '' THEN
        RETURN NEW;
    END IF;

    SELECT hash_salt INTO salt
    FROM inquiry_security.rate_limit_config
    WHERE singleton = true;

    bucket_hash := md5(client_ip || ':' || salt::text);

    DELETE FROM inquiry_security.inquiry_rate_limits
    WHERE updated_at < now() - interval '24 hours';

    INSERT INTO inquiry_security.inquiry_rate_limits AS existing (
        ip_hash,
        window_started_at,
        attempt_count,
        updated_at
    ) VALUES (
        bucket_hash,
        now(),
        1,
        now()
    )
    ON CONFLICT (ip_hash) DO UPDATE
    SET window_started_at = CASE
            WHEN existing.window_started_at <= now() - interval '15 minutes' THEN now()
            ELSE existing.window_started_at
        END,
        attempt_count = CASE
            WHEN existing.window_started_at <= now() - interval '15 minutes' THEN 1
            ELSE existing.attempt_count + 1
        END,
        updated_at = now()
    RETURNING attempt_count INTO current_attempt_count;

    IF current_attempt_count > 3 THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = '문의 접수가 잠시 제한되었습니다. 15분 후 다시 시도해 주세요.';
    END IF;

    RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION inquiry_security.guard_inquiry_submission_rate() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS inquiry_submission_rate_limit ON public.inquiries;
CREATE TRIGGER inquiry_submission_rate_limit
BEFORE INSERT ON public.inquiries
FOR EACH ROW
EXECUTE FUNCTION inquiry_security.guard_inquiry_submission_rate();
