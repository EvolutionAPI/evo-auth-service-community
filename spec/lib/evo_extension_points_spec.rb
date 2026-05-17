# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EvoExtensionPoints do
  after { EvoExtensionPoints.reset! } # rubocop:disable RSpec/DescribedClass

  describe '.replace' do
    it 'rejects unknown extension point keys' do
      expect { described_class.replace(:not_a_thing) { :noop } }
        .to raise_error(described_class::UnknownExtensionPoint)
    end

    it 'requires a block' do
      expect { described_class.replace(:token_claims) }.to raise_error(ArgumentError)
    end
  end

  describe EvoExtensionPoints::AuthBridge do
    it 'returns nil for current_user in the community default' do
      expect(described_class.current_user).to be_nil
    end

    it 'returns the same user from sign_in_user as a no-op default' do
      user = Object.new
      expect(described_class.sign_in_user(user)).to equal(user)
    end

    it 'returns the same user from sign_out as a no-op default' do
      user = Object.new
      expect(described_class.sign_out(user)).to equal(user)
    end

    it 'honors a replace override on current_user' do
      sentinel = Object.new
      EvoExtensionPoints.replace(:auth_bridge_current_user) { sentinel }
      expect(described_class.current_user).to equal(sentinel)
    end

    it 'honors a replace override on create_user' do
      EvoExtensionPoints.replace(:auth_bridge_create_user) do |email:, password:, attrs: {}|
        { email: email, password: password, attrs: attrs }
      end
      result = described_class.create_user(email: 'a@b.test', password: 'pw', attrs: { role: 'agent' })
      expect(result).to eq(email: 'a@b.test', password: 'pw', attrs: { role: 'agent' })
    end

    it 'honors a replace override on sign_in_user' do
      seen = []
      EvoExtensionPoints.replace(:auth_bridge_sign_in_user) { |user| seen << user }
      described_class.sign_in_user(:user_42)
      expect(seen).to eq([:user_42])
    end

    it 'honors a replace override on sign_out' do
      seen = []
      EvoExtensionPoints.replace(:auth_bridge_sign_out) { |user| seen << user }
      described_class.sign_out(:user_42)
      expect(seen).to eq([:user_42])
    end
  end

  describe EvoExtensionPoints::TokenClaims do
    it 'returns an empty hash by default' do
      expect(described_class.claims_for(Object.new)).to eq({})
    end

    it 'honors a replace override' do
      EvoExtensionPoints.replace(:token_claims) do |user|
        { 'audience' => 'my_consumer', 'user_object' => user }
      end
      user = Object.new
      result = described_class.claims_for(user)
      expect(result).to eq('audience' => 'my_consumer', 'user_object' => user)
    end
  end

  describe EvoExtensionPoints::LoginGate do
    it 'returns :allow by default' do
      expect(described_class.check(Object.new)).to eq(:allow)
    end

    it 'forwards context kwargs to the default impl' do
      expect(described_class.check(Object.new, ip: '127.0.0.1', user_agent: 'rspec')).to eq(:allow)
    end

    it 'honors a replace override returning a denial reason' do
      EvoExtensionPoints.replace(:login_gate) do |_user, **context|
        context[:blocked] ? [:deny, :blocked_by_consumer] : :allow
      end
      expect(described_class.check(Object.new)).to eq(:allow)
      expect(described_class.check(Object.new, blocked: true)).to eq([:deny, :blocked_by_consumer])
    end
  end
end
