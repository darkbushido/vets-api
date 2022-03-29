# frozen_string_literal: true

require 'claims_api/common/exceptions/token_validation_error'

module ClaimsApi
  module Error
    module ErrorHandler
      def self.included(clazz)
        clazz.class_eval do
          # rescue_from ::Common::Exceptions::TokenValidationError, with: :token_validation_error
          rescue_from ::Common::Exceptions::TokenValidationError, with: lambda {
                                                                          render_error(ClaimsApi::Error::TokenValidationError.new)
                                                                        }
        end
      end

      private

      def render_error(error)
        render json: { errors: error.errors }, status: error.status_code
      end

      # def token_validation_error
      #   err = ClaimsApi::Error::TokenValidationError.new
      #   render_error(err)
      # end
    end
  end
end
