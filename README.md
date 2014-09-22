# Outbound Ruby Library

## Install
### Simple
    gem install outbound

### Bundler
    gem 'outbound', '~> 0.1.0', :require => 'outbound'

## Setup
    require 'outbound'
    require 'logger'

    Outbound.init("Your API KEY", Logger::ERROR)

## Identify User

    require 'outbound'
    user_info = {
        :first_name => "FirstName",
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

## Register a device token
You can register device tokens for push notification by sending them in the `identify` or individually using the `register` call.

    require 'outbound'

    # To register a token for Apple Push Notification Service (iOS)
    Outbound.register Outbound.APNS, "USER_ID", "DEVICE_TOKEN_HERE"

    # To register a token for Google Cloud Messaging (Android)
    Outbound.register Outbound.GCM, "USER_ID", "DEVICE_TOKEN_HERE"

## Revoke a device token
You can also revoke a previously registered device tokens.

    require 'outbound'

    # To revoke a token for Apple Push Notification Service (iOS)
    Outbound.revoke Outbound.APNS, "USER_ID", "DEVICE_TOKEN_HERE"

    # To revoke a token for Google Cloud Messaging (Android)
    Outbound.revoke Outbound.GCM, "USER_ID", "DEVICE_TOKEN_HERE"

## Specifics
### User ID
- A user ID must ALWAYS be a string or a number. Anything else will trigger an error and the call will not be sent to Outbound. User IDs are always stored as strings. Keep this in mind if you have different types. A user with ID of 1 (the number) will be considered the same as user with ID of "1" (the string).
- A user ID should be static. It should be the same value you use to identify the user in your own system.

### Event Name
- An event name in a track can only be a string. Any other type of value will trigger an error and the call will not be sent to Outbound.
- Event names can be anything you want them to be (as long as they are strings) and contain any character you want.

### Device Tokens
- If you send a device token through an `identify` call, that is equivalent to sending a `register` call. Regardless of the state of that token it will become active again and we will attempt to send notifications to it. It is recommended that if you use the `register` and `revoke` calls that you DO NOT send any tokens in `identify` calls. This way you can more easily control the state of your tokens.

### Results
- Both the `identify` and `track` methods return a `Outbound::Result` instance. It has `error` and `received_call` attributes that are accesible. `received_call` is a boolean that indicates if the http request was even made. `error` will be either `nil` or a string error message. There is also a `success?` method that returns true if the call went through to Outbound and did not have any errors. There are also `?` method available for each different error type.
