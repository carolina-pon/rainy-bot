class User < ApplicationRecord
  validates :line_id, presence: true
end
