# frozen_string_literal: true

class FormProfiles::VA2122a < FormProfile
  def metadata
    {
      version: 0,
      prefill: true,
      returnUrl: 'view-change-representative/search/representative-type'
    }
  end
end
