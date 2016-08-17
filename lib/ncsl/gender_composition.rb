module Ncsl
  # Describes the gender composition of state legislative offices.
  # http://www.ncsl.org/legislators-staff/legislators/womens-legislative-network.aspx
  module GenderComposition
    URL_BASE = "http://www.ncsl.org/legislators-staff/legislators/womens-legislative-network/women-in-state-legislatures"
    URL_SOURCES = [
      {:year => 2009, :url => "#{URL_SOURCES}-2009.aspx"},
      {:year => 2010, :url => "#{URL_BASE}-2010.aspx"},
      {:year => 2011, :url => "#{URL_BASE}-2011.aspx"},
      {:year => 2012, :url => "#{URL_BASE}-2012.aspx"},
      {:year => 2013, :url => "#{URL_BASE}-for-2013.aspx"},
      {:year => 2014, :url => "#{URL_BASE}-for-2014.aspx"},
      {:year => 2015, :url => "#{URL_BASE}-for-2015.aspx"},
      {:year => 2016, :url => "#{URL_BASE}-for-2016.aspx"}
    ]
  end
end
