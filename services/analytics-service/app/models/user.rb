# frozen_string_literal: true

# Lightweight User model for analytics tracking
# This represents users from the User Service
class User < ApplicationRecord
  self.table_name = 'users'
  
  # We don't have a users table in Analytics Service
  # but we need this model for associations
  # In production, user_id would reference User Service
  
  def self.table_exists?
    false
  end
end