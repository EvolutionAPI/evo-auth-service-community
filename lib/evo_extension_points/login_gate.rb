# frozen_string_literal: true

module EvoExtensionPoints
  # LoginGate extension point. Community default returns :allow; the
  # auth-service performs no pre-login check beyond what Devise already
  # enforces. A consumer overrides via
  # EvoExtensionPoints.replace(:login_gate) { |user, **context| ... }.
  # See EXTENSION_POINTS.md at the repository root.
  module LoginGate
    DEFAULT_IMPL = ->(_user, **_context) { :allow }

    class << self
      def check(user, **context)
        impl = EvoExtensionPoints.impl_for(:login_gate) || DEFAULT_IMPL
        impl.call(user, **context)
      end
    end
  end
end
