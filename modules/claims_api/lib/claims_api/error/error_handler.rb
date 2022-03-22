module ClaimsApi
  module Error
    module ErrorHandler
      def self.included(clazz)
        clazz.class_eval do
          rescue_from ::Common::Exceptions::TokenValidationError, with: :token_validation_error
        end
      end

      private
      def token_validation_error
        json = {
          errors: [
            {
              title: "Token Validation Error",
              detail: "Invalid token.",
              code: "401",
              status: "401"
            }
          ]
        }
        render json: json, status: 401
      end
    end
  end
end