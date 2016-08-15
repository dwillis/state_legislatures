require 'open-uri'

module Ncsl
  class PdfSource
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

    def self.all
      SOURCES.map{|source| new(source) }
    end

    def initialize(source)
      @url = source[:url]
      @year = source[:year]
    end

    def url
      @url
    end

    def year
      @year
    end

    def file_path
      File.expand_path("../../../pdf/control/#{year}.pdf", __FILE__)
    end

    def download
      puts "Downloading to #{file_path}"
      File.open(file_path, "wb") do |file|
        open(url, "rb") do |source_file|
          file.write(source_file.read)
        end
      end
    end

    def txt_file_path
      File.expand_path("../../../txt/control/#{year}.txt", __FILE__)
    end

    def convert_to_txt
      puts "Converting to #{txt_file_path}"
      system "pdftotext #{file_path} #{txt_file_path} -layout"
    end
  end
end
