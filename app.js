// Generated by CoffeeScript 1.7.1

/*
Module dependencies.
 */

(function() {
  var app, express, findSimilar, isEmpty, path, port, printKeysAndValues, request, routes, server, url;

  express = require("express");

  routes = require("./routes");

  path = require("path");

  request = require("request");

  url = require("url");


  /*
  Middleware / express setup.
   */

  app = express();

  port = process.env.PORT || 3000;

  app.set("port", port);

  app.set("views", path.join(__dirname, "views"));

  app.set("view engine", "jade");

  app.use(express.favicon());

  app.use(express.logger("dev"));

  app.use(express.json());

  app.use(express.urlencoded());

  app.use(express.methodOverride());

  app.use(app.router);

  app.use(require("stylus").middleware(path.join(__dirname, "public")));

  app.use(express["static"](path.join(__dirname, "public")));

  if ("development" === app.get("env")) {
    app.use(express.errorHandler());
  }

  server = app.listen(3000);

  console.log("Express server listening on port " + app.get("port"));


  /*
  URL Routing
   */

  app.get("/", routes.index);

  String.prototype.removeSlash = function() {
    var output;
    output = this;
    if (this.charAt(this.length - 1) === '/') {
      output = this.substr(0, this.length - 1);
    }
    return output;
  };

  isEmpty = function(obj) {
    var key;
    for (key in obj) {
      console.log(key);
      if (obj.hasOwnProperty(key)) {
        return false;
      }
    }
    return true;
  };

  printKeysAndValues = function(obj) {
    var i, key, value, _results;
    i = 0;
    _results = [];
    for (key in obj) {
      value = obj[key];
      if (i === 0) {
        console.log('query is ');
      }
      console.log('  ' + key + ': ' + value);
      _results.push(i++);
    }
    return _results;
  };

  app.post("/api/urls/", function(req, res) {
    var idPart, indexSplit, options, sharedPath, similarUrls, urlObj, urlStr, urlToVisit;
    urlStr = req.body.urlStr;
    similarUrls = urlStr.findSimilar;
    urlObj = url.parse(urlStr, true);
    console.log('host is ' + urlObj.host);
    console.log('pathname is ' + urlObj.pathname);
    if (isEmpty(urlObj.query)) {
      console.log('query is empty');
      console.log('REST style. No query string needed.');
      urlObj.pathname = urlObj.pathname.removeSlash();
      indexSplit = urlObj.pathname.lastIndexOf("/");
      sharedPath = urlObj.pathname.substr(0, indexSplit);
      idPart = urlObj.pathname.substr(indexSplit + 1);
      console.log('All event URLs share this string: ' + sharedPath);
      console.log('Event id is ' + idPart);
    } else {
      console.log('The events are accessed with a query string.');
      console.log('One of these is the event id.');
      printKeysAndValues(urlObj.query);
    }
    urlToVisit = url.format(urlObj);
    options = {
      url: urlToVisit,
      headers: {
        'User-Agent': 'PaulCowgillBot'
      }
    };
    request(options, function(error, response, html) {
      if (!error) {
        return console.log(html);
      }
    });
    res.set({
      'Content-Type': 'text/plain',
      'Location': '/urls/12345'
    });
    return res.send({
      success: true
    });
  });

  app.get("/post", function(req, res) {
    return request.post('http://service.com/upload', {
      form: {
        urlStr: 'http://www.sfmoma.org/exhib_events/exhibitions/513'
      }
    });
  });

  app.get("/api/urls/:url_id");


  /*
  Generate similar URLs
   */

  findSimilar = function() {
    return similarUrls;
  };

}).call(this);
