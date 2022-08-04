class ApplicationController < ActionController::Base
    config.time_zone = 'Eastern Time (US & Canada)'
    def current_user
        @current_user ||= User.find(session[:user_id]) if session[:user_id]
    end

    def a_rules
        @a_infractions = Rule.where(track: 'A').where(legacy: false).sort_by {|i| (i.description.split('.')[0].to_i)}
    end

    def b_rules
        @b_infractions = Rule.where(track: 'B').where(legacy: false).sort_by {|i| (i.description.split('.')[0].to_i)}
    end

    helper_method :current_user
    helper_method :a_rules
    helper_method :b_rules  
end