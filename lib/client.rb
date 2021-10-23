# frozen_string_literal: true

require "httparty"

class Client
  USER_AGENT = "BurnieBot/2.0 by BLITZCRUNK123"

  attr_reader :refresh_token

  def initialize
    read_refresh_token
  end

  def authenticate
    authentication = Authentication.new(self)
    authentication.authenticate
    read_refresh_token
  end

  def client_id
    Configuration["client_id"]
  end

  def secret
    Configuration["secret"]
  end

  def post(path, **params)
    HTTParty.post(
      "https://oauth.reddit.com/#{path}",
      headers: headers,
      body: params,
    )
  end

  def get(path)
    HTTParty.get("https://oauth.reddit.com/#{path}", headers: headers)
  end

  # extension arg is just for compatibility with RedditKit
  def submit(title, subreddit, text:, flair_text:, extension: nil)
    Post.create(self, "[Game Thread] #{title}", subreddit, text: text, flair_text: flair_text)
  end

  def update_subreddit(subreddit, description:)
    Subreddit.update(self, subreddit, description: description)
  end

  private

  def headers
    {
      "User-Agent" => USER_AGENT,
      "Authorization" => auth_header,
    }
  end

  def auth_header
    "Bearer #{access_token}"
  end

  def access_token
    AccessToken.new(self).refresh
  end

  def read_refresh_token
    @refresh_token = File.read(".refresh_token")
  end
end
