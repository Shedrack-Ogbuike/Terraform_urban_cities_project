-- Drop the table if it exists
DROP TABLE IF EXISTS staging_nyc_311_data;

-- Create the staging table for NYC 311 data
CREATE TABLE staging_nyc_311_data (
    unique_key VARCHAR(255),
    created_date VARCHAR(255),
    closed_date VARCHAR(255),
    agency VARCHAR(255),
    agency_name VARCHAR(255),
    complaint_type VARCHAR(255),
    descriptor VARCHAR(255),
    location_type VARCHAR(255),
    incident_zip VARCHAR(255),
    incident_address VARCHAR(255),
    street_name VARCHAR(255),
    cross_street_1 VARCHAR(255),
    cross_street_2 VARCHAR(255),
    intersection_street_1 VARCHAR(255),
    intersection_street_2 VARCHAR(255),
    cross_street_name VARCHAR(255),
    borough VARCHAR(255),
    bbl VARCHAR(255),
    open_data_channel_type VARCHAR(255),
    x_coordinate_state_plane VARCHAR(255),
    y_coordinate_state_plane VARCHAR(255),
    latitude NUMERIC,
    longitude NUMERIC,
    location VARCHAR(255),
    park_facility_type VARCHAR(255),
    vehicle_type VARCHAR(255),
    taxi_license_number VARCHAR(255),
    reason VARCHAR(255),
    community_board VARCHAR(255),
    final_drop_off_type VARCHAR(255),
    load_timestamp TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE staging_nyc_311_data IS 'Staging table for raw 311 data loaded via ADF from Azure Blob.';
