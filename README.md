# Outbound Ruby Library

## Install
### Simple
    gem install outbound-ruby

### Bundler
    gem 'outbound', '~> 0.1.0', :require => 'outbound'

## Setup
    require 'outbound'
    require 'logger'

    Outbound.init("Your API KEY", Logger::ERROR)

## Identify User

    require 'outbound'
    user_info = {
        :first_name => "FirstName"
        :last_name => "LastName",
        :email => "username@domain.com",
        :phone_number => "5551234567",
        :apns_tokens => ["ios device token"],
        :gcm_tokens => ["android device token"]
    }
    user_attributes = {
        :some_other_attribute => "Something"
    }
    Outbound.identify("USER ID", user_info, user_attributes)

## Track Event

    require 'outbound'
    event_properties = {
        :some_event_property => "Something"
    }
    Outbound.track("USER ID", "EVENT NAME", event_properties)

## Specifics
### User ID
- A user ID must ALWAYS be a string or a number. Anything else will trigger an error and the call will not be sent to Outbound. User IDs are always stored as strings. Keep this in mind if you have different types. A user with ID of 1 (the number) will be considered the same as user with ID of "1" (the string).
- A user ID should be static. It should be the same value you use to identify the user in your own system.

### Event Name
- An event name in a track can only be a string. Any other type of value will trigger an error and the call will not be sent to Outbound.
- Event names can be anything you want them to be (as long as they are strings) and contain any character you want.

### Results
- Both the `identify` and `track` methods return a `Outbound::Result` instance. It has `error` and `received_call` attributes that are accesible. `received_call` is a boolean that indicates if the http request was even made. `error` will be either `nil` or a string error message. There is also a `success?` method that returns true if the call went through to Outbound and did not have any errors. There are also `?` method available for each different error type.
