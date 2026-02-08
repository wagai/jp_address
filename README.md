[日本語版はこちら](README.ja.md)

# Basho

A Ruby gem for working with Japanese address data — prefectures, cities, postal codes, and regions — in a unified interface.

## Why Basho

Dealing with Japanese addresses is tedious.

- Looking up an address from a postal code requires parsing CSVs and loading them into a database
- Maintaining master data for prefectures and cities means writing migrations
- Postal code auto-fill and prefecture-city cascading selects end up being rewritten every project
- Existing gems are tightly coupled to Rails, have outdated data, or lack Hotwire support

Basho solves all of these.

- **No DB migrations** — All data is bundled as JSON. Just `gem install` and go
- **ActiveRecord integration** — `include Basho` + a one-line macro for automatic postal code to address resolution on save
- **Hotwire-ready** — Built-in Rails Engine with postal code auto-fill and cascade select
- **Lightweight** — Immutable models via `Data.define`, lazy loading, zero external dependencies

## Supported Versions

- Ruby 3.2 / 3.3 / 3.4 / 4.0

## Installation

```ruby
# Gemfile
gem "basho"
```

```bash
bundle install
```

## Quick Start

### Look up an address from a postal code

```ruby
postal = Basho::PostalCode.find("154-0011").first
postal.prefecture_name  # => "東京都"
postal.city_name        # => "世田谷区"
postal.town             # => "上馬"
```

### Auto-save address columns from a postal code

```ruby
class User < ApplicationRecord
  include Basho
  basho_postal :postal_code,
    prefecture: :pref_name,
    city: :city_name,
    town: :town_name
end

user = User.new(postal_code: "154-0011")
user.save
user.pref_name  # => "東京都"
user.city_name  # => "世田谷区"
user.town_name  # => "上馬"
```

### Search prefectures and cities

```ruby
Basho::Prefecture.find(13).name           # => "東京都"
Basho::Prefecture.where(region: "関東")    # => 7 results
Basho::City.find("131016").name            # => "千代田区"
```

## Usage

### Prefecture

```ruby
Basho::Prefecture.find(13)             # Find by code
Basho::Prefecture.find(name: "東京都")  # Find by name
Basho::Prefecture.all                   # All 47 prefectures
Basho::Prefecture.where(region: "関東") # Filter by region

pref = Basho::Prefecture.find(13)
pref.code          # => 13
pref.name          # => "東京都"
pref.name_en       # => "Tokyo"
pref.name_kana     # => "トウキョウト"
pref.name_hiragana # => "とうきょうと"
pref.type          # => "都"
pref.region        # => Region
pref.cities        # => Array<City>
pref.capital       # => City (prefectural capital)
```

### City

```ruby
Basho::City.find("131016")              # Find by municipality code
Basho::City.where(prefecture_code: 13)  # Filter by prefecture
Basho::City.valid_code?("131016")       # Validate check digit

city = Basho::City.find("131016")
city.code             # => "131016"
city.prefecture_code  # => 13
city.name             # => "千代田区"
city.name_kana        # => "チヨダク"
city.capital?         # => false
city.prefecture       # => Prefecture
```

### PostalCode

```ruby
results = Basho::PostalCode.find("154-0011")  # Always returns an Array
results = Basho::PostalCode.find("1540011")    # Hyphenless format also works

postal = results.first
postal.code              # => "1540011"
postal.formatted_code    # => "154-0011"
postal.prefecture_code   # => 13
postal.prefecture_name   # => "東京都"
postal.city_name         # => "世田谷区"
postal.town              # => "上馬"
postal.prefecture        # => Prefecture
```

### Region

```ruby
Basho::Region.all                # 8 regions
Basho::Region.find("関東")       # Find by name

region = Basho::Region.find("関東")
region.name             # => "関東"
region.name_en          # => "Kanto"
region.prefectures      # => Array<Prefecture>
region.prefecture_codes # => [8, 9, 10, 11, 12, 13, 14]
```

## ActiveRecord Integration

### Look up prefecture and city from a municipality code

```ruby
class Shop < ApplicationRecord
  include Basho
  basho :local_gov_code
end

shop.prefecture   # => Prefecture
shop.city         # => City
shop.full_address # => "東京都千代田区"
```

### Get an address string from a postal code

