module ClaimsApi
  module V2
    module Forms
      class DisabilityCompensation < ClaimsApi::V2::Base
        version 'v2'
        
        resource '526' do
          desc 'Submit claim.'
          post '/' do
            raise 'NotImplemented'
          end
        end
      end
    end
  end
end
