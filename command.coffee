#!/usr/bin/env coffee

program = require('commander')
http = require('http')
config = require('./config').config
colors = require('colors')


program
	.version('0.0.1')
	.usage('[options] texte')
	.option('-s, --short','Affiche la version étendue')
	.option('-t, --test','Vérifie que l API fonctionne')
	.parse(process.argv)


if program.test
	program.translate = 'well'
else 
	program.translate = program.args.join(' ')




options =
	host: "127.0.0.1"
	port: config.port
	method: 'GET'
	path: '/api.json?page='+encodeURIComponent(program.translate)

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
		json = JSON.parse(data)

		if program.test
			return test(json)
		
		console.log json.query.bold, '\t›\t', json.translation.green
		if json.types.length > 0 and not program.short
			console.log ''
			for el in json.types
				console.log "* ".green,el.name.underline.bold
				for translation in el.data
					if translation.translation.length < 6
						t='\t\t'
					else t='\t'
					console.log "\t",translation.translation.bold.green,t,'› ',translation.syn.join(', ').italic

request.on 'error', (e) ->
	if e.code is "ECONNREFUSED"
		console.log "Le service n'est pas lancé".bold.red.underline
		console.log "$ ".green,"cd /www/dev/dictionary && coffee server.coffee &"
request.end()


test = (json) ->
	i = 0
	x = (a,b,name='.') ->
		if a is b
			console.log "* #{++i} \t›".green,"#{name}".bold.underline.blue,a
		else
			console.log "* #{++i} \t›".red,"#{name}".bold.underline.yellow,a,' != ',b

	x json.query, 'well', 'query'
	x json.translation, 'bien', 'translation'
	x json.types.length, 4, 'types'
	x json.types[0].name, 'adverbe', 'type.nom'
	x json.types[0].data.length, 4, 'type.data'
	x json.types[0].data[0].syn.length, 6, 'type.data.syn'
