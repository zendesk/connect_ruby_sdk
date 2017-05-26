require File.expand_path('../lib/outbound', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'outbound'
  s.version     = Outbound::VERSION
  s.date        = Date.today.to_s
  s.summary     = 'Outbound sends automated email, SMS, phone calls and push notifications based on the actions users take (or do not take) in your app.'
  s.description = "Outbound sends automated email, SMS, phone calls and push notifications based on the actions users take or do not take in your app. The Outbound API has two components:

Identify each of your users and their attributes using an identify API call.
Track the actions that each user takes in your app using a track API call.
Because every message is associated with a user (identify call) and a specific trigger action that a user took or should take (track call), Outbound is able to keep track of how each message affects user actions in your app. These calls also allow you to target campaigns and customize each message based on user data.

Example: When a user in San Francisco(user attribute) does signup(event) but does not upload a picture(event) within 2 weeks, send them an email about how they'll benefit from uploading a picture."
  s.authors     = ['Travis Beauvais']
  s.email       = 'support@outbound.io'
  s.files       = ['lib/outbound.rb']
  s.homepage    = 'https://outbound.io'
  s.license = 'MIT'
end
