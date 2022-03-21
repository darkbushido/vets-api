# frozen_string_literal: true

require 'common/client/configuration/rest'
require 'common/client/middleware/logging'

module MhvInheritedProofing::Mhv
  class Configuration < Common::Client::Configuration::REST
    def valid_id_url
      Settings.mhv.inherited_proofing.valid_id_url
    end

    def vacct_info_url
      Settings.mhv.inherited_proofing.vacct_info_url
    end

    def app_token
      Settings.mhv.rx.app_token
    end
  end
end
