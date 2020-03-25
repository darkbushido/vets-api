# frozen_string_literal: true

require 'rails_helper'

describe EVSSPolicy do
  subject { described_class }

  permissions :access? do
    context 'with a user who has the required evss attributes' do
      let(:user) { build(:user, :loa3) }

      it 'grants access' do
        expect(subject).to permit(user, :evss)
      end

      it 'increments the StatsD success counter' do
        expect { EVSSPolicy.new(user, :evss).access? }.to trigger_statsd_increment('api.evss.policy.success')
      end
    end

    context 'with a user who does not have the required evss attributes' do
      let(:user) { build(:unauthorized_evss_user, :loa3) }

      it 'denies access' do
        expect(subject).not_to permit(user, :evss)
      end

      it 'increments the StatsD failure counter' do
        expect { EVSSPolicy.new(user, :evss).access? }.to trigger_statsd_increment('api.evss.policy.failure')
      end
    end
  end

  permissions :access_form526? do
    context 'with a user who has the required form526 attributes' do
      let(:user) { build(:user, :loa3) }

      it 'grants access' do
        expect(subject).to permit(user, :evss)
      end

      it 'increments the StatsD success counter' do
        expect { EVSSPolicy.new(user, :evss).access_form526? }.to trigger_statsd_increment('api.evss.policy.success')
      end
    end

    context 'with a user who does not have the required form526 attributes' do
      let(:user) { build(:unauthorized_evss_user, :loa3) }

      it 'denies access' do
        expect(subject).not_to permit(user, :evss)
      end

      it 'increments the StatsD failure counter' do
        expect { EVSSPolicy.new(user, :evss).access_form526? }.to trigger_statsd_increment('api.evss.policy.failure')
      end
    end
  end

  permissions :access_original_claims? do
    context 'with a user who is missing birls and participant id' do
      let(:user) { build(:user_with_no_ids) }

      it 'grants access' do
        expect(subject).to permit(user, :evss)
      end

      it 'increments the StatsD success counter' do
        expect { EVSSPolicy.new(user, :evss).access_original_claims? }.to trigger_statsd_increment(
          'api.evss.policy.success'
        )
      end
    end

    context 'with a user who is missing only one id' do
      let(:user) { build(:user_with_no_birls_id) }

      it 'grants access' do
        expect(subject).to permit(user, :evss)
      end

      it 'increments the StatsD success counter' do
        expect { EVSSPolicy.new(user, :evss).access_original_claims? }.to trigger_statsd_increment(
          'api.evss.policy.success'
        )
      end
    end

    context 'with a user who does not have the required original claims attributes' do
      let(:user) { build(:unauthorized_evss_user, :loa3) }

      it 'denies access' do
        expect(subject).not_to permit(user, :evss)
      end

      it 'increments the StatsD failure counter' do
        expect { EVSSPolicy.new(user, :evss).access_original_claims? }.to trigger_statsd_increment(
          'api.evss.policy.failure'
        )
      end
    end

    context 'with a user who already has the birls and particiapnt id' do
      let(:user) { build(:user, :loa3) }

      it 'denies access' do
        expect(subject).not_to permit(user, :evss)
      end

      it 'increments the StatsD failure counter' do
        expect { EVSSPolicy.new(user, :evss).access_original_claims? }.to trigger_statsd_increment(
          'api.evss.policy.failure'
        )
      end
    end
  end
end
