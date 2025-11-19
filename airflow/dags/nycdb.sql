-- This script performs the final transformation and loading (T) after ADF (L) completes.

-- 1. Create the Final Production Table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS public.nyc_311_requests_final (
    request_id          BIGINT PRIMARY KEY,
    created_at          TIMESTAMP,
    closed_at           TIMESTAMP,
    complaint_category  TEXT,
    borough             VARCHAR(50),
    location_zip        VARCHAR(10),
    location_lat        NUMERIC,
    location_lon        NUMERIC,
    agency              TEXT,
    etl_load_date       TIMESTAMP DEFAULT NOW()
);

-- 2. Insert and Transform Data from Staging to Final (ROBUST VERSION)
INSERT INTO public.nyc_311_requests_final (
    request_id,
    created_at,
    closed_at,
    complaint_category,
    borough,
    location_zip,
    location_lat,
    location_lon,
    agency
)
SELECT
    -- Safely cast unique_key to BIGINT (NO redundant CASE/NULL check needed here)
    CAST(TRIM(T1.unique_key) AS BIGINT) AS request_id,
    NULLIF(T1.created_date, '')::TIMESTAMP,
    NULLIF(T1.closed_date, '')::TIMESTAMP,
    TRIM(T1.complaint_type),
    UPPER(TRIM(T1.borough)),
    TRIM(T1.incident_zip),
    T1.latitude,
    T1.longitude,
    T1.agency
FROM
    public.staging_nyc_311_data T1
WHERE 
    -- 1. CRITICAL FIX: Only include rows where unique_key is a valid number.
    TRIM(T1.unique_key) ~ '^[0-9]+$'
    AND 
    -- 2. Prevent insertion of duplicates that already exist in the final table.
    NOT EXISTS (
        SELECT 1 
        FROM public.nyc_311_requests_final T2
        -- Compare the staging ID to the final table ID
        WHERE T2.request_id = CAST(TRIM(T1.unique_key) AS BIGINT)
    );