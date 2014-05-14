
###
Module dependencies.
###
express = require("express")
routes = require("./routes")
#config = require("./config")
path = require("path")
#request = require("request")
#url = require("url")

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

app.get "/", routes.index
