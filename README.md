# UW Student Web Service
This implements almost all of the public and private [v4 UW Student Webservice
endpoints](https://wiki.cac.washington.edu/display/SWS/Student+Web+Service+Client+Home+Page).  It's designed to fetch the JSON endpoints and return a Hash.  This gem has the capability to cache all web requests to assit with speedy development.

## Installation

    git clone git@github.com:UWFosterIT/uwsws.git
    bundle install
    rake build
    rake install

## Setup and Tests
Make sure to delete /test/test_private_endpoints.rb if you are not authorized at those endpoints otherwise half the tests will fail.  Change the ``cache`` symlink to point a valid path or create a directory for it like below.

    rm cache
    mkdir cache
    rake

## Usage
Basic example below gives you hash of term data for winter 2013

    require 'uw_student_webservice'
    service = UwStudentWebService.new
    term    = service.term(2013, "winter")

Maybe you want all the Geology courses from 1985?

    require 'uw_student_webservice'
    service = UwStudentWebService.new
    courses = service(1985, "winter", curriculum: "GEOG")

For cases where you need to page through results you can check for the existance
of ``service.next`` and make follow up queries based on it's data.

    require 'uw_student_webservice'
    service = UWStudentWebService.new
    courses = service.courses(1985, "autumn", curriculum: "GEOG", size: 25)
    puts service.next

For a full list of examples see /test

## Caching

If you pass ``use_cache: true`` as a parameter to ``UWStudentWebService.new`` all web requests will be cached in your local file system. However, you will need to have a cache directory in the root of whatever projects you are using this gem in.

## TO DO
Put this on RubyGems.org so it's as easy as "gem install uwsws"

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
