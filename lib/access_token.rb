# frozen_string_literal: true

class AccessToken
  def initialize(client)
    @client = client
  end

  def refresh
    request = HTTParty.post(
      "https://www.reddit.com/api/v1/access_token",
      body: {
        grant_type: "refresh_token",
        refresh_token: client.refresh_token,
      },
      headers: { "Authorization" => auth_header },
    )

    data = JSON.parse(request.response.body)
    data["access_token"]
  end

  private

  attr_reader :client

  def auth_header
    auth = Base64.strict_encode64("#{client.client_id}:#{client.secret}")
    "Basic #{auth}"
  end
end
