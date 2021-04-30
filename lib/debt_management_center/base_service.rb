# frozen_string_literal: true

require 'common/client/base'

module DebtManagementCenter
  class BaseService < Common::Client::Base
    include Common::Client::Concerns::Monitoring

    def initialize(user)
      @user = user
      @file_number = init_file_number
    end

    private

    def init_file_number
      BGS::PeopleService.new(@user).find_person_by_participant_id[:file_nbr].presence || @user.ssn
    rescue Savon::SOAPFault
      @user.ssn
    end

    def with_monitoring_and_error_handling
      with_monitoring(2) do
        yield
      end
    rescue => e
      handle_error(e)
    end

    def save_error_details(error)
      Raven.tags_context(
        external_service: self.class.to_s.underscore
      )

      Raven.extra_context(
        url: config.base_path,
        message: error.message,
        body: error.body
      )
    end

    def handle_error(error)
      case error
      when Common::Client::Errors::ClientError
        handle_client_error(error)
      else
        raise error
      end
    end

    def handle_client_error(error)
      save_error_details(error)

      raise_backend_exception(
        "DMC#{error&.status}",
        self.class,
        error
      )
    end
  end
end
