class PatronsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def save
    if params[:id] && params[:id] != ''
      id = param[:id].to_i
      @patron = Patron.find(id)
    else
      @patron = Patron.new
    end
    @patron.assign_attributes(patron_params)
    @patron.save
    respond_to do |format|
      format.js
    end
  end

  def edit
  end

  def list
  end

  def show
  end

  private

  def patron_params
    params.permit(:first_name, :middle_name, :last_name, :no_name, :no_address, :city, :state, :zip, :alias, :description, :notes, :card_number)
  end

end
