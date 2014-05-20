
###
Module dependencies.
###
express = require("express")
routes = require("./routes")
path = require("path")
request = require("request") #Use HTTP to visit URLs
url = require("url") #URL parsing
_ = require("underscore") #Useful array operations, etc.

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

app.use express.static(path.join(__dirname, "public"))

# development only
app.use express.errorHandler() if "development" is app.get("env")

server = app.listen(3000)
console.log "Express server listening on port " + app.get("port")

###
# General purpose functions
###
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

# To print out an object's keys and values with a single commands
printKeysAndValues = (obj) ->
	i = 0
	for key, value of obj
		if i is 0
			console.log('query is ')	
		console.log('  ' + key + ': ' + value)
		i++


###
URL Routing
###

#show sample json response here
app.get "/", routes.index

#To test:
#curl -H  "Content-Type:application/x-www-form-urlencoded" --data "urlStr=http%3A%2F%2Fcalendar.boston.com%2Flowell_ma%2Fevents%2Fshow%2F274127485-mrt-presents-shakespeares-will" http://localhost:3000/api/urls/
#curl -H  "Content-Type:application/x-www-form-urlencoded" --data "urlStr=http%3A%2F%2Fwww.sfmoma.org%2Fexhib_events%2Fexhibitions%2F513" http://localhost:3000/api/urls/
#curl -H  "Content-Type:application/x-www-form-urlencoded" --data "urlStr=http%3A%2F%2Fwww.workshopsf.org%2F%3Fpage_id%3D140%26id%3D1328" http://localhost:3000/api/urls/
#curl -H  "Content-Type:application/x-www-form-urlencoded" --data "urlStr=http%3A%2F%2Fevents.stanford.edu%2Fevents%2F353%2F35309%2F" http://localhost:3000/api/urls/

