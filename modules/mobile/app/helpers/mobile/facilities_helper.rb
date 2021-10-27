# frozen_string_literal: true

module Mobile
  module FacilitiesHelper
    module_function

    def get_facilities(facility_ids)
      facilities_service.get_facilities(ids: facility_ids.to_a.map { |id| "vha_#{id}" }.join(','))
    end

    def get_facility_names(facility_ids)
      facilities = get_facilities(facility_ids)
      facilities.map(&:name)
    end

    def facilities_service
      Lighthouse::Facilities::Client.new
    end
  end
end
