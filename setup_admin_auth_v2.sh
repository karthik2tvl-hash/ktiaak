#!/usr/bin/env bash
# Run AFTER setup_admin_auth_v2.sh and add_admin_setup.sh. Run from INSIDE admin_portal:
#   bash ../add_home_and_passwords.sh
#
# 1. User setup: the admin can now set / change a password for each user
#    (stored as a secure bcrypt hash, never as plain text).
# 2. Home screen: your 4-section website (index.html) becomes the public home page "/".
#    The admin dashboard moves to /admin, and sign in takes admins there.
#    The home page also picks up the Site setup values (name, brand colour, footer text,
#    maintenance mode).
set -e

if [ ! -f app/models/user.rb ] || [ ! -f app/views/layouts/admin.html.erb ]; then
  echo "Run this from inside admin_portal, after add_admin_setup.sh"
  exit 1
fi

# Find the website file (the 4-section index.html)
WEBSITE=""
for candidate in "${WEBSITE_HTML:-}" ../index.html ./index.html; do
  if [ -n "$candidate" ] && [ -f "$candidate" ]; then WEBSITE="$candidate"; break; fi
done
if [ -z "$WEBSITE" ]; then
  echo "Could not find index.html. Put it next to the admin_portal folder, or run:"
  echo "  WEBSITE_HTML=/path/to/index.html bash ../add_home_and_passwords.sh"
  exit 1
fi

# ---------- 1. Passwords for users ----------
bundle add bcrypt || true
rails generate migration AddPasswordDigestToUsers password_digest:string
rails db:migrate

cat > app/models/user.rb <<'EOF'
class User < ApplicationRecord
  ROLES = %w[member editor support].freeze

  has_secure_password

  attribute :active, :boolean, default: true
  attribute :role, :string, default: "member"

  before_validation { self.email = email.to_s.strip.downcase }

  validates :name, presence: true, length: { maximum: 80 }
  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: ROLES }
  validates :phone, length: { maximum: 20 }, allow_blank: true
  validates :password, length: { minimum: 8 }, allow_blank: true

  scope :search, lambda { |q|
    next all if q.blank?
    like = "%#{sanitize_sql_like(q)}%"
    where("name LIKE :q OR email LIKE :q", q: like)
  }
end
EOF

ruby <<'RUBY'
path = "app/controllers/users_controller.rb"
src = File.read(path, encoding: "UTF-8")
from = "permit(:name, :email, :phone, :role, :active)"
abort "Could not update #{path}" unless src.include?(from)
File.write(path, src.sub(from) { "permit(:name, :email, :phone, :role, :active, :password, :password_confirmation)" }, encoding: "UTF-8")
RUBY

cat > app/views/users/_form.html.erb <<'EOF'
<%= form_with model: user do |f| %>
  <%= render "shared/errors", record: user %>

  <div class="form-grid two">
    <div>
      <%= f.label :name, "Full name" %>
      <%= f.text_field :name, required: true, autofocus: true %>
    </div>
    <div>
      <%= f.label :email %>
      <%= f.email_field :email, required: true %>
    </div>
    <div>
      <%= f.label :phone %>
      <%= f.telephone_field :phone %>
    </div>
    <div>
      <%= f.label :role %>
      <%= f.select :role, User::ROLES.map { |r| [r.titleize, r] } %>
    </div>
    <div>
      <%= f.label :password, user.new_record? ? "Password" : "New password" %>
      <%= f.password_field :password, autocomplete: "new-password",
            required: user.new_record?, minlength: 8 %>
      <div class="hint">
        <% if user.new_record? %>At least 8 characters.<% else %>Leave blank to keep the current password.<% end %>
      </div>
    </div>
    <div>
      <%= f.label :password_confirmation, "Confirm password" %>
      <%= f.password_field :password_confirmation, autocomplete: "new-password",
            required: user.new_record? %>
    </div>
    <div class="check span-2">
      <%= f.check_box :active %>
      <%= f.label :active, "Active (can use the site)" %>
    </div>
  </div>

  <div class="form-actions">
    <%= f.submit class: "btn" %>
    <%= link_to "Cancel", users_path, class: "btn secondary" %>
  </div>
