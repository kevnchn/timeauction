class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :configure_permitted_parameters, if: :devise_controller?
  before_filter :set_first_time_sign_in_cookie, if: :first_time_sign_in?

  helper_method :on_production_server?, :can_submit_hours?, :hk_domain?

  def after_sign_in_path_for(resource)
    if referer_match?
      super
    else
      stored_location_for(resource) || request.env['omniauth.origin'] || request.referer || root_path
    end
  end

  def on_production_server?
    Rails.env.production? && !(ENV['TA_ENVIRONMENT'] == "staging")
  end

  def authenticate_admin!
    unless current_user.try(:admin?)
      flash[:alert] = "You are not authorized to access this page."
      redirect_to root_path
    end
  end

  def hk_domain?
    params[:hk] == "yes" || request.host == "timeauction.hk" || request.original_url.include?("timeauction.hk")
  end

  protected

  def set_first_time_sign_in_cookie
    cookies[:first_time_sign_in] = true
  end

  def first_time_sign_in?
    current_user && current_user.sign_in_count == 1 && cookies[:first_time_sign_in].nil?
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) do |u|
      u.permit(:first_name, :last_name, :username, :email, :password, :password_confirmation)
    end

    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit(:first_name, :last_name, :username, :email, :password, :password_confirmation)
    end
  end

  def referer_match?
    return false unless resource
    sign_in_url = new_session_url(resource)
    sign_up_url = new_registration_url(resource)
    if Rails.env.production?
      failed_sign_in_url = "http://" + request.host + "/users"
    else
      failed_sign_in_url = "http://" + request.host + ":" + request.port.to_s + "/users"
    end

    return request.referer == sign_in_url || request.referer == sign_up_url || request.referer == failed_sign_in_url
  end

  def can_submit_hours?
    current_user.premium || current_user.bids.any?
  end
end
