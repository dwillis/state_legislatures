## State Legislatures

This repository contains summary data about state legislative bodies, beginning with [partisan composition](http://www.ncsl.org/research/about-state-legislatures/partisan-composition.aspx) and [women in state legislatures](http://www.ncsl.org/legislators-staff/legislators/womens-legislative-network/women-in-state-legislatures-for-2013.aspx) as compiled by the National Conference of State Legislatures covering 2009-2016.

### Contributing

#### Prerequisites

Install homebrew, git, ruby and bundler.

Install `pdftotext` command line utility. If on a Mac, install `pdftotext` by installing `poppler`:

```` sh
brew install poppler
````

Download the source code and install package dependencies:

```` sh
git clone git@github.com:dwillis/state_legislatures.git
cd state_legislatures
bundle install
````

#### Conversion Process

Download party composition pdf files and convert to machine-readable formats:

```` sh
ruby script/etl_party_compositions.rb
````

Scrape gender composition html tables and convert to machine-readable formats:

```` sh
ruby script/etl_gender_compositions.rb
````
