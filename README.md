# mgTranslate

## Translation in the terminal.

![gif](http://i.uto.io/jUyNT)

As in v0.0.1, it allows only EN->FR

### Installation

`git clone https://github.com/marg51/mgTranslate.git mg-translate`

`cd $_`

`npm install`

`coffee server.coffee 1>/dev/null 2>&1 &` or `coffee server.coffee`

`coffee command.coffee -h`

`coffee command.coffee well`

### Global command

- Make `command.coffee` executable : `chmod +x command.coffee`
- Add an alias to your `~/.bashrc` or equivalent : `alias translate='/path/to/command.coffee'`
- Reload your conf : `source ~/.bashrc`
- Have fun : `translate well`


## Dictionary.app Hijack

I started this project to add a translator to Apple's Dictionary.app, based on what the Wikipedia plugin do.

![gif](http://i.uto.io/Tk3NT)

Sadly, the Wikipedia plugin is hardcoded and we can only make static plugin.

Never mind, we can use the Wikipedia plugin, and send OUR data, instead of Wikipedia's.

That plugin use the proxy `http://lookup-api.apple.com` to fetch Wikipedia's data.

>I used `[ngrep](https://ngrep.sourceforge.net)` to get the API endpoint, which is a supercool tool. I used this command `ngrep -W byline -d en0 "^GET |^POST " tcp and port 80`

In `/etc/hosts`, I added this line `127.0.0.1 lookup-api.apple.com` which resolve `lookup-api.apple.com` to the IP `127.0.0.1`

We need to clear the DNS cache : `dscacheutil -flushcache`

nginx will now get the requests from Dictionary.app. We need to update its conf to redirect all request to our nodejs module

```nginx
server {
        listen   80;
        # Yep, the domain requested still is this one
        server_name lookup-api.apple.com;

        location / {
                # I used the random local port 8346, you can use whatever you want.
                # This port is used by our node application (see config.coffee)
                proxy_pass       http://127.0.0.1:8346;
                proxy_http_version 1.1;
        }
}```

Don't forget to reload nginx `sudo nginx -s reload`


If the service is started (`coffee server.coffee`, see section "Installation" above), you can relaunch Dictionary.app and go to the Wikipedia section.

**Easy, right ?**

## API

The service has two endpoint : `fr.wikipedia.org/w/api.php` and `api.json`

The former is for Dictionary.app, see above. The latter is for the terminal, but it returns raw data.
You can use it for your own application.

![](http://i.uto.io/DQ5MA)

#### params

  - `page` the query string
  - `version` set version to 2 if you want examples from gTranslate. Works only for one word (ie "well", not "very well")

#### example

  - `curl http://localhost:8346/api.json?page=well&version=2`
  - `curl http://localhost:8346/api.json?page=very%20well`

#### format

```javascript
{
  "query": "well", // what user has requested
  "translation": "bien", // the main translation
  "types": [ // some others translations if any, by type (ie noun, adverbe ...). The order of type is not guaranteed
    {
      "name": "adverbe",
      "data": [
        {
          "translation": "bien",
          "syn": [ // synonymes
            "well",
            "good"
            // [...] others synonymes
          ]
        }
        // [...] others translations of type "adverbe"
      ]
    },
    {
      "name": "nom",
      "data": [
        {
          "translation": "puits",
          "syn": [
            "well"
            // [...] others synonymes
          ]
        }
        // [...] others translations of type "nom"
      ]
    }
    // [...] others types of translations
  ]
}
```

## Limitations

The very first goal of this project, was to allow the triple-tap (Mac OS X) to translate the word. I couldn't make it work correctly. Sometimes it works. Sometimes not.

![](http://i.uto.io/zIyMj)

## Todo

- Select the language.
- Clean up the code.
- Warn when there is a mistake / typo

## Warnings

It is only for private and personal use. Use it at your own risk
This project use google translate. Please read https://developers.google.com/translate/v2/terms

##
