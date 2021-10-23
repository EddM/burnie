# frozen_string_literal: true

require "active_support/core_ext/hash/indifferent_access"

class Subreddit
  def initialize(client, subreddit)
    @client = client
    @subreddit = subreddit
  end

  def update(description:)
    sub_attributes = attributes

    sub_attributes = sub_attributes.merge(
      type: sub_attributes[:subreddit_type],
      link_type: sub_attributes[:content_options],
      lang: sub_attributes[:language],
      allow_top: true,
      "header-title" => sub_attributes[:header_hover_text],
      sr: sub_attributes[:subreddit_id],
      api_type: "json",
    )

    client.post(
      "api/site_admin.json",
      **sub_attributes.merge(description: description),
    )
  end

  def attributes
    attributes = client.get("r/#{subreddit}/about/edit.json?raw_json=1")
    return if attributes.nil?

    attributes.with_indifferent_access[:data]
  end

  def self.update(client, subreddit, description:)
    subreddit = new(client, subreddit)
    subreddit.update(description: description)
  end

  private

  attr_reader :client, :subreddit
end
