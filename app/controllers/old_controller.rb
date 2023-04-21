class OldController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!

  def list
    @reports = Oldreport.paginate(page: params[:page], per_page: 10).order(date_of: :desc)
  end

  def show
  end
end
