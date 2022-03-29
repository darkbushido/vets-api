# frozen_string_literal: true

require 'inherited_proofing/mhv/inherited_proofing/verifier'
require 'inherited_proofing/logingov/service'

class InheritedProofingController < ApplicationController
  def auth
    load_user
    return unless @current_user

    inherited_proofing_verifier = InheritedProofing::MHV::InheritedProofingVerifier.new(@current_user)
    auth_code = inherited_proofing_verifier.perform
    return unless auth_code.exists?

    render body: logingov_inherited_proofing_service.render_auth(auth_code: auth_code),
           content_type: 'text/html'
  rescue => e
    render json: { errors: e }, status: :bad_request
  end

  private

  def logingov_inherited_proofing_service
    @logingov_inherited_proofing_service ||= InheritedProofing::Logingov::Service.new
  end
end
