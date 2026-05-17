# frozen_string_literal: true

module EvoExtensionPoints
  # TokenClaims extension point. Community default returns an empty hash;
  # the auth-service emits no extra claims beyond what devise_token_auth
  # already produces. A consumer overrides via
  # EvoExtensionPoints.replace(:token_claims) { |user| { ... } }.
  # See EXTENSION_POINTS.md at the repository root.
  module TokenClaims
    DEFAULT_IMPL = ->(_user) { {} }

    class << self
      def claims_for(user)
        impl = EvoExtensionPoints.impl_for(:token_claims) || DEFAULT_IMPL
        impl.call(user)
      end
    end
  end
end