<% end %>
EOF

# ---------- 2. Public home screen ----------
mkdir -p app/views/home
cp "$WEBSITE" app/views/home/index.html.erb

ruby <<'RUBY'
path = "app/views/home/index.html.erb"
src = File.read(path, encoding: "UTF-8")

# [pattern, replacement, description]
patches = [
  [%r{<title>.*?</title>}m,
   "<title><%= @site.site_name %> | AI &amp; Cloud Training</title>", "page title"],
  [/--primary:\s*#\h{6};/,
   "--primary: <%= @site.primary_color %>;", "brand colour"],
  [%r{<p class="copy">.*?</p>}m,
   '<p class="copy">© <span id="year"></span> <%= @site.site_name %>. ' \
   '<%= @site.footer_text.presence || "All rights reserved." %> · ' \
   '<%= link_to "Admin login", new_admin_session_path %></p>', "footer line"]
]

patches.each do |pattern, replacement, what|
  abort "Could not find the #{what} in index.html" unless src.match?(pattern)
  src = src.sub(pattern) { replacement }
end
File.write(path, src, encoding: "UTF-8")
RUBY

cat > app/views/home/maintenance.html.erb <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><%= @site.site_name %> | Back soon</title>
  <style>
    body { margin: 0; min-height: 100vh; display: grid; place-items: center; text-align: center; padding: 1rem;
           font-family: system-ui, sans-serif; color: #e8ecf8;
           background: linear-gradient(135deg, #0b1020, #1a1033 60%, #24135a); }
    h1 { font-size: clamp(1.8rem, 6vw, 3rem); margin-bottom: .5rem; }
    p { color: #9aa6c7; }
    a { color: #22d3ee; }
  </style>
</head>
<body>
  <div>
    <h1>We’ll be back soon 🛠️</h1>
    <p><%= @site.site_name %> is undergoing scheduled maintenance.</p>
    <% if @site.contact_email.present? %>
      <p>Questions? <a href="mailto:<%= @site.contact_email %>"><%= @site.contact_email %></a></p>
    <% end %>
  </div>
</body>
</html>
EOF

cat > app/controllers/home_controller.rb <<'EOF'
# Public home screen for visitors (no login needed).
class HomeController < ApplicationController
  layout false

  def index
    @site = SiteSetting.instance
    render :maintenance, status: :service_unavailable if @site.maintenance_mode
  end
end
EOF

# ---------- 3. Routes: "/" is the website, "/admin" is the dashboard ----------
cat > config/routes.rb <<'EOF'
Rails.application.routes.draw do
  devise_for :admins

  get "admin", to: "dashboard#index", as: :admin_root

  resources :users, except: :show
  resources :products, except: :show
  resource  :site_setting, only: %i[edit update]

  root "home#index"
end
EOF

# ---------- 4. Admins land on the dashboard after signing in ----------
cat > app/controllers/application_controller.rb <<'EOF'
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
EOF

ruby <<'RUBY'
path = "app/views/layouts/admin.html.erb"
src = File.read(path, encoding: "UTF-8")
dash = /link_to "Dashboard",\s+root_path/
abort "Could not update the admin layout" unless src.match?(dash) && src.include?("</nav>")
src = src.sub(dash) { 'link_to "Dashboard", admin_root_path' }
src = src.sub("</nav>") { '<%= link_to "View site ↗", root_path, target: "_blank", rel: "noopener" %>' + "\n        </nav>" }
File.write(path, src, encoding: "UTF-8")
RUBY

echo ""
echo "Done! Restart your server:"
echo "  ADMIN_INVITE_CODE=choose-a-secret rails server"
echo ""
echo "  Home screen (public website):  http://localhost:3000"
echo "  Admin login:                   http://localhost:3000/admins/sign_in"
echo "  Admin dashboard:               http://localhost:3000/admin"
echo "  Users (now with passwords):    http://localhost:3000/users"
