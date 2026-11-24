class SessionsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    redirect_to root_path if current_user
  end

  def create
    user = User.from_omniauth(request.env["omniauth.auth"])
    return failure unless user

    destination = local_return_path(session[:return_to])
    reset_session
    session[:user_id] = user.id
    session[:signed_in_at] = Time.current.to_i
    redirect_to destination || root_path
  end

  def failure
    redirect_to sign_in_path, alert: "Unable to sign in. Use your authorized staff Google account."
  end

  def destroy
    reset_session
    redirect_to sign_in_path, status: :see_other
  end

  private

  def local_return_path(path)
    return unless path&.start_with?("/") && !path.start_with?("//")
    return if path.match?(/[\\[:cntrl:]]/)

    url_from(path)
  end
end
