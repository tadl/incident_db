class Comment < ApplicationRecord
  def submitted_by
    user = User.find(self.user_id)
    return user.name
  end

  def submitted_by_pic
    user = User.find(self.user_id)
    return user.avatar
  end

  def posted_on
    return self.created_at.in_time_zone("Eastern Time (US & Canada)").strftime("%m/%d/%Y at %l:%M %p")
  end

  def edited_on
    return self.updated_at.in_time_zone("Eastern Time (US & Canada)").strftime("%m/%d/%Y at %l:%M %p")
  end

  def was_edited
    if self.updated_at != self.created_at
      return true
    else
      return false
    end
  end

end
