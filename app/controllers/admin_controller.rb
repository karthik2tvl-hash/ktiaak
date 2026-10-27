# Base class for every screen inside the admin panel.
class AdminController < ApplicationController
  before_action :authenticate_admin!
  layout "admin"
end
