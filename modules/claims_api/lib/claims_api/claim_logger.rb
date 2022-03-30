# frozen_string_literal: true

module ClaimsApi
  # Logger for ClaimsApi, mostly used to format a print statement
  # Uses the standard Rails logger
  #
  #   ClaimsApi::Logger.log('526ez', claim_id: 'id_here')
  #   # => "ClaimsApi :: 526ez :: Claim ID: id_here"
  class Logger
    LEVELS = %i[debug info warn error fatal unknown].freeze

    def self.log(tag, **params)
      level = pick_level(**params)
      params.delete(:level)
      msg = format_msg(tag, **params)

      Rails.logger.send(level, msg)
      msg
    end

    def self.pick_level(**params)
      params.key?(:level) && params[:level].to_sym.in?(LEVELS) ? params[:level].to_sym : :info
    end

    def self.format_msg(tag, **params)
      msg = ['ClaimsApi', tag]
      case tag
      when '526ez'
        msg.append("Claim ID: #{params[:claim_id]}") if params[:claim_id].present?
        msg.append("VMBS ID: #{params[:vbms_id]}") if params[:vbms_id].present?
        msg.append("autoCrestPDFGenerationDisabled: #{params[:pdf_gen_dis]}") || false
        msg.append("Attachment ID: #{params[:attachment_id]}") if params[:attachment_id].present?
      when 'poa'
        msg.append("PoA ID: #{params[:poa_id]}") if params[:poa_id].present?
        msg.append("Status: #{params[:status]}") if params[:status].present?
        msg.append("Error Code: #{params[:error]}") if params[:error].present?
      when 'itf'
        msg.append("ITF: #{params[:status]}") if params[:status].present?
      else
        msg.append(params.to_json)
      end
      msg.join(' :: ')
    end
  end
end

# Uncomment to allow a global (to claims_api) claims_log() method
# def claims_log(*tags, **params)
#   ClaimsApi::Logger.log(*tags, **params)
# end
