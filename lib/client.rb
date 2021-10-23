# frozen_string_literal: true

class Client
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
      headers: {
        "User-Agent" => "BurnieBot/2.0 by BLITZCRUNK123",
        "Authorization" => "Bearer #{access_token}",
      },
      body: params,
    )
  end

  # extension arg is just for compatibility with RedditKit
  def submit(title, subreddit, text:, flair_text:, extension: nil)
    Post.create(self, "[Game Thread] #{title}", subreddit, text: text, flair_text: flair_text)
  end

  private

  def access_token
    AccessToken.new(self).refresh
  end

  def read_refresh_token
    @refresh_token = File.read(".refresh_token")
  end
end
