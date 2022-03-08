module V0
  class Form1095BsController < ApplicationController

    # todo:  find what access is needed...
    # maybe create a form1095_policy?
    # skip_before_action :authenticate # for testing
    before_action { authorize :form1095, :access?}
    

    def download
      # render json: { error: "No 1095-B form exists for year #{download_params[:tax_year]}"} unless @current_user.present?
      puts "downloading...................................................................................................."
      puts download_params

      # form = Form1095B.find_by_icn_and_year(@current_user[:icn], download_params[:tax_year])
      form = Form1095B.first
      puts form
      
      raise Common::Exceptions::RecordNotFound, download_params unless form.present?
      # return render json: {errors: [{title: "Record not found", detail: "Form 1096-B not found for year #{download_params}", code: "404", status: "404"}]}

      render json: form.gen_pdf

      # file_name = "1095B_#{download_params}.pdf"
      # send_data form.gen_pdf, filename: file_name, type: "application/pdf", disposition: "attachment"
    end

    private

    def download_params
      params.require(:tax_year) # icn should come from current user
    end
  end
end