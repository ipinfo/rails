# <img src="https://ipinfo.io/static/ipinfo-small.svg" alt="IPinfo" width="24"/> IPinfo Rails Client Library

This is the official Rails client library for the IPinfo.io IP address API, allowing you to lookup your own IP address, or get any of the following details for an IP:

- [Geolocation](https://ipinfo.io/ip-geolocation-api) (city, region, country, postal code, latitude and longitude)
- [ASN](https://ipinfo.io/asn-api) (ISP or network operator, associated domain name, and type, such as business, hosting or company)
- [Company](https://ipinfo.io/ip-company-api) (the name and domain of the business that uses the IP address)
- [Carrier](https://ipinfo.io/ip-carrier-api) (the name of the mobile carrier and MNC and MCC for that carrier if the IP is used exclusively for mobile traffic)

Check all the data we have for your IP address [here](https://ipinfo.io/what-is-my-ip).

## Getting Started

You'll need an IPinfo API access token, which you can get by singing up for a free account at [https://ipinfo.io/signup](https://ipinfo.io/signup).

The free plan is limited to 50,000 requests per month, and doesn't include some of the data fields such as IP type and company data. To enable all the data fields and additional request volumes see [https://ipinfo.io/pricing](https://ipinfo.io/pricing)

### Installation

1. Option 1) Add this line to your application's Gemfile:

    ```ruby
    gem 'ipinfo-rails'
    ```

    Then execute:

    ```bash
    $ bundle install
    ```

    Option 2) Install it yourself by running the following command:

    ```bash
    $ gem install ipinfo-rails
    ```

1. Open your `config/environment.rb` file or your preferred file in the `config/environment` directory. Add the following code to your chosen configuration file.

    ```ruby
    require 'ipinfo-rails'
    config.middleware.use(IPinfoMiddleware, {token: "<your_token>"})
    ```

    Note: if editing `config/environment.rb`, this needs to come before `Rails.application.initialize!` and with `Rails.application.` prepended to `config`, otherwise you'll get runtime errors.

1. Restart your development server.

### Quickstart

Once configured, `ipinfo-rails` will make IP address data accessible within Rail's `request` object. These values can be accessed at `request.env['ipinfo']`.

## Details Data

`request.env['ipinfo']` is `Response` object that contains all fields listed [IPinfo developer docs](https://ipinfo.io/developers/responses#full-response) with a few minor additions. Properties can be accessed through methods of the same name.

```ruby
request.env['ipinfo'].hostname == 'cpe-104-175-221-247.socal.res.rr.com'
```

### Country Name

`request.env['ipinfo'].country_name` will return the country name, as supplied by the `countries.json` file. See below for instructions on changing that file for use with non-English languages. `request.env['ipinfo'].country` will still return country code.

```ruby
request.env['ipinfo'].country == 'US'
request.env['ipinfo'].country_name == 'United States'
```

### IP Address

`request.env['ipinfo'].ip_address` will return the an `IPAddr` object from the [Ruby Standard Library](https://ruby-doc.org/stdlib-2.5.1/libdoc/ipaddr/rdoc/IPAddr.html). `request.env['ipinfo'].ip` will still return a string.

```ruby
request.env['ipinfo'].ip == '104.175.221.247'
request.env['ipinfo'].ip_address == <IPAddr: IPv4:104.175.221.247/255.255.255.255>
```

### Longitude and Latitude

`request.env['ipinfo'].latitude` and `request.env['ipinfo'].longitude` will return latitude and longitude, respectively, as strings. `request.env['ipinfo'].loc` will still return a composite string of both values.

```ruby
request.env['ipinfo'].loc == '34.0293,-118.3570'
request.env['ipinfo'].latitude == '34.0293'
request.env['ipinfo'].longitude == '-118.3570'
```

### Accessing all properties

`request.env['ipinfo'].all` will return all details data as a hash.

```ruby
request.env['ipinfo'].all ==
{
:asn => {  :asn => 'AS20001',
           :domain => 'twcable.com',
           :name => 'Time Warner Cable Internet LLC',
           :route => '104.172.0.0/14',
           :type => 'isp'},
:city => 'Los Angeles',
:company => {  :domain => 'twcable.com',
               :name => 'Time Warner Cable Internet LLC',
               :type => 'isp'},
:country => 'US',
:country_name => 'United States',
:hostname => 'cpe-104-175-221-247.socal.res.rr.com',
:ip => '104.175.221.247',
:ip_address => <IPAddr: IPv4:104.175.221.247/255.255.255.255>,
:loc => '34.0293,-118.3570',
:latitude => '34.0293',
:longitude => '-118.3570',
:phone => '323',
:postal => '90016',
:region => 'California'
}
```

## Configuration

 In addition to the steps listed in the Installation section it is possible to configure the library with more detail. The following arguments are allowed and are described in detail below.

```ruby
config.middleware.use(IPinfoMiddleware, {
  token: "<your_token>",
  ttl: "",
  maxsize: "",
  cache: "",
  http_client: "",
  countries: "",
  filter: "",
})
```

### Authentication

The IPinfo library can be authenticated with your IPinfo API token, which is set in the environment file. It also works without an authentication token, but in a more limited capacity.

```ruby
config.middleware.use(IPinfoMiddleware, {token: '123456789abc'})
```

### Caching

In-memory caching of `details` data is provided by default via the [lrucache](https://www.rubydoc.info/gems/lrucache/0.1.4/LRUCache) gem. This uses an LRU (least recently used) cache with a TTL (time to live) by default. This means that values will be cached for the specified duration; if the cache's max size is reached, cache values will be invalidated as necessary, starting with the oldest cached value.

#### Modifying cache options

Cache behavior can be modified by setting the `ttl` and `maxsize` options.

- Default maximum cache size: 4096 (multiples of 2 are recommended to increase efficiency)
- Default TTL: 24 hours (in seconds)

```ruby
config.middleware.use(IPinfoMiddleware, {
  ttl: 30,
  maxsize: 40
})
```

#### Using a different cache

It's possible to use a custom cache by creating a child class of the [CacheInterface](https://github.com/ipinfo/ruby/blob/master/lib/ipinfo/cache/cache_interface.rb) class and passing this into the handler object with the `cache` keyword argument. FYI this is known as [the Strategy Pattern](https://sourcemaking.com/design_patterns/strategy).

```ruby
config.middleware.use(IPinfoMiddleware, {:cache => my_fancy_custom_class})
```

If a custom cache is used the `maxsize` and `ttl` settings will not be used.

### Using a different HTTP library

Ruby is notorious for having lots of HTTP libraries. While `Net::HTTP` is a reasonable default, you can set any other that [Faraday supports](https://github.com/lostisland/faraday/tree/29feeb92e3413d38ffc1fd3a3479bb48a0915730#faraday) if you prefer.

```ruby
config.middleware.use(IPinfoMiddleware, {:http_client => my_client})
```

Don't forget to bundle the custom HTTP library as well.

### Internationalization

When looking up an IP address, the response object includes a `Details.country_name` method which includes the country name based on American English. It is possible to return the country name in other languages by setting the countries setting when creating the IPinfo object.

The file must be a `.json` file with the following structure:

```ruby
{
 "BD": "Bangladesh",
 "BE": "Belgium",
 "BF": "Burkina Faso",
 "BG": "Bulgaria"
 ...
}
```

```ruby
config.middleware.use(IPinfoMiddleware, {:countries => <path_to_settings_file>})
```

### Filtering

By default, `ipinfo-rails` filters out requests that have `bot` or `spider` in the user-agent. Instead of looking up IP address data for these requests, the `request.env['ipinfo']` attribute is set to `nil`. This is to prevent you from unnecessarily using up requests on non-user traffic.

To set your own filtering rules, *thereby replacing the default filter*, you can set `:filter` to your own, custom callable function which satisfies the following rules:

- Accepts one request.
- Returns *True to filter out, False to allow lookup*

To use your own filter rules:

```ruby
config.middleware.use(IPinfoMiddleware, {
  filter: ->(request) {request.ip == '127.0.0.1'}
})
```

This simple lambda function will filter out requests coming from your local computer.

## Other Libraries

There are official IPinfo client libraries available for many languages including PHP, Go, Java, Ruby, and many popular frameworks such as Django, Rails and Laravel. There are also many third party libraries and integrations available for our API.

## About IPinfo

Founded in 2013, IPinfo prides itself on being the most reliable, accurate, and in-depth source of IP address data available anywhere. We process terabytes of data to produce our custom IP geolocation, company, carrier, privacy detection (VPN, proxy, Tor), hosted domains, and IP type data sets. Our API handles over 20 billion requests a month for 100,000 businesses and developers.

![image](https://avatars3.githubusercontent.com/u/15721521?s=128&u=7bb7dde5c4991335fb234e68a30971944abc6bf3&v=4)
