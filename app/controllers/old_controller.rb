class OldController < ApplicationController

  def list
    @reports = Oldreport.order(date_of: :desc, id: :desc).paginate(page: params[:page], per_page: 10)
  end

  def view
    @report = Oldreport.find(params[:id])
  end

  def search
    @query = params[:query] if params[:query].is_a?(String)
    reports = @query.present? ? Oldreport.search(@query) : Oldreport.none
    @reports = reports.paginate(page: params[:page], per_page: 10)
  end
end
