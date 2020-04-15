config = Rails.configuration.councils[ENV['COUNCIL'] || :demo]
Passwordless.default_from_address =  config[:default_from_address]
Passwordless.restrict_token_reuse = false # Tokens can be reused until the magic link times out (timeout_at)
Passwordless.expires_at = lambda { 1.day.from_now } # How long until a passwordless session expires.
Passwordless.timeout_at = lambda { 1.hour.from_now } # How long until a magic link expires.
