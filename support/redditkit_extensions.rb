module RedditKit
  class Client

    module Subreddits

      def update_subreddit(subreddit_name, parameters = {})
        @modhash = user.attributes[:modhash]

        attributes = get("r/#{subreddit_name}/about/edit.json").body[:data]

        params = {
          type: 'public', link_type: 'any',
          lang: 'en', allow_top: true, show_media: attributes[:show_media], over_18: attributes[:over_18],
          sr: attributes[:subreddit_id], uh: @modhash, api_type: 'json',
          title: attributes[:title], description: attributes[:description],
          public_description: attributes[:public_description], wikimode: attributes[:wikimode]
        }

        post('api/site_admin.json', params.merge(parameters))
      end

    end

  end
end
