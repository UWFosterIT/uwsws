# UW Student Web Service
This implements most of the [v5 UW Student Webservice
endpoints](https://wiki.cac.washington.edu/display/SWS/Student+Web+Service+Client+Home+Page).  Each endpoint is querried for their json response and a hash is then returned.  This gem has the capability to cache all web requests to assit with speedy development.

## USE

### Installation

    gem install uw_sws

### Examples
First, configure the gem to how you want to use it.

```Ruby
require 'uw_sws'
cert    = "/TheFullPath/ToYour/x509Certificate.pem"
key     = "/TheFullPath/ToYour/x509Key"
url     = "https://ucswseval1.cac.washington.edu/student/v5/"
service = UwSws.new(cert: cert, key: key, base: url, use_cache: false)
```

Now get all the Geology courses from 1985?

    courses = service(1985, "winter", curriculum: "GEOG")

For cases where you need to page through results you can check for the existance
of ``service.next`` and make follow up queries based on it's data.

    courses = service.courses(1985, "autumn", curriculum: "GEOG", size: 25)
    puts service.next

For a full list of examples see ``/test``

### Caching

If you pass ``use_cache: true`` as a parameter to ``UwSws.new`` all web requests will be cached in your local file system. However, you will need to have a cache directory in the root of whatever projects you are using this gem in.

## Endpoint Implementation
All links below go to the official service documentation.  The code block refers to it's implementation in this gem.  See the tests for how to use all the supported endpoints.

``service = UwSws.new(...params...)``

#### Fully Supported
* [Campus](https://wiki.cac.washington.edu/display/SWS/Campus+Search+Resource+V5)  ``service.campus``
* [College Search](https://wiki.cac.washington.edu/display/SWS/College+Search+Resource+V5)  ``service.colleges``
* [Course](https://wiki.cac.washington.edu/display/SWS/Course+Resource+v5) ``service.course``
* [Course Search](https://wiki.cac.washington.edu/display/SWS/Course+Search+Resource+V5) ``service.courses``
* [Curriculumn Search](https://wiki.cac.washington.edu/display/SWS/Curriculum+Search+Resource+V5) ``service.curricula``
* [Department Search](https://wiki.cac.washington.edu/display/SWS/Department+Search+Resource+V5) ``service.departments``
* [Enrollment](https://wiki.cac.washington.edu/display/SWS/Enrollment+Resource+V5) ``service.enrollment``
* [Enrollment Search](https://wiki.cac.washington.edu/display/SWS/Enrollment+Search+Resource+V5) ``service.enrollments``
* [Personal Financial](https://wiki.cac.washington.edu/display/SWS/Personal+Financial+Resource+V5) ``service.finance``
* [Person](https://wiki.cac.washington.edu/display/SWS/Person+Resource+V5) ``service.person``
* [Person Search](https://wiki.cac.washington.edu/display/SWS/Person+Search+Resource+V5) ``service.people``
* [Registration](https://wiki.cac.washington.edu/display/SWS/Registration+Resource+V5) ``service.registration``
* [Registration Search](https://wiki.cac.washington.edu/display/SWS/Registration+Search+Resource+v5) ``service.registrations``
* [Section](https://wiki.cac.washington.edu/display/SWS/Section+Resource+V5) ``service.section``
* [Section Search](https://wiki.cac.washington.edu/display/SWS/Section+Search+Resource+v5) ``service.sections``
* [Term](https://wiki.cac.washington.edu/display/SWS/Term+Resource+V5) ``service.term``
* [Test Score](https://wiki.cac.washington.edu/display/SWS/Test+Score+Resource+V5) ``service.test_score``

#### Partially Supported (may or may not work)
* [Notice](https://wiki.cac.washington.edu/display/SWS/Notice+Resource+V5) ``service.notice``

#### Not implemented in this gem
Most of these are not implemented due to additional security requirements beyond a simple 509 cert.  Requirements such as permissions in ASTRA or x-uw-act-as permissions passed in the header.  Feel free fork and make a pull request with working tests if you have those permissions.

* [Degree Audit] (https://wiki.cac.washington.edu/display/SWS/SWS+v5+API) (all of them) under review
* [Change of Major](https://wiki.cac.washington.edu/display/SWS/Change+of+Major+Resource) extra security needed
* [Enrollment Majors ](https://wiki.cac.washington.edu/display/SWS/Enrollment+Majors) extra security needed
* [Resource List](https://wiki.cac.washington.edu/display/SWS/Resource+List+V5) not needed!
* [Section Status](https://wiki.cac.washington.edu/display/SWS/Section+Status+Resource+V5)  extra security needed
* [Version List](https://wiki.cac.washington.edu/display/SWS/Version+List+Resource+v5) not needed!


## Development

### Installation
Ignore the cache warnings after bundle install.

    git clone git@github.com:UWFosterIT/uwsws.git
    cd uwsws
    bundle install

#### Setup and Tests
Change the ``cache`` symlink to point to a valid path or create a directory for it like below.  Also, in ``/test`` you will need to provide the full path to your x.509 cert and key before running ``rake``.

    rm cache
    mkdir cache
    rake

You may get 1 or 2 test failing, "financial info", if that endpoint isn't in production yet. If something else fails it's most likely your cert or its permissions granted to it.

### Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### Changes Since < 2.0.0
* v4 is no longer used, all queries are now against v5
* no more public endpoints, all queries now require a cert
* Endpoints that ended with _search have been changed to their plural form (person_search to people)
* A few new endpoints were added, see list above for whats supported
