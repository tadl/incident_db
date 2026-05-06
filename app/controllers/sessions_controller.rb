class SessionsController < ApplicationController
  def create
    user = User.from_omniauth(request.env['omniauth.auth'])
    if user != false
      session[:user_id] = user.id
      redirect_to safe_return_path(session.delete(:return_to)) || incidents_path
    else
      redirect_to root_url, :alert => 'error'
    end
  end
  
  def destroy
    session.delete(:user_id)
    redirect_to root_url
  end

  def test_create
    raise ActionController::RoutingError, "Not Found" unless Rails.env.test?

    session[:user_id] = params[:id]
    redirect_to safe_return_path(session.delete(:return_to)) || incidents_path
  end
end
