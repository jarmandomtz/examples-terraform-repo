# CICD with AWS and Jenkins

## Create a Github repo helloworld
On Github crate an organization "esausi"
And create a repository called "helloworld"

## Create a GitHub organization Jenkins Job
Using github-organization-plugin create an Organization Jenkins Job and configure it for access the organization projects, filtering just the project we need to scan

Steps
- Create Jenkins instance
- Create Github organization
- Create repo token (https://github.com/settings/tokens) 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
- Add token to credentials in Jenkins, User and Password type
- On Jenkins, create a Job
  - Type: github organization (enabled with default plugins)
  - Owner: Organization name, this case "esausi"
  - Credential: Credential for github, this case token "Github"
  - Behaviors->Add->Filter by name(with regular expresion), 
    - Regular expresion: change .* to helloworld
    - Discovery Branches: All branches
    - Scan organization Triggers: 5 mins

## Create helloworld pipeline
Steps
- Create new empty branch on helloworld project, "initial-branch"
- Initialize repo
- Install required npm packages: mocha, zombie
- Create nodejs app file, helloworld.js
- Create test file, test/helloworld_test.js
- Update test command on nodejs, package.json on test script section

```js
npm config set registry http://registry.npmjs.org/
npm init -yes
#package.json file created

npm install mocha@2.5.3 --save-dev
npm install zombie --save-dev

%> cat helloworld.js
var http = require("http")

http.createServer(function (request, response) {

   response.writeHead(200, {'Content-Type': 'text/plain'})

   response.end('Hello World\n')
}).listen(3000)

console.log('Server running')

%> cat test/helloworld_test.js
var Browser = require('zombie')
var assert = require('assert')

var app = require('../helloworld')

describe('main page', function(){
    before(function() {
        this.browser = new Browser({ site: 'http://localhost:3000'})
    })
    before(function(done) {
        this.browser.visit('/', done)
    })
    it('should say hello world', function(){
        assert.ok(this.browser.success)
        assert.equal(this.browser.text(), "Hello World")
    })
})

%> cat package.json
{
  "name": "helloworld",
...
  "scripts": {
    "test": "node_modules/mocha/bin/mocha"
  },
...

%> npm test

```


