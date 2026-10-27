# Public home screen for visitors (no login needed).
class HomeController < ApplicationController
  layout false

  def index
    @site = SiteSetting.instance
    render :maintenance, status: :service_unavailable if @site.maintenance_mode
  end
end
