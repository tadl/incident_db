class Comment < ApplicationRecord
  belongs_to :user, optional: true
  validates :description, presence: true, length: { maximum: 16_000 }

  def submitted_by
    user&.name.presence || "Former staff member"
  end

  def posted_on
    created_at&.strftime("%m/%d/%Y at %l:%M %p")
  end

  def edited_on
    updated_at&.strftime("%m/%d/%Y at %l:%M %p")
  end

  def was_edited
    updated_at != created_at
  end
end
