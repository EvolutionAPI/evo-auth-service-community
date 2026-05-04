# Environment Configuration for EvoAuth Service
# Basic configurations needed for the app to work

Rails.application.configure do
  # Basic app configuration
  Rails.application.config.app_name = 'Evo Auth Service'
  auth_service_url = ENV.fetch('AUTH_SERVICE_URL', 'http://localhost:3001')
  Rails.application.config.app_url = auth_service_url

  # Configure routes URL options so url_for in models generates absolute URLs
  begin
    parsed = URI.parse(auth_service_url)
    Rails.application.routes.default_url_options = {
      host: parsed.host,
      port: parsed.port,
      protocol: parsed.scheme
    }
  rescue URI::InvalidURIError => e
    Rails.logger.warn "AUTH_SERVICE_URL is not a valid URI: #{e.message}"
  end

  Rails.application.config.enable_account_signup = true

  # MFA configuration with defaults
  Rails.application.config.mfa_config = {
    issuer_name: 'Evo Auth Service',
    backup_codes_count: 10,
    email_otp_expires_in: 300,
    totp_drift_behind: 30,
    totp_drift_ahead: 30
  }

  Rails.logger.info "🔧 EvoAuth: Basic environment configuration loaded"
end
