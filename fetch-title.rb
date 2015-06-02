#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'htmlentities'

gem 'google-api-client'
require 'google/api_client'

def get_youtube_service
  client = Google::APIClient.new(
    :key => "PUT_YOUR_YOUTUBE_KEY_HERE",
    :authorization => nil,
    :application_name => "fetch-youtube-title",
    :application_version => '1.0.0'
  )
  youtube = client.discovered_api('youtube', 'v3')
  return client, youtube
end

$google_client, $youtube = get_youtube_service

def fetch_http(uri, limit = 10)
  # You should choose better exception.
  raise ArgumentError, 'HTTP redirect too deep' if limit == 0
  begin
    http = Net::HTTP.new(uri.host, uri.port);
    if(uri.scheme == "https")
      http.use_ssl     = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
  rescue => e
    return nil;
  end

  case response
    when Net::HTTPSuccess
        then response
    when Net::HTTPRedirection,Net::HTTPMovedPermanently
      location = URI.parse(response['location']);
      fetch_http(location, limit - 1)
    else
      response.error!
  end
end

def document_encoding(response)
  encoding = false
  response.type_params.each_pair do |k, v|
    # Check response['content-type'] header
    encoding = v.upcase if k =~ /charset/i
  end
  unless encoding
    # Check <meta> tag
    encoding = response.body =~ /<meta[^>]*HTTP-EQUIV=["']Content-Type["'][^>]*content=["'](.*)["']/i && $1 =~ /charset=(.+)/i && $1.upcase
  end
  return encoding
end

def fetch_youtube_title(id)
   begin
    #puts("Request youtube for id = " + id)
    search_response = $google_client.execute!(
      :api_method => $youtube.videos.list,
      :parameters =>
      {
        :part => 'snippet,contentDetails,statistics',
        :fields => 'items(snippet(title),contentDetails(duration),statistics(viewCount))',
        :id => id
      }
    )
    #puts(search_response.body) # print JSON

    title = nil;
    if (search_response.data.items.length > 0)
      search_result = search_response.data.items[0];

      # Might be a good idea to use: https://github.com/arnau/ISO8601
      duration = search_result.contentDetails.duration
      duration = duration[2..-1].downcase

      title = "#{search_result.snippet.title} [#{duration} - #{search_result.statistics.viewCount} views]";
    end
    return title;

  rescue Google::APIClient::TransmissionError => e
    puts e.result.body
  end
end

def fetchTitles(text)
  word = text.split(" ");

  word.each { |w|
    if(w.start_with?("http://", "https://", "www."))

      if(w.start_with?("www."))
        uri_str = "http://" + w;
      else
        uri_str = w;
      end

      uri  = URI.parse(uri_str);

      if (uri.host.include?("youtube.com"))
        #params = Hash[URI::decode_www_form(uri.query)] # if you are below 2.1 version of Ruby
        params = URI::decode_www_form(uri.query).to_h # if you are in 2.1 or later version of Ruby
        id = params["v"]
        title = fetch_youtube_title(id);
        if(title == nil)
          puts("Youtube Error: video not found for id " + id);
          next
        end
      else
        res = fetch_http(uri);
        if(res == nil)
          puts("Error: Couldn't fetch: " + uri_str);
          next
        end

        begin
          title = res.body.scan(/<title>(.*)<\/title>/mi).first;
          if(title == nil)
            #puts("No <title> found for: " + uri_str);
            next
          end
          title = title.first;

          #puts(title.encoding.name); #ASCII-8BIT
          docEncoding = document_encoding(res);
          #puts("Document encoding = " + docEncoding);
          docEncoding = docEncoding ? docEncoding : "UTF-8"; # Suppose utf8 if unknown

          # Ensure proper encoding before HTMLEntities call
          #title = title.force_encoding('ASCII-8BIT').encode(docEncoding, :undef => :replace, :replace => '?');
          title = title.force_encoding(docEncoding);
          title = HTMLEntities.new.decode(title);

          # Not needed anymore?
          title = title.gsub(/[\x00-\x1F]/," ").strip;

          title = title[0..149] if(title.size > 150);

        rescue
          puts("Exception when encoding title");
        end
      end

      puts(title);
    end
  }
end


# Some tests:

puts("\nYoutube:");
fetchTitles("https://www.youtube.com/watch?v=9Xt5tZyrMZI");

puts("\nInvalid Youtube:");
fetchTitles("https://www.youtube.com/watch?v=INVALID");

puts("\nClassic web page:");
fetchTitles("http://home.web.cern.ch/about/updates/2015/04/cern-researchers-confirm-existence-force");

puts("\nClassic web page HTTPS:");
fetchTitles("https://ninjadoge24.github.io/");

puts("\nWith redirect:");
fetchTitles("http://on.mash.to/1ci9jhL");

puts("\nWith words:");
fetchTitles("Come to the dark side http://home.web.cern.ch/about/updates/2015/04/cern-researchers-confirm-existence-force right?");

puts("\nSeveral links with words:");
fetchTitles("Come to the dark side http://home.web.cern.ch/about/updates/2015/04/cern-researchers-confirm-existence-force right? or got to http://on.mash.to/1ci9jhL because you love tech");

puts("\nWeird char:");
fetchTitles("http://www.universfreebox.com/article/29773/L-Autorite-de-la-Concurrence-met-sous-scelle-des-bureaux-du-siege-de-SFR");
