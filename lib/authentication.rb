# frozen_string_literal: true

class Authentication
  REDIRECT_URI = "https://www.edd.xxx"

  SCOPES = "identity,edit,flair,history,modconfig,modflair,modlog,modposts,modwiki,mysubreddits," \
           "privatemessages,read,report,save,subscribe,vote,wikiedit,wikiread,submit"

  def initialize(client)
    @client = client
  end

  def authenticate
    puts "Go to this URL:"
    puts authentication_url
    puts
    puts "Enter the code from the URL you were redirected to:"
    one_time_code = $stdin.gets.chomp
    access_token_url = "https://www.reddit.com/api/v1/access_token"

    options = {
      grant_type: "authorization_code",
      code: one_time_code,
      redirect_uri: REDIRECT_URI,
    }

    request = HTTParty.post(
      access_token_url,
      body: options,
      headers: { "Authorization" => auth_header },
    )

    data = JSON.parse(request.response.body)
    refresh_token = data["refresh_token"]
    File.write(".refresh_token", refresh_token, mode: "w")
  end

  private

  attr_reader :client

  def authentication_url
    "https://www.reddit.com/api/v1/authorize.compact?client_id=#{CGI.escape(client.client_id)}&response_type=code&" \
    "state=#{SecureRandom.hex(8)}&redirect_uri=#{CGI.escape(REDIRECT_URI)}&duration=permanent&" \
    "scope=#{CGI.escape(SCOPES)}"
  end

  def auth_header
    auth = Base64.strict_encode64("#{client.client_id}:#{client.secret}")
    "Basic #{auth}"
  end
end
