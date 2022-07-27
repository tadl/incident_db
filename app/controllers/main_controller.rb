class MainController < ApplicationController
  def index
  end

  def admin_pannel
    @a_infractions = Rule.where(track: 'A').where(legacy: false).sort_by {|i| (i.description.split('.')[0].to_i)}
    @b_infractions = Rule.where(track: 'B').where(legacy: false).sort_by {|i| (i.description.split('.')[0].to_i)}
    @legacy_infractions = Rule.where(legacy: true).sort_by .sort_by {|i| (i.description.split('.')[0].to_i)}
  end
  
end
