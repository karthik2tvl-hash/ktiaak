class DashboardController < AdminController
  def index
    @users_count = User.count
    @products_count = Product.count
    @low_stock_count = Product.where(active: true).where("stock <= 5").count
    @site = SiteSetting.instance
  end
end
