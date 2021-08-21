var http = require("http")
var date = require('date-and-time')

http.createServer(function (request, response) {

   // Send the HTTP header
   // HTTP Status: 200 : OK
   // Content Type: text/plain
   response.writeHead(200, {'Content-Type': 'text/plain'})

   // Send the response body as "Hello World"
   var mydate = new Date();
   var dateformated = date.format(mydate,'YYYY/MM/DD HH:mm:ss');

   var msg = "Hello World, " + dateformated + "\n";
   response.end(msg)
}).listen(3000)

// Console will print the message
console.log('Server running')