```ruby
class Shop < ApplicationRecord
  include Basho
  basho_postal :postal_code
end

shop.postal_address # => "東京都世田谷区上馬"
```

### Auto-save address columns from a postal code

When you pass mapping options to `basho_postal`, it registers a `before_save` callback that auto-fills address columns from the postal code.

```ruby
class User < ApplicationRecord
  include Basho
  basho_postal :postal_code,
    prefecture: :pref_name,
    city: :city_name,
    town: :town_name
end
```

- Resolution runs only when `postal_code` changes
- Partial mappings are supported (e.g. `prefecture:` only)
- Without options, only the `postal_address` method is defined (backward compatible)

## Hotwire Engine

A built-in Rails Engine providing postal code auto-fill and prefecture-city cascade select via Turbo Frame + Stimulus. No custom controllers needed.

### Setup

```ruby
# config/application.rb
require "basho/engine"
```

```ruby
# config/routes.rb
mount Basho::Engine, at: "/basho"
```

### Postal Code Auto-fill

Automatically fills in prefecture, city, and town fields when a postal code is entered.

```erb
<%= form_with(model: @shop) do |f| %>
  <div data-controller="basho--auto-fill"
       data-basho--auto-fill-url-value="<%= basho.postal_code_lookup_path %>">

    <%= f.text_field :postal_code,
          data: { action: "input->basho--auto-fill#lookup",
                  "basho--auto-fill-target": "input" } %>

    <turbo-frame id="basho-result"
                 data-basho--auto-fill-target="frame"></turbo-frame>

    <%= f.text_field :prefecture,
          data: { "basho--auto-fill-target": "prefecture" } %>
    <%= f.text_field :city,
          data: { "basho--auto-fill-target": "city" } %>
    <%= f.text_field :town,
          data: { "basho--auto-fill-target": "town" } %>
  </div>
<% end %>
```

1. User enters a 7-digit postal code
2. After a 300ms debounce, a Turbo Frame request is sent to the server
3. Stimulus auto-fills the prefecture, city, and town fields

### Prefecture-City Cascade Select

Selecting a prefecture dynamically loads the corresponding cities via JSON API.

```erb
<%= form_with(model: @shop) do |f| %>
  <div data-controller="basho--cascade-select"
       data-basho--cascade-select-prefectures-url-value="<%= basho.prefectures_path %>"
       data-basho--cascade-select-cities-url-template-value="<%= basho.cities_prefecture_path(':code') %>">

    <select data-basho--cascade-select-target="prefecture"
            data-action="change->basho--cascade-select#prefectureChanged">
      <option value="">Select prefecture</option>
    </select>

    <select data-basho--cascade-select-target="city">
      <option value="">Select city</option>
    </select>
  </div>
<% end %>
```

Use the `basho_cascade_data` helper for concise data attributes.

```erb
<div <%= tag.attributes(data: basho_cascade_data) %>>
  ...
</div>
```

1. On page load, if the prefecture select is empty, all 47 prefectures are fetched from the API
2. Selecting a prefecture rebuilds the city select from the API
3. Changing the prefecture resets and re-fetches the city select

### JSON API Endpoints

Mounting the Engine exposes the following endpoints.

```
GET /basho/prefectures           # => [{"code":1,"name":"北海道"}, ...]
GET /basho/prefectures/13/cities  # => [{"code":"131016","name":"千代田区"}, ...]
GET /basho/postal_codes/lookup?code=1540011  # => Turbo Frame HTML
```

## Without the Engine

You can skip the Engine and build your own endpoints using `PostalCode.find`.

```ruby
# JSON API
class PostalCodesController < ApplicationController
  def lookup
    results = Basho::PostalCode.find(params[:code])

    render json: results.map { |r|
      { prefecture: r.prefecture_name, city: r.city_name, town: r.town }
    }
  end
end
```

## Data Sources

| Data | Source | Update Frequency |
|------|--------|-----------------|
| Prefectures | Ministry of Internal Affairs, JIS X 0401 | Rarely changes |
| Cities | Ministry of Internal Affairs, Local Government Codes | A few times per year |
| Postal codes | Japan Post KEN_ALL.csv | Monthly (auto-updated via GitHub Actions) |
| Regions | 8 regions (hardcoded) | Never changes |

## Development

```bash
git clone https://github.com/wagai/basho.git
cd basho
bin/setup
bundle exec rspec
```

## License

MIT License
