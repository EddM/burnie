module RedditKit
  class Client
    module Subreddits
      def subreddit_attributes(subreddit_name)
        if attributes = get("r/#{subreddit_name}/about/edit.json?raw_json=1")
          attributes.body[:data]
        end
      end

      def update_subreddit(subreddit_name, parameters = {})
        @modhash = user.attributes[:modhash]
        attributes = subreddit_attributes(subreddit_name)

        params = attributes.merge(
          type: attributes[:subreddit_type],
          link_type: attributes[:content_options],
          lang: attributes[:language],
          allow_top: true,
          "header-title" => attributes[:header_hover_text],
          sr: attributes[:subreddit_id],
          uh: @modhash,
          api_type: 'json'
        )

        post('api/site_admin.json', params.merge(parameters))
      end
    end
  end
end
