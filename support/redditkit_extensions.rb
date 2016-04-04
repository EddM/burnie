module RedditKit
  class Client
    module Subreddits
      def subreddit_attributes(subreddit_name)
        if attributes = get("r/#{subreddit_name}/about/edit.json")
          attributes.body[:data]
        end
      end

      def update_subreddit(subreddit_name, parameters = {})
        @modhash = user.attributes[:modhash]
        attributes = subreddit_attributes(subreddit_name)

        params = {
          type: attributes[:subreddit_type], link_type: attributes[:content_options],
          lang: attributes[:language], allow_top: true, show_media: attributes[:show_media], over_18: attributes[:over_18],
          sr: attributes[:subreddit_id], uh: @modhash, api_type: 'json',
          title: attributes[:title], description: attributes[:description],
          public_description: attributes[:public_description], wikimode: attributes[:wikimode],
          key_color: attributes[:key_color], show_media_preview: true
        }

        post('api/site_admin.json', params.merge(parameters))
      end
    end
  end
end
