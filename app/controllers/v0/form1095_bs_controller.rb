# frozen_string_literal: true

module V0
  class Form1095BsController < ApplicationController
    before_action { authorize :form1095, :access? }
    before_action :get_1095b

    def last_updated
      # puts "getting last_updated ts"

      render json: { last_updated: @form.updated_at }
    end
    
    def download
      file_name = "1095B_#{download_params}.pdf"
      send_data @form.get_pdf, filename: file_name, type: 'application/pdf', disposition: 'attachment'
    end

    private

    def get_1095b
      @form = Form1095B.find_by(veteran_icn: @current_user[:icn], tax_year: download_params)

      if @form.blank?
        Rails.logger.error("Form 1095-B for year #{download_params} not found", user_uuid: @current_user&.uuid)
        raise Common::Exceptions::RecordNotFound, download_params
      end
    end

    def download_params
      params.require(:tax_year)
    end
    
  end
  
end