# frozen_string_literal: true

module EvoExtensionPoints
  # AuthBridge extension point. Community defaults are intentionally
  # minimal: create_user delegates to the public User model, sign_in_user
  # / sign_out / current_user are no-op returns. A consumer overrides any
  # of the four sub-keys via EvoExtensionPoints.replace(:auth_bridge_*).
  # See EXTENSION_POINTS.md at the repository root.
  module AuthBridge
    DEFAULT_CREATE_USER = lambda do |email:, password:, attrs: {}|
      User.create!(email: email, password: password, **attrs)
    end
    DEFAULT_SIGN_IN_USER = ->(user) { user }
    DEFAULT_CURRENT_USER = -> {}
    DEFAULT_SIGN_OUT = ->(user) { user }

    class << self
      def create_user(email:, password:, attrs: {})
        impl = EvoExtensionPoints.impl_for(:auth_bridge_create_user) || DEFAULT_CREATE_USER
        impl.call(email: email, password: password, attrs: attrs)
      end

      def sign_in_user(user)
        impl = EvoExtensionPoints.impl_for(:auth_bridge_sign_in_user) || DEFAULT_SIGN_IN_USER
        impl.call(user)
      end

      def current_user
        impl = EvoExtensionPoints.impl_for(:auth_bridge_current_user) || DEFAULT_CURRENT_USER
        impl.call
      end

      def sign_out(user)
        impl = EvoExtensionPoints.impl_for(:auth_bridge_sign_out) || DEFAULT_SIGN_OUT
        impl.call(user)
      end
    end
  end
end
