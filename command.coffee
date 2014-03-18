#!/usr/bin/env coffee

program = require('commander')
http = require('http')
config = require('./config').config
colors = require('colors')


program
	.version('0.0.1')
	.usage('[options] texte')
	.option('-s, --short','Affiche juste la traduction')
	.option('-e, --extended','Affiche des examples, synonymes ...')
	.option('-t, --unit-test','Vérifie que l API fonctionne')
	.parse(process.argv)


if program.unitTest
	program.translate = 'well'
else 
	program.translate = program.args.join(' ')

options =
	host: "127.0.0.1"
	port: config.port
	method: 'GET'
	path: '/api.json?page='+encodeURIComponent(program.translate)

query = (fn,version=1) ->
	options.path+='&version='+version
	request = http.request options, (result) ->
		if result.statusCode isnt 200
			console.log "Erreur".red, result.statusCode, options.host.green,options.path.green
			return process.exit(1)
		data = ""
		result.on "data", (d) ->
			data+= d.toString()
		result.on "end", ->
			fn(JSON.parse(data))
			
			
			

	request.on 'error', (e) ->
		if e.code is "ECONNREFUSED"
			console.log "Le service n'est pas lancé".bold.red.underline
			console.log "$ ".green,"cd '#{__dirname}' && coffee server.coffee 1>/dev/null 2>&1 &"
		else 
			console.log "Erreur apparue"
	request.end()

if program.unitTest
	query (json) -> 
		test(json)
	, 1+program.extended

else if program.short
	query (json) -> 
		renderShort(json)

else if program.extended
	query (json) ->	
		renderExtended(json)
	, 2

else 
	query (json) -> 
		render(json)

renderShort = (json) ->
	console.log json.query.bold, '\t›\t', json.translation.green

render = (json) ->
	renderShort(json)
	if json.types.length > 0
		console.log ''
		for el in json.types
			console.log "* ".green,el.name.underline.bold
			for translation in el.data
				if translation.translation.length < 6
					t='\t\t'
				else t='\t'
				console.log "\t",translation.translation.bold.green,t,'› ',translation.syn.join(', ').italic

renderExtended = (json) ->
	if json.def.length > 0
		console.log '\n'+'DEFINITION'.underline.bold
		for el in json.def
			console.log "* ".green,el.name.underline.bold
			for def in el.list
				console.log '  › ',def[0]
				console.log '\t  ',def[2].grey
	if json.examples.length > 0
		console.log '\n'+'EXAMPLES'.underline.bold
		for el in json.examples
			console.log '  › ',el[0].replace(/<.?b>/g,'').grey


test = (json) ->
	i = 0
	x = (a,b,name='.') ->
		if a is b
			console.log "* #{++i} \t›".green,"#{name}".bold.underline.blue,a
		else
			console.log "* #{++i} \t›".red,"#{name}".bold.underline.yellow,a,' != ',b

	x json.query, 'well', 'query'
	x json.types.length, 4, 'types'
	x json.types[0].name, 'adverbe', 'type.nom'
	x json.types[0].data.length, 4, 'type.data'
	x json.types[0].data[0].syn.length, 6, 'type.data.syn'

	if not program.extended
		x json.translation, 'bien', 'translation'

	if program.extended
		x json.examples.length, 3, 'examples'
		x typeof json.examples[0][0], 'string', 'examples.string'
		x json.def.length, 5, 'def'
		x json.def[0].name, 'adverbe', 'def.name'
		x json.def[0].list.length, 3, 'def.list'
		x json.def[0].list[0].length, 3, 'def.list[0]'