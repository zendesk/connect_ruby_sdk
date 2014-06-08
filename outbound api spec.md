The API has 2 endpoints.

1. /identify

Used to identify a user. Only one required param: "user_id". Optional parameters include "first_name", "last_name", "email", "phone_number" (all are strings) and "apns" and "gcm" (which are lists of strings). You can also include a free-form hash of attributes. This optional hash should be called "attributes". A sample request body might look like:

    {
        user_id: str|num,
        first_name: str,
        last_name: str,
        email: str,
        phone_number: str,
        apns: [],
        gcm: [],
        attributes: {
            anything: "can go here"
        }
    }

2. /track
Used to track events triggered by users. There are 2 required params: "user_id" and "event". A third optional param is "properties" which should be a free-form hash of properties describing the event. A sample request might be:

    {
        user_id: str|num,
        event: str,
        properties: {
            anything: "can go here"
        }
    }

You can also identify a user inside of a track call by including all the parameters from the /identify call inside a parameter called "user" in the track call. Like this:

    {
        user_id: str|num,
        event: str,
        properties: {
            anything: "can go here"
        }
        user: {
            first_name: str,
            last_name: str,
            email: str,
            phone_number: str,
            apns: [],
            gcm: [],
            attributes: {
                anything: "can go here"
            }
        }
    }
