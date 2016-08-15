require 'open-uri'

SOURCES = [
  {:year => 2009, :url => "http://www.ncsl.org/documents/statevote/legiscontrol_2009.pdf"},
  {:year => 2010, :url => "http://www.ncsl.org/documents/statevote/LegisControl_2010.pdf"},
  {:year => 2011, :url => "http://www.ncsl.org/documents/statevote/LegisControl_2011.pdf"},
  {:year => 2012, :url => "http://www.ncsl.org/documents/statevote/legiscontrol_2012.pdf"},
  {:year => 2013, :url => "http://www.ncsl.org/documents/statevote/legiscontrol_2013.pdf"},
  {:year => 2014, :url => "http://www.ncsl.org/documents/statevote/legiscontrol_2014.pdf"},
  {:year => 2015, :url => "http://www.ncsl.org/Portals/1/Documents/Elections/Legis_Control_2015_Feb4_11am.pdf"},
  {:year => 2016, :url => "http://www.ncsl.org/Portals/1/Documents/Elections/Legis_Control_2016_Apr20.pdf"}
]

#
# DOWNLOAD PDF
#

def self.parse(source)
  file_path = File.expand_path("../../pdf/control/#{source[:year]}.pdf", __FILE__)
  puts "Downloading to #{file_path}"
  File.open(file_path, "wb") do |file|
    open(source[:url], "rb") do |source_file|
      file.write(source_file.read)
    end
  end
end

SOURCES.each do |source|
  parse(source)
end
