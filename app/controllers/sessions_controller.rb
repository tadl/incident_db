class SessionsController < ApplicationController
  before_action :set_headers
  def create
    user = User.from_omniauth(request.env['omniauth.auth'])
    if user != false
      session[:user_id] = user.id
      url = request.env['omniauth.origin']
      redirect_to url
    else
      redirect_to root_url, :alert => 'error'
    end
  end
  
  def destroy
    session.delete(:user_id)
    redirect_to root_url
  end
end