#Include urlStr in the url
app.get "/api/urls/:urlStr", (req, res) ->
	
	#Let the client know to expect JSON data
	res.set({
		'Content-Type': 'application/json'
	})
	
	alreadySent = false
	#If the API request takes more than 2 minutes,
	#give up and return a 404 error
	setTimeout(()->
		if alreadySent is false
			res.status(404)
			res.send({success: false})
	, 120000)

	urlStr = req.params.urlStr

	#Convert the URL into an object using Node's url module
	urlObj = url.parse(urlStr,true) #true parameter parses query string
	
	#If the URL is REST style,
	#no query string needed.
	if isEmpty(urlObj.query)
		
		urlObj.pathname = urlObj.pathname.removeSlash()
		stringsToSearchFor = urlObj.pathname.split("/")
		#513 OR 274127485-mrt-presents-shakespeares-will OR 
		#idPart = urlObj.pathname.substr(indexSplit+1)
		
	#The events are accessed with a query string.
	else
		# Print the query string object
		printKeysAndValues(urlObj.query)
		stringsToSearchFor = []
		for key of urlObj.query
			stringsToSearchFor.push(key)
		stringsToSearchFor.push("")

	#build input URL
	urlToVisit = url.format(urlObj)

	# Find the parent URL that's likely to link to multiple similar events
	#(if this fails, go up two)
	#build parent URL
	indexSplit = urlObj.pathname.lastIndexOf("/")
	urlObj.pathname = urlObj.pathname.substr(0,indexSplit)
	#sharedPath = urlObj.pathname.substr(0,indexSplit)
	#urlObj.pathname = sharedPath
	urlObj.query = {}
	urlObj.search = ''	
	urlToVisitParent = url.format(urlObj)

	visitUrl = (url) ->
		#visit URL
		options =
			url: url,
			headers: {
				'User-Agent': 'PaulCowgillBot'
			}

		console.log(url)

		request options, (error, response, html) ->

			console.log(response.statusCode)
			
			#Initialize arrays to store possible answers
			allAnswers = []
			allAnswersA = []
			allAnswersB = []

			#If the parent request didn't work,
			#change parent url to one higher and recurse
			if !error and response.statusCode == 404
				console.log 'Try another URL'
				urlToVisitParent = urlToVisitParent.removeSlash()

				indexSplit = urlToVisitParent.lastIndexOf("/")
				urlToVisitParent = urlToVisitParent.substr(0,indexSplit)
				console.log(urlToVisitParent)

				#Also update the id so you can still build the url
				
				visitUrl(urlToVisitParent)

			#Make sure no errors occurred when making the request
			if !error and response.statusCode == 200
					
				#Play with the html
				console.log "Searching for..."

				for element, index in stringsToSearchFor
					if index isnt stringsToSearchFor.length - 1 and element isnt ""
						console.log element
						
						# Pick a regular expression that matches possible href matches
						regexToSearchFor= new RegExp("href=\s*[\"a-z0-9.\-\/_\?&;=:\s]*" + element + "[\"a-z0-9.\-\/_\?&;=:\s]*[0-9]+[^> ]*",["g"])
						
						# Find matches to the regex in the raw html
						# Build a list of the matches
						answer = html.match(regexToSearchFor)

						#if there was a match
						if answer isnt null
							for word, count in answer
								#remove any spaces
								word = word.replace(/\s/g, "")
								#get rid of the href="..." on the outside of the string
								word = word.substr(6,word.length-7)
								answer[count] = word

							#Make copies of the array to try different URL string concatenations
							answerA = answer.slice(0)
							answerB = answer.slice(0)

							#console.log('Building one set of answers')
							for word, count in answer
								
								#Is the path relative or absolute?
								n = word.indexOf(urlToVisitParent)
								
								#If the URL path is relative
								#It might be relative to the parent directory or the root domain
								if n is -1
									
									#Try assuming the path is relative to the root domain
									urlOutputA = urlObj.protocol + '//' + urlObj.host + '/' + word
									
									#Try assuming the path is relative to the parent directory
									urlOutputB = urlToVisitParent + '/' + word
									
									#Make sure there are two slashes after the http:
									#and one between each subsequent part of the path
									urlOutputA = urlOutputA.replace(/\/\//g, "\/")
									urlOutputA = urlOutputA.replace(/http:\//g, "http:\/\/")
									urlOutputB = urlOutputB.replace(/\/\//g, "\/")
									urlOutputB = urlOutputB.replace(/http:\//g, "http:\/\/")

								#If URL path is absolute
								else
									console.log("parent url is already in the URL")
									urlOutputA = word
									urlOutputB = word

								answerA[count] = urlOutputA
								answerB[count] = urlOutputB

							#We're still inside the loop of the stringsToSearchFor
							#So we don't know which answer array is probably right yet
							#Let's use the number of results for each search string
							#as an indicator.

							#if you don't have at least 10 answers yet, use these new ones
							if allAnswersA.length < 10
								allAnswersA = answerA
							if allAnswersB.length < 10
								allAnswersB = answerB
							
							# if you already have at least 10 answers
							# and you have another list of at least 10
							# choose the one with fewer answers
							if allAnswersA.length >= 10 and answerA.length >= 10
								if answerA.length < allAnswersA.length
									allAnswersA = answerA
							if allAnswersB.length >= 10 and answerB.length >= 10
								if answerB.length < allAnswersB.length
									allAnswersB = answerB

				###
				# Choose the correct array from the search results
				# Note: Duplicated code below - need to clean this up
				###
				
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
								allAnswersA = _.uniq(allAnswersA,false)
								allAnswers = allAnswersA.slice(0,10)
								console.log("Final answer is")
								console.log(allAnswers)
								if alreadySent is false
									alreadySent = true
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
								allAnswersB = _.uniq(allAnswersB,false)
								allAnswers = allAnswersB.slice(0,10)
								console.log("Final answer is")
								console.log(allAnswers)
								#res.status(200)
								if alreadySent is false
									alreadySent = true
									res.send({ success: true, answer: allAnswers })
						else
							console.log('Response undefined')


			return response.statusCode

	#Call the function
	visitUrl(urlToVisitParent)