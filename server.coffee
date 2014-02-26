restify = require('restify')
http = require('http')
config = require('./config').config

server = restify.createServer
	name:'dictionary'
	version: '0.0.1-dev'

server.use restify.acceptParser(server.acceptable)
server.use restify.queryParser()
server.use restify.bodyParser()


options =
	host: "translate.google.fr"
	port: 80
	method: 'GET'
	_path: '/translate_a/t?client=t&sl=en&tl=fr&hl=fr&sc=2&ie=UTF-8&oe=UTF-8&oc=2&otf=1&ssel=0&tsel=0&q='
	headers:
		'Pragma': 'no-cache'
		'Accept-Language': 'fr-FR,fr;q=0.8,en-US;q=0.6,en;q=0.4'
		'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1681.0 Safari/537.36'
		'Accept': "application/json"
		'Referer': 'http://translate.google.fr/'
		'Cache-Control': 'no-cache'
		
server.get 'fr.wikipedia.org/w/api.php', (req, res, next) ->
	if req.params.search?
		result = [req.params.search,[req.params.search]]
		console.log "search for ", result
		res.send result
		return

	query req.params.page.replace(/_/g,' '), (json) ->
		response = """<?xml version="1.0"?><api><parse displaytitle="#{json.query} -› #{json.translation}"><redirects /><text xml:space="preserve">
			&lt;h1&gt; #{json.query} -› #{json.translation} &lt;/h1&gt;"""

		for el in json.types
			response += """&lt;h3&gt; #{el.name} &lt;/h3&gt;
				&lt;ul&gt;"""
			for translation in el.data
				response += """&lt;li&gt;&lt;b&gt; #{translation.translation} &lt;/b&gt;
					- &lt;i&gt; #{translation.syn.join(', ')} &lt;/i&gt; &lt;/li&gt;"""
			response += '&lt;/ul&gt;'
		response += "</text></parse></api>"
		res.header('Content-Type','application/xml')
		res.send response

server.get 'api.json', (req, res, next) ->
	query req.params.page.replace(/_/g,' '), (json) ->
		res.send json
	

query = (search,fn) ->
	options.path = options._path+encodeURIComponent(search)
	request = http.request options, (result) ->
		if result.statusCode isnt 200
			res.send {statusCode:result.statusCode}
			console.log result.headers
			console.log options
			return
		data = ""
		result.on "data", (d) ->
			data+= d.toString()
		result.on "end", ->
			json = extract(JSON.parse(data.replace(/,(?=,)/g,',[]')))
			fn(json)

	request.on 'error', (e) ->
		console.log "erreur",e
	request.end()


extract = (e) ->
	console.log JSON.stringify(e)
	a = {}
	a.query = e[0][0][1]
	a.translation = e[0][0][0]
	a.types = []
	if Object.prototype.toString.call(e[1]) is "[object Array]"
		for el in e[1]
			tmp = {name:el[0],data:[]}
			a.types.push tmp
			for value in el[2]
				console.log el[0],value[1]
				tmp.data.push translation: value[0], syn: value[1]

	return a

server.listen config.port, ->
	console.log 'lookup-api.uto.io, localhost:'+config.port
