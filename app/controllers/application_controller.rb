class ApplicationController < ActionController::Base
    config.time_zone = 'Eastern Time (US & Canada)'

    def current_user
        @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
    end

    def a_rules
        @a_infractions = Rule.where(track: 'A').where(legacy: false).sort_by {|i| (i.description.split('.')[0].to_i)}
    end

    def b_rules
        @b_infractions = Rule.where(track: 'B').where(legacy: false).sort_by {|i| (i.description.split('.')[0].to_i)}
    end

    def authenticate_user!
        if !current_user
            session[:return_to] = request.fullpath if request.get?
            redirect_to root_path
        end
    end

    def check_super_admin!
        if current_user&.is_super_admin == false
            redirect_to root_path
        end
    end

    def safe_return_path(path)
        uri = URI.parse(path.to_s)
        return uri.to_s if uri.relative? && uri.host.nil? && uri.path.present? && !uri.to_s.start_with?("//")
    rescue URI::InvalidURIError
        nil
    end

    helper_method :current_user
    helper_method :a_rules
    helper_method :b_rules  
end
