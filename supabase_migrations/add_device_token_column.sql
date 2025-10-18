-- Add device_token column to users table for FCM push notifications
-- This column stores the Firebase Cloud Messaging device token for each user
-- Admins will receive push notifications when users request gifts

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS device_token TEXT;

-- Add comment to the column
COMMENT ON COLUMN users.device_token IS 'Firebase Cloud Messaging device token for push notifications';

-- Create an index on device_token for faster queries when fetching admin tokens
CREATE INDEX IF NOT EXISTS idx_users_device_token ON users(device_token) WHERE device_token IS NOT NULL;

-- Create an index on is_admin for faster queries when fetching admin device tokens
CREATE INDEX IF NOT EXISTS idx_users_is_admin ON users(is_admin) WHERE is_admin = true;
