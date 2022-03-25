# frozen_string_literal: true

require 'inherited_proofing/mhv/service'
require 'inherited_proofing/logingov/service'

class InheritedProofingController < ApplicationController
  def auth
    load_user
    return unless @current_user

    mhv_data = mhv_inherited_proofing_service(@current_user).identity_proof_data
    return unless mhv_data['code'].exists?
    store_mhv_data(mhv_data)
    render body: logingov_inherited_proofing_service.render_auth(auth_code: mhv_data[:code]),
           content_type: 'text/html'
  rescue => e
    render json: { errors: e }, status: :bad_request
  end

  private

  def store_mhv_data(data)
    inherited_proofing_mhv_data = InheritedProofing::MHVIdentityData.new(
      code: data[:code],
      user_uuid: @current_user.uuid,
      data: data
    )
    inherited_proofing_mhv_data.save! if inherited_proofing_mhv_data.valid?
  end

  def mhv_inherited_proofing_service(user = nil)
    @mhv_inherited_proofing_service ||= InheritedProofing::MHV::Service.new(user)
  end

  def logingov_inherited_proofing_service
    @logingov_inherited_proofing_service ||= InheritedProofing::Logingov::Service.new
  end
end
