class PatronController < ApplicationController
  before_action :protect

  def patron_info
    patron_id = sanitize(params[:patron_id])
    data = VoyagerHelpers::Liberator.get_patron_info(patron_id)    
    if data.blank?
      render json: {}, status: 404
    else
      data[:campus_authorized] = CampusAccess.has_access?(patron_id)
      if params[:ldap].present? && sanitize(params[:ldap])=="true"
        data[:ldap] = Ldap.find_by_netid(patron_id)
      end
      respond_to do |wants|
        wants.json  { render json: MultiJson.dump(data) }
      end
    end
  end

  def patron_codes
    data = VoyagerHelpers::Liberator.get_patron_stat_codes(sanitize(params[:patron_id]))
    if data.blank?
      render json: {}, status: 404
    else
      respond_to do |wants|
        wants.json  { render json: MultiJson.dump(data) }
      end
    end
  end

  private
  def protect
    unless user_signed_in?
      ips = Rails.application.config.ip_allowlist
      render plain: "You are unauthorized", status: 403 if not ips.include? request.remote_ip
    end
  end
end
