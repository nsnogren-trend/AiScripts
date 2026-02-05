## Summary
Add an API automation test framework to this repo. It should be a separate Xunit project to not interfere with the existing tests. It should target the deployed app at [api-url].

## Background context
The reasons I'm adding this framework to this repo are: 

1. This repo contains the code for the endpoints I'll be testing against. The tests should be able to share the real production DTO's so that all creating API requests and parsing responses will always perfectly match without duplicating code in a separate test framework repo.

2. The API tests can automatically be updated to reflect the real available endpoints. Copilot can check for changed endpoint code and update the tests. Copilot can see exactly how the endpoints work and write working tests for them.

## Fixtures
There should be a fixture which logs in and saves authentication data to a file, so that all tests can reuse the logged in state. That fixture should be agnostic of login method, in order for us to develop multiple alternate methods and code the fixture to select the appropriate one. The fixture should contain logic to trigger login only if the auth data is stale.

## Logins
There should login methods to perform the actual login. The login data should be saved per combination of username + environment. 

## Users
There should be a user class containing username and password which can be passed in to a login method from the fixture. The fixture should be able to authenticate multiple users in parallel to save time.

## .env
Username and password should exist as environment variables and be read from a .env for running the tests locally

## Passing reusable authenticated clients to tests
Test classes will access configured authenticated API clients from the fixture instance.

## Env config
There should be a config class for setting test-environment URLs (staging vs RC, etc.) and other settings. It should be easy to select an environment to run the tests against, whether running them locally or from git actions.

## Project Organization
There should be a top level "api" folder for the automation.
Subfolder for each domain (result, inventory, tags, etc.). *use the names from the real services.*
Subfolder under domain for each endpoint *use the names from the real services.*
Within the end point folder should be:
1. The API code to interact with the endpoint
2. The test file (with one happy path test by default to assert the endpoint is functional)
**The API and Test files should reference the real [repo-name] DTOs (that's one of the reasons I'm putting this project in the [repo-name] repo)**

## Tests
To start there should be a minimum of one test to assert the endpoint is functional. It should first assert on status code and then check one representative value from the response, if available.

Any test which needs to access test data to function (i.e. you need a GUID to view a record) should try to pull that data from a search, config, or select endpoint.

This should make the tests very resilient to other users changing data in the environments.

For instance - the search endpoint file can have a simple call to post the search, but another method which accepts a search parameter and number of records, and then returns the ID's of those records.

## Common code
Shared functions like Search, History, Note, etc. should be in a common folder which can be referenced/reused across domains. Be very careful about graduating a function to "common." For instance, many records have a /detail endpoint, but I would not graduate this to common because at minimum they have different response DTO's. 

## Success criteria
1. This project should have a library of API automation and tests which test the real deployed app which [repo-name] is a part of.
2. It should share the real DTO's with [repo-name].
3. It should have a smoke test for each endpoint.
4. It's code and naming conventions should be incredibly consistent.
5. DO NOT ADD ANY COMMENTS. Code should read like prose. Names express function.

## Future work after you're done
I will need to provide the usernames and passwords once you're done.

I will need to provide a login method to create an authenticated client. Make it very easy to add.

I should be able to tell copilot to "check [repo-name] for endpoint updates and update the API automation coverage," and get perfectly consistent results because this framework will be so clean, consistent, and simple.

I should be able to tell copilot to design a test which strings multiple endpoints together to create a workflow and get perfectly consistent results, again because this framework is so clean, consistent, and simple.

## Final note
**Take as long as you need to to get this right. You won't be able to run the tests against the real deployed app yet - but you should take every measure, perform every code review, to ensure they will work correctly when you're done.**

