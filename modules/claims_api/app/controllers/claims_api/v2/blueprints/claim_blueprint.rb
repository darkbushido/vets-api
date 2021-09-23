# frozen_string_literal: true

module ClaimsApi
  module V2
    module Blueprints
      class ClaimBlueprint < Blueprinter::Base
        identifier :id
        field :type
        field :status
        field :end_product_code

        field :@links do |claim, options|
          {
            rel: 'self',
            type: 'GET',
            url: "#{options[:base_url]}/services/benefits/v2/veterans/#{options[:veteran_id]}/claims/#{claim[:id]}"
          }
        end

        view :list do
          exclude :end_product_code
        end

        transform ClaimsApi::V2::Blueprints::Transformers::LowerCamelTransformer
      end
    end
  end
end
