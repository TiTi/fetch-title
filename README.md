# fetch-title

Fetch a web page `<title>` with Ruby and the YouTube Data API

## Web Page

This **Ruby** script tries to look for links in a text and resolve the web page title for each url.  
The code is pretty crappy, we basically look for `<title></title>` with a regexp. :-*  

## YouTube Data API

The script allows to fetch youtube video title by using the YouTube Data API.  
Indeed, without using the dedicated API, you'll likely be blacklisted sooner or later:
>  429 "Too Many Requests"

### Installation
The Ruby Google API client is required:
```
gem install google-api-client
```
And you also have to replace `PUT_YOUR_YOUTUBE_KEY_HERE` with your own key. Create one over here:
* https://console.developers.google.com/
* https://developers.google.com/youtube/v3/docs/videos

Tip: In case you set up ip restriction ; make sure to define your IPv6 if you're using it.

### Output

We fetch the title, duration and viewCount. Sample for https://www.youtube.com/watch?v=9Xt5tZyrMZI:

    Terminator Genisys | Help Spot | Paramount Pictures UK [1m2s - 807833 views]

Many more info can be fetched with the API, check it out!

## Note

This code is currently used for an IRC bot that parse messages to provide page title on each posted link. 
I've bascially upgraded it with the YouTube Data API stuff.

## Known issues

* I'm using `URI::decode_www_form`, which require **Ruby>=2.1**  
In case you are using **Ruby<2.1**, just comment that line and uncomment the one just before.
* Encoding is not perfect, especially on windows. PR welcome.
