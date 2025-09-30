-- SQL script to create tables for a simple blog application
-- postgres syntax

-- USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    role VARCHAR(50) DEFAULT 'general',
    photo_url TEXT
);

-- PETS TABLE
CREATE TABLE IF NOT EXISTS pets (
    pet_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    species VARCHAR(100) NOT NULL,
    breed VARCHAR(100),
    age INT,
    weight FLOAT,
    photo_url TEXT
);

-- POSTS TABLE
CREATE TABLE IF NOT EXISTS posts (
    post_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    content JSONB NOT NULL,
    created_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- COMMENTS TABLE
CREATE TABLE IF NOT EXISTS comments (
    comment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- HEALTH_RECORDS TABLE
CREATE TABLE IF NOT EXISTS health_records (
    record_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id UUID NOT NULL REFERENCES pets(pet_id) ON DELETE CASCADE,
    record_type VARCHAR(100) NOT NULL,
    details JSONB NOT NULL,
    date DATE NOT NULL
);

-- DAILY LOGS TABLE
CREATE TABLE IF NOT EXISTS daily_logs (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id UUID NOT NULL REFERENCES pets(pet_id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    notes TEXT
);

-- DAILY LOGS DETAILS TABLE (Activities in the Diagram)
CREATE TABLE IF NOT EXISTS daily_log_details (
    detail_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    log_id UUID NOT NULL REFERENCES daily_logs(log_id) ON DELETE CASCADE,
    food_entries JSONB,
    walk_entries JSONB,
    medication_entries JSONB
);

-- ROLES Lookup TABLE
CREATE TABLE IF NOT EXISTS roles (
    role_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name VARCHAR(50) UNIQUE NOT NULL
);

-- Health Record Types Lookup TABLE
CREATE TABLE IF NOT EXISTS health_record_types (
    type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_name VARCHAR(100) UNIQUE NOT NULL
);

-- Indexes for performance optimization
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_pets_user_id ON pets(user_id);
CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_health_records_pet_id ON health_records(pet_id);