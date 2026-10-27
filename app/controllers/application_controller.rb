class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :invite_code])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  # After login or sign up, send admins to the dashboard (not the public home page)
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || (resource.is_a?(Admin) ? admin_root_path : super)
  end
end
