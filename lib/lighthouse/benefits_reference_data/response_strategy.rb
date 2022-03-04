# frozen_string_literal: true

require 'common/models/redis_store'
require 'common/models/concerns/cache_aside'

module Lighthouse
  module BenefitsReferenceData
    class ResponseStrategy < Common::RedisStore
      include Common::CacheAside

      redis_config_key :reference_data_response

      def cache_by_user_and_type(user_uuid, type, &block)
        do_cached_with(key: "#{user_uuid}:#{type}", &block)
      end
    end
  end
end
