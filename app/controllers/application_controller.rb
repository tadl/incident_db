class ApplicationController < ActionController::Base
  SESSION_LIFETIME = 12.hours

  before_action :prevent_caching
  before_action :authenticate_user!
  helper_method :current_user

  private

  def current_user
    return @current_user if defined?(@current_user)

    signed_in_at = session[:signed_in_at]
    @current_user = if signed_in_at.is_a?(Integer) && signed_in_at >= SESSION_LIFETIME.ago.to_i
      User.find_by(id: session[:user_id])
    end
  end

  def authenticate_user!
    return if current_user

    if request.get? && request.format.html?
      session[:return_to] = request.fullpath
      redirect_to sign_in_path
    else
      head :unauthorized
    end
  end

  def prevent_caching
    no_store
  end
end
