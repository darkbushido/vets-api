# frozen_string_literal: true

module SignIn::SharedServiceBehavior
  def token(code)
    response = perform(
      :post, config.token_path, token_params(code), { 'Content-Type' => 'application/json' }
    )
    response.body
  rescue Common::Client::Errors::ClientError => e
    raise e
  end

  def user_info(token)
    response = perform(:get, config.userinfo_path, nil, { 'Authorization' => "Bearer #{token}" })
    response.body
  rescue Common::Client::Errors::ClientError => e
    raise e
  end

  private

  def add_query(url, params)
    if params.any?
      uri = URI.parse(url)
      uri.query = Rack::Utils.parse_nested_query(uri.query).merge(params).to_query
      uri.to_s
    else
      url
    end
  end

  def auth_url
    "#{config.base_path}/#{config.auth_path}"
  end

  def token_url
    "#{config.base_path}/#{config.token_path}"
  end

  def token_params(code)
    {
      grant_type: config.grant_type,
      code: code,
      client_assertion_type: config.client_assertion_type,
      client_assertion: client_assertion_jwt
    }.to_json
  end

  def client_assertion_jwt
    jwt_payload = {
      iss: config.client_id,
      sub: config.client_id,
      aud: token_url,
      jti: SecureRandom.hex,
      nonce: nonce,
      exp: Time.now.to_i + config.client_assertion_expiration_seconds
    }
    JWT.encode(jwt_payload, config.ssl_key, 'RS256')
  end

  def state
    @state ||= SecureRandom.hex
  end

  def nonce
    @nonce ||= SecureRandom.hex
  end
end
