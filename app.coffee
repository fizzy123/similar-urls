
###
Module dependencies.
###
express = require("express")
routes = require("./routes")
#config = require("./config")
path = require("path")
request = require("request")
url = require("url")
path = require("path")

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
#curl -H  "Content-Type:application/x-www-form-urlencoded" --data "urlStr=http%3A%2F%2Fcalendar.boston.com%2Flowell_ma%2Fevents%2Fshow%2F274127485-mrt-presents-shakespeares-will" http://localhost:3000/api/urls/
#curl -H  "Content-Type:application/x-www-form-urlencoded" --data "urlStr=http%3A%2F%2Fwww.sfmoma.org%2Fexhib_events%2Fexhibitions%2F513" http://localhost:3000/api/urls/
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
	console.log(urlObj)

	console.log('host is ' + urlObj.host)
	console.log('pathname is ' + urlObj.pathname)
	
	#REST style. No query string needed.
	if isEmpty(urlObj.query)
		console.log('query is empty')
		console.log('REST style. No query string needed.')
		
		urlObj.pathname = urlObj.pathname.removeSlash()

		indexSplit = urlObj.pathname.lastIndexOf("/")
		sharedPath = urlObj.pathname.substr(0,indexSplit)
		stringsToSearchFor = urlObj.pathname.split("/")
		
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
		stringsToSearchFor = []
		for key of urlObj.query
			stringsToSearchFor.push(key)
		stringsToSearchFor.push("")


	#build input URL
	urlToVisit = url.format(urlObj)
	#console.log(urlObj)

	# Pick a generic regular expression that matches what we think is the ID / full query string
	# do this by parsing query string into special characters, letters, and numbers
	
	# ONE REGEX TO MATCH ALL BUT ROOT DOMAIN
	# urlObj.pathname

	# SECOND REGEX TO MATCH JUST ID
	# idPart

	###
	# CODE GOES HERE
	###

	# Find the parent URL that's likely to link to multiple similar events
	#(if this fails, go up two)
	#build parent URL
	urlObj.pathname = sharedPath
	urlObj.query = {}
	urlObj.search = ''	
	urlToVisitParent = url.format(urlObj)
	#console.log(urlObj)

	console.log(urlToVisit)
	console.log(urlToVisitParent)


	visitUrl = (url) ->
		#visit URL
		options =
			url: url,
			headers: {
				'User-Agent': 'PaulCowgillBot'
			}

		request options, (error, response, html) ->

			console.log(response.statusCode)
			allAnswers = []
			allAnswersA = []
			allAnswersB = []

			#Make sure no errors occurred when making the request
			if !error and response.statusCode == 200
					
				#Play with the html
				#console.log html.substr(400,10)
				console.log "Searching for..."

				for element, index in stringsToSearchFor
					if index isnt stringsToSearchFor.length - 1 and element isnt ""
						console.log element
						regexToSearchFor= new RegExp("href=\s*[\"a-z0-9.\-\/_\?&;=:\s]*" + element + "[\"a-z0-9.\-\/_\?&;=:\s]*[0-9]+[\"a-z0-9.\-\/_\?&;=:\s]*",["g"])

						# Find matches to the regex in the raw html
						# Build a list of the matches
						# if you had to go up two in the path, be careful when building the final URL results
						useRoot = true
						answer = html.match(regexToSearchFor)

						if answer isnt null
							for word, count in answer
								word = word.replace(/\s/g, "")
								word = word.substr(6,word.length-7)
								answer[count] = word

							answerA = answer.slice(0)
							answerB = answer.slice(0)
							console.log('Building one set of answers')
							for word, count in answerA
								n = word.indexOf(urlToVisitParent)
								#If parent url isn't in the URL yet
								if n is -1
									#console.log("Parent url not in URL")
									urlOutput = urlObj.protocol + '//' + urlObj.host + word
	
								#If parent url is already in the URL
								else
									console.log("parent url is already in the URL")
									urlOutput = word
								answerA[count] = urlOutput

							console.log('Building the second set of answers')
							for word, count in answerB
								n = word.indexOf(urlToVisitParent)
								#If parent url isn't in the URL yet
								if n is -1
									#console.log("Parent url not in URL")
									
									#just stop using path.join!
									temp = path.join(urlToVisitParent, word)
									urlOutput = temp.replace(/http:\/\//g, "http:\/\/")
									

									#urlOutput = path.join(urlToVisitParent, word)
	
								#If parent url is already in the URL
								else
									console.log("parent url is already in the URL")
									urlOutput = word
								answerB[count] = urlOutput
							
							#if you don't have at least 10 answers yet, use these new ones
							if allAnswersA.length < 10
								allAnswersA = answerA
							
							# if you already have at least 10 answers
							# and you have another list of at least 10
							# choose the one with fewer answers
							if allAnswersA.length >= 10 and answerA.length >= 10
								if answerA.length < allAnswersA.length
									allAnswersA = answerA

							#if you don't have at least 10 answers yet, use these new ones
							if allAnswersB.length < 10
								allAnswersB = answerB
							
							# if you already have at least 10 answers
							# and you have another list of at least 10
							# choose the one with fewer answers
							if allAnswersB.length >= 10 and answerB.length >= 10
								if answerB.length < allAnswersB.length
									allAnswersB = answerB

				#Check one URL
				options2 =
					url: allAnswersA[0],
					headers: {
						'User-Agent': 'PaulCowgillBot'
					}
				
				request options2, (err, resp, html2) ->
					console.log('Checking a test URL')
					console.log(allAnswersA[0])
					if !error
						if resp isnt undefined
							if resp.statusCode == 200
								console.log(resp.statusCode)
								allAnswers = allAnswersA.slice(0,10)
								console.log("Final answer is")
								console.log(allAnswers)
								res.send({ success: true, answer: allAnswers })
						else
							console.log('Response undefined')

				#Check one URL
				options2 =
					url: allAnswersB[0],
					headers: {
						'User-Agent': 'PaulCowgillBot'
					}
				
				request options2, (err, resp, html2) ->
					console.log('Checking a test URL')
					console.log(allAnswersB[0])
					if !error
						if resp isnt undefined
							if resp.statusCode == 200
								console.log(resp.statusCode)
								allAnswers = allAnswersB.slice(0,10)
								console.log("Final answer is")
								console.log(allAnswers)
								res.send({ success: true, answer: allAnswers })
						else
							console.log('Response undefined')



				# # Pick the best 10

				console.log("Other URLs are:")
				console.log(allAnswersA)
				console.log("...or...")
				console.log(allAnswersB)


				#Still need to fix Stanford URLs. (and ones for )
				#Need to stop truncating Boston URLs.


			if !error and response.statusCode == 404
				console.log 'Try another URL'
				urlToVisitParent = urlToVisitParent.removeSlash()

				indexSplit = urlToVisitParent.lastIndexOf("/")
				urlToVisitParent = urlToVisitParent.substr(0,indexSplit)
				console.log(urlToVisitParent)

				#Also update the id so you can still build the url

				###
				# CODE GOES HERE
				###
				
				visitUrl(urlToVisitParent)

			return response.statusCode

	visitUrl(urlToVisitParent)

	res.set({
		'Content-Type': 'text/plain',
		'Location': '/urls/12345'
	})

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

