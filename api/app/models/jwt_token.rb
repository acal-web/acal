require "jwt"

class JwtToken
  ALGORITHM = "HS256"
  EXPIRATION_TIME = 30.days

  class << self
    def encode(id, key: :user_id, expires_at: EXPIRATION_TIME.from_now)
      payload = {
        key => id,
        exp: expires_at.to_i,
        iat: Time.current.to_i
      }

      JWT.encode(payload, secret_key, ALGORITHM)
    end

    def decode(token)
      return nil if token.blank?

      begin
        decoded = JWT.decode(token, secret_key, true, algorithm: ALGORITHM)
        decoded.first.symbolize_keys
      rescue JWT::DecodeError, JWT::ExpiredSignature, StandardError
        nil
      end
    end

    def valid?(token)
      decode(token).present?
    end

    private

    def secret_key
      Rails.application.credentials.dig(:jwt_secret) || "default-insecure-key-change-in-production"
    end
  end
end
