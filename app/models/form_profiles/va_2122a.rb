# frozen_string_literal: true

class FormProfiles::VA2122a < FormProfile
  def metadata
    {
      version: 0,
      prefill: true,
      returnUrl: '/service-file-information'
    }
  end
end
