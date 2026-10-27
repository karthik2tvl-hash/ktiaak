class SiteSettingsController < AdminController
  before_action :set_site_setting

  def edit; end

  def update
    if @site_setting.update(site_setting_params)
      redirect_to edit_site_setting_path, notice: "Site settings saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_site_setting
    @site_setting = SiteSetting.instance
  end

  def site_setting_params
    params.require(:site_setting).permit(
      :site_name, :tagline, :contact_email, :contact_phone, :address,
      :logo_url, :primary_color, :footer_text, :maintenance_mode
    )
  end
end
