[![Build Status](https://travis-ci.com/openedinc/minerva.svg?branch=master)](https://travis-ci.com/openedinc/minerva)

# Minerva

## Summary
`Minerva` is a repository for standards-alignable resources. It includes endpoints to query and filter the resources, as well as a database schema for the resources.

## Using Minerva as a Consumer

### Getting an Access Token

You'll first need to ask your `Minerva` provider to create an account for you. Your provider will then give you a `client_id` and `secret` that you'll use to get an access token. Then, you'll provide that access token with all your other requests.

Here is a cURL example of how you would use your `client_id` and `secret` to get your access token. You would need to change the `BASE_URL` to match your `Minerva` provider's url.  

```
curl -X POST BASE_URL/oauth/token \
  -F grant_type=client_credentials \
  -F client_id=FILL_ME_IN \
  -F client_secret=FILL_ME_IN_TOO
```

If you need write privileges (to create/update/delete resources), then you'll need to specify a `write` scope when getting your access token, like in:
```
curl -X POST BASE_URL/oauth/token \
  -F grant_type=client_credentials \
  -F client_id=FILL_ME_IN \
  -F client_secret=FILL_ME_IN_TOO
  -F scope='public write'
```

### Using Your Access Token
Once you have received the token, you'll need to provide it in the headers of all other future requests (except for `get_token`). Note that your header needs to have the word "Bearer" in it. Here is a cURL example making a `GET` request to `/ims/rs/v1p0/subjects` (replace `ACCESS_TOKEN` with your actual access token):

```
curl -X GET BASE_URL/ims/rs/v1p0/subjects \
  -H 'Authorization: Bearer ACCESS_TOKEN'
```

### Making Requests
These are the existing endpoints:

#### Subjects Controller
1. `GET /ims/rs/v1p0/subjects` - `index`

#### Resources Controller
1. `GET /ims/rs/v1p0/resources` - `index`
2. `POST /ims/rs/v1p0/resources` - `create`
3. `PUT /ims/rs/v1p0/resources/:id` - `update` (can also use `PATCH`)
4. `DELETE /ims/rs/v1p0/resources/:id` - `destroy`

Note that all users have access to the `index` actions for both controllers by default. However, for the other endpoints that write changes, `write` scopes are necessary. See above on obtaining access tokens with `write` scopes.


An example request you could do (filling in for `BASE_URL` and `TOKEN`) is
```
curl -X GET \
  "BASE_URL/ims/rs/v1p0/resources?limit=10&offset=0&filter=name~'hello'&sort=name&orderBy=asc" \
  -H "accept: application/json" \
  -H "authorization: Bearer ACCESS_TOKEN"
```

See the documentation on Swaggerhub to view more details on the kinds of queries you can do: https://app.swaggerhub.com/apis/ACT.org/lti-resource_search_service_open_api_json_definition/1.0#/  

## Using Minerva as a Provider

### Getting Started
Type `bin/setup` to install needed gems and set up your database.

### Granting Users Access
When a user or application requests access, you will need to create an application for them. You can type in a rails console
```ruby
redirect_uri = 'https://www.example.com' # Fill in for your URL
name = 'example_username' # Fill in user name for your user
Doorkeeper::Application.create!(
  name: name, redirect_uri: redirect_uri, scopes: 'public'
) # You can give write scopes with `scopes: 'public write'`
```
Your user will need the resulting app's `secret` and `uid`.
They will generate an access token themselves with these credentials.

You can create a set of test credentials for dev environment by running
```
bundle exec rake ex_oauth
```
You can create a set of test credentials for test environment by running
```
bundle exec rake ex_oauth RAILS_ENV=test
```
The credentials will be printed to screen.  
Note that you cannot use this command in production for safety purposes.


## Extensions
1. Resource id search. You can use comma delimited resource ids in filter parameter
if you want to get specific resources:
```
curl -X GET \
  "BASE_URL/ims/rs/v1p0/resources?limit=10&offset=0&filter=id='1,2,3'" \
  -H "accept: application/json" \
  -H "authorization: Bearer ACCESS_TOKEN"
```


## Contributing
If you want to contribute, you can either make your own extension and then
add yours to the list of extensions, or you can work on extending an existing
extension. Just open a pull request. Make sure to write specs for everything you
do, and keep current specs passing :)

Run `bin/ci` to run the project's specs. Keep in mind that it will clean out
the test db.
