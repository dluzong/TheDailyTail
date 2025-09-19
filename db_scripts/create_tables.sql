-- SQL script to create tables for a simple blog application
-- postgres syntax

-- USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    password VARCHAR(100) NOT NULL,
    role VARCHAR(50) DEFAULT 'general', -- roles: owner, foster, rescue, adoption, general (should i make this an enum?)
);

-- PETS TABLE
CREATE TABLE IF NOT EXISTS pets (
    pet_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),
    name VARCHAR(100) NOT NULL,
    species VARCHAR(100) NOT NULL,
    breed VARCHAR(100) NOT NULL,
    age INT NOT NULL,
    weight FLOAT NOT NULL
);

-- POSTS TABLE
CREATE TABLE IF NOT EXISTS posts (
    post_id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(user_id),
    content JSONB NOT NULL,
    created_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- COMMENTS TABLE
CREATE TABLE IF NOT EXISTS comments (
    comment_id SERIAL PRIMARY KEY,
    post_id INT REFERENCES posts(post_id),
    user_id UUID REFERENCES users(user_id),
    content TEXT NOT NULL,
    created_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- HEALTH_RECORDS TABLE
CREATE TABLE IF NOT EXISTS health_records (
    record_id SERIAL PRIMARY KEY,
    pet_id UUID REFERENCES pets(pet_id),
    record_type VARCHAR(100) NOT NULL, -- e.g., vaccination, check-up (should i make this an enum?)
    details JSONB NOT NULL,
    date DATE NOT NULL
);

-- DAILY LOGS TABLE
CREATE TABLE IF NOT EXISTS daily_logs (
    log_id SERIAL PRIMARY KEY,
    pet_id UUID REFERENCES pets(pet_id),
    log_date TIMESTAMP NOT NULL,
    notes TEXT OPTIONAL
);

-- DAILY LOGS DETAILS TABLE (Activities in the Diagram)
CREATE TABLE IF NOT EXISTS daily_log_details (
    detail_id SERIAL PRIMARY KEY,
    log_id INT REFERENCES daily_logs(log_id),
    food_entries JSONB,
    walk_entries JSONB,
    medication_entries JSONB
);

CREATE INDEX idx_user_id ON users(user_id);

