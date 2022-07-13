class SessionsController < ApplicationController
    def create
      user = User.from_omniauth(request.env['omniauth.auth'])
      if user != false
        session[:user_id] = user.id
        url = request.env['omniauth.origin']
        redirect_to url
      else
        redirect_to root_url, :alert => Settings.error_msg.invalid_domain
      end
    end
  
    def destroy
      puts 'sam was here'
      session.delete(:user_id)
      redirect_to root_url
    end
end