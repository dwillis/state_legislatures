require 'open-uri'
require 'csv'
require 'pry'

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

    CELL_DELIMETER = "   "
    DOUBLE_CELL_DELIMETER = "                   "

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

    def txt_file_path
      File.expand_path("../../../txt/control/#{year}.txt", __FILE__)
    end

    def csv_file_path
      File.expand_path("../../../csv/control/#{year}.csv", __FILE__)
    end

    def download
      puts "Downloading to #{file_path}"
      File.open(file_path, "wb") do |file|
        open(url, "rb") do |source_file|
          file.write(source_file.read)
        end
      end
    end

    def convert_to_txt
      puts "Converting to #{txt_file_path}"
      system "pdftotext #{file_path} #{txt_file_path} -layout"
    end

    def txt_lines
      lines = IO.read(txt_file_path).split("\n") - ["\f"]
      lines.reject!{|line|
        line.include?("Total") ||
        line.include?(year.to_s) ||
        line.include?("Control") ||
        line.include?("Unicameral") #todo: handle these
      }
      lines -= [""]
      #
      # workaround for 2013/2014: Florida, Georgia, Idaho, Indiana, Kansas, Louisiana, Michigan, Wisconsin ...
      #
      lines.map!{|l| l.gsub(" e ", CELL_DELIMETER)}
      #
      # workaround for 2015 and 2016 bugs (blank values should be zeros) ...
      #
      if [2015,2016].include?(year)
        lines.map!{|line| line.gsub( line.slice(0,25) , "#{line.slice(0,25).strip}#{CELL_DELIMETER}") }
        lines.map!{|line| line.gsub(DOUBLE_CELL_DELIMETER, "#{CELL_DELIMETER}0#{CELL_DELIMETER}") }
      end
      #
      # workaround for 2016 Louisiana bug where "Rep Rep Dem" should be "Rep    Dem" ...
      #
      if year == 2016
        lines.map!{|line| line.include?("Louisiana") ? line.gsub("Rep Rep Dem", "Rep#{CELL_DELIMETER}Dem") : line }
      end
      return lines
    end

    def convert_txt_to_csv
      puts "Converting to #{csv_file_path}"
      parse_next = true
      CSV.open(csv_file_path, "w") do |csv|
        txt_lines.each do |line|
          cells = line.split(CELL_DELIMETER).map{|l| l.strip } - [""]

          parse_next = false if line.include?("Wyoming")
          if parse_next == true
            puts "... #{cells.first}"
            binding.pry unless cells.count == 13 # raise CellCountError.new(line) unless cells.count == 13
            #csv << line
          end
        end
      end
    end

    class CellCountError < StandardError ; end
  end
end
