# frozen_string_literal: true

# Public extension contract of evo-auth-service-community. See
# EXTENSION_POINTS.md at the repository root for the full contract.
# The three sub-modules under this namespace ship no-op defaults; an
# external consumer overrides a specific extension point at process
# start via EvoExtensionPoints.replace(:name, &block).
#
# Sub-modules are autoloaded by Zeitwerk under lib/evo_extension_points/.
module EvoExtensionPoints
  KNOWN_KEYS = %i[
    auth_bridge_create_user
    auth_bridge_sign_in_user
    auth_bridge_current_user
    auth_bridge_sign_out
    token_claims
    login_gate
  ].freeze

  class UnknownExtensionPoint < ArgumentError; end

  class << self
    def replace(key, &block)
      raise ArgumentError, 'block required' unless block
      raise UnknownExtensionPoint, "unknown extension point: #{key.inspect}" unless KNOWN_KEYS.include?(key)

      overrides[key] = block
      block
    end

    def impl_for(key)
      overrides[key]
    end

    def reset!
      @overrides = nil
    end

    private

    def overrides
      @overrides ||= {}
    end
  end
end
