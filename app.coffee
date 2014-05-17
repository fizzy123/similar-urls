
###
Module dependencies.
###
express = require("express")
routes = require("./routes")
#config = require("./config")
path = require("path")
request = require("request")
url = require("url")

###
Middleware / express setup.
###

app = express()

port = process.env.PORT or 3000
# all environments
app.set "port", port

#This lets the app know to look for view in the views folder
app.set "views", path.join(__dirname, "views")

#This sets the templating engine to jade
app.set "view engine", "jade"

app.use express.favicon()
app.use express.logger("dev")
app.use express.json()
app.use express.urlencoded()
app.use express.methodOverride()
app.use app.router

app.use require("stylus").middleware(path.join(__dirname, "public"))
app.use express.static(path.join(__dirname, "public"))

# development only
app.use express.errorHandler() if "development" is app.get("env")

server = app.listen(3000)
console.log "Express server listening on port " + app.get("port")


#Be sure to set user agent somewhere!!!

###
URL Routing
###

#show sample json response here
app.get "/", routes.index

#return a list of urls in the db
#app.get "/api/urls/"
	#if urlStr parameter is included
	#search for that specific URL by the string provided
	#?apikey={API_KEY}
	#?urlStr={urlStr}


#Add a url to the db
#To test:
#curl -H  "Content-Type:application/x-www-form-urlencoded" --data "urlStr=http%3A%2F%2Fwww.sfmoma.org%2Fexhib_evens%2Fexhibitions%2F513" http://localhost:3000/api/urls/
#curl -H  "Content-Type:application/x-www-form-urlencoded" --data "urlStr=http%3A%2F%2Fcalendar.boston.com%2Flowell_ma%2Fevents%2Fshow%2F274127485-mrt-presents-shakespeares-will" http://localhost:3000/api/urls/
#curl -H  "Content-Type:application/x-www-form-urlencoded" --data "urlStr=http%3A%2F%2Fwww.workshopsf.org%2F%3Fpage_id%3D140%26id%3D1328" http://localhost:3000/api/urls/
#curl -H  "Content-Type:application/x-www-form-urlencoded" --data "urlStr=http%3A%2F%2Fevents.stanford.edu%2Fevents%2F353%2F35309%2F" http://localhost:3000/api/urls/

String.prototype.removeSlash = () ->
	#If last char is a slash
	output = this
	if this.charAt(this.length-1) is '/'
		#Trim the slash
		output = this.substr(0,this.length-1)

	return output
	

isEmpty = (obj) ->
	for key of obj
		console.log(key)
		if(obj.hasOwnProperty(key))
			return false
	return true

printKeysAndValues = (obj) ->
	i = 0
	for key, value of obj
		if i is 0
			console.log('query is ')	
		console.log('  ' + key + ': ' + value)
		i++



app.post "/api/urls/", (req, res) ->
	#urlStr={urlStr}
	urlStr = req.body.urlStr
	similarUrls = urlStr.findSimilar

	urlObj = url.parse(urlStr,true) #true parameter parses query string
	#console.log(urlObj)

	console.log('host is ' + urlObj.host)
	console.log('pathname is ' + urlObj.pathname)
	
	#REST style. No query string needed.
	if isEmpty(urlObj.query)
		console.log('query is empty')
		console.log('REST style. No query string needed.')
		
		urlObj.pathname = urlObj.pathname.removeSlash()

		indexSplit = urlObj.pathname.lastIndexOf("/")
		sharedPath = urlObj.pathname.substr(0,indexSplit)
		
		#513 OR 274127485-mrt-presents-shakespeares-will OR 
		idPart = urlObj.pathname.substr(indexSplit+1)
		console.log('All event URLs share this string: ' + sharedPath)
		console.log('Event id is ' + idPart)
	
	#The events are accessed with a query string.
	else
		console.log('The events are accessed with a query string.')
		console.log('One of these is the event id.')
		#Print the query string object
		printKeysAndValues(urlObj.query)


	#buildURL
	urlToVisit = url.format(urlObj)

	#visit URL
	options =
		url: urlToVisit,
		headers: {
			'User-Agent': 'PaulCowgillBot'
		}
	request options, (error, response, html) ->

		console.log(response.statusCode)
		#Make sure no errors occurred when making the request
		if !error and response.statusCode == 200
				
			#Play with the html
			console.log html.substr(0,400)

		if !error and response.statusCode == 404
			console.log 'Try another URL'

	# Pick a generic regular expression that matches what we think is the ID / full query string
	# do this by parsing query string into special characters, letters, and numbers



	# Go up one for a restful path
	# if this fails, go up two



	# Find matches to the regex in the raw html



	# Build a list of the matches
	# if you had to go up two in the path, be careful when building the final URL results



	# Try them until you get 10 that work


	res.set({
		'Content-Type': 'text/plain',
		'Location': '/urls/12345'
	})
	res.send({ success: true })

#TEMP: try the api
app.get "/post", (req, res) ->
	request.post 'http://service.com/upload', {form:{urlStr:'http://www.sfmoma.org/exhib_events/exhibitions/513'}}


app.get "/api/urls/:url_id"
	#?apikey={API_KEY}


###
Generate similar URLs
###
findSimilar = () ->
	return similarUrls

