# frozen_string_literal: true

require 'rails_helper'

describe Form1095Policy do
  subject { described_class }

    permissions :access? do
        context 'with a user who has the required 1095-B attributes' do
            let(:user) { build(:user, :loa3, icn: "12345678654332534") }

            it 'grants access' do
                expect(subject).to permit(user, :form1095)
            end
        end
        

        context 'with a user who is not LOA3 verified' do
            let(:user) { build(:user, :loa1, icn: "45678654356789876") }

            it 'denies access' do
                expect(subject).not_to permit(user, :form1095)
            end
        end

        # can't have user who is loa3 without ICN
        # context 'with a user who does not have an ICN' do
        #     let(:user) { build(:user, :loa3, icn: nil) }
    
        #     puts "tetst user without icn"

        #     it 'denies access' do
        #         puts "test user without icn"
        #         user.identity.icn = nil
        #         # user&.mpi&.icn = nil
        #         puts user.icn || "nil"
        #         expect(subject).not_to permit(user, :form1095)
        #     end
        # end

        context 'with a user who does not have an ICN' do
            let(:user) { build(:user, :loa1, icn: nil) }
    
            it 'denies access' do
                expect(subject).not_to permit(user, :form1095)
            end
        end
    end
end
