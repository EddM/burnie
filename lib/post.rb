# frozen_string_literal: true

class Post
  SELF = "self"

  def initialize(client, title, subreddit, text:, flair_text:)
    @client = client
    @title = title
    @subreddit = subreddit
    @text = text
    @flair_text = flair_text
  end

  def save
    client.post(
      "api/submit",
      title: title,
      sr: subreddit,
      text: text,
      kind: SELF,
    )
  end

  def self.create(*args)
    new(*args).save
  end

  attr_reader :client, :title, :subreddit, :text, :flair_text
end
