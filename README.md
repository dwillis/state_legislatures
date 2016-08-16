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

Download PDF files:

```` sh
ruby script/download_pdf.rb
````

Convert PDF files to TXT:

```` sh
ruby script/convert_pdf_to_txt.rb
````

Convert TXT files to CSV:

```` sh
ruby script/convert_txt_to_csv.rb
````

Convert TXT files to JSON:

```` sh
ruby script/convert_txt_to_json.rb
````

Normalize CSV files:

```` sh
ruby script/normalize_csv.rb
````
