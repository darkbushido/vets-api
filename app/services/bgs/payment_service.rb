# frozen_string_literal: true

module BGS
  class PaymentService < BaseService
    # Retrieves a veterans payment history (payments and return payments)
    # via the bgs-ext gem's payment_information service.
    # https://github.com/department-of-veterans-affairs/bgs-ext/blob/master/lib/bgs/services/payment_information.rb
    #
    # @person an instance of BGS::PeopleService
    #
    # @return Array an array of payments and return payments
    #
    def payment_history(person)
      response = @service.payment_information.retrieve_payment_summary_with_bdn(
        person[:ptcpnt_id],
        person[:file_nbr],
        '00', # payee code
        person[:ssn_nbr]
      )
      return empty_response if response[:payments].nil?

      response
    rescue Savon::Error, BGS::ShareError => e
      # BGS::ShareError is the base error class that the bgs-ext gem will return
      report_error(e)
      raise BGS::ServiceException.new('BGS_PAYMENT_HISTORY_502', { detail: e.message, source: self.class.name })
    rescue => e
      report_error(e)
      return empty_response if e.message.include?('No Data Found')

      raise e
    end

    private

    def empty_response
      { payments: { payment: [] } }
    end
  end
end
