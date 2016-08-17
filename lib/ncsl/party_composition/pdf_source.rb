require 'open-uri'
require 'csv'
require 'pry'

module Ncsl
  module PartyComposition
    class PdfSource
      COLUMN_HEADERS = [
        "state", "total_seats",
        "total_senate", "senate_dem", "senate_gop", "senate_other",
        "total_house", "house_dem", "house_gop", "house_other",
        "legis_control","gov_party", "state_control"
      ] # order matters

      PARTIES = [
        {:abbrevs => ["Dem"], :name => "Democrat"},
        {:abbrevs => ["Rep"], :name => "Republican"},
        {:abbrevs => ["Ind"], :name => "Independent"},
        {:abbrevs => ["C", "Cov"], :name => "Covenant"},
        {:abbrevs => ["PDP"], :name => "Popular Democratic"},
        {:abbrevs => ["NPP"], :name => "New Progressive"}
      ]
      PARTY_ABBREVIATIONS = PARTIES.map{ |party| party[:abbrevs] }.flatten
      STATE_CONTROL_VALUES = ["Divided", "N/A"].concat(PARTY_ABBREVIATIONS)
      GOVERNOR_PARTY_VALUES = ["N/A", "NULL"].concat(PARTY_ABBREVIATIONS)
      LEGISLATURE_CONTROL_VALUES = ["Split", "N/A"].concat(PARTY_ABBREVIATIONS)

      DATA_DIR = File.expand_path("../../../../data/party_composition", __FILE__)
      CELL_DELIMETER = "   "
      DOUBLE_CELL_DELIMETER = "                   "
      #DOUBLE_CELL_DELIMETER_UNICAMERAL = "               "

      def self.all
        Ncsl::PartyComposition::PDF_SOURCES.map{|source| new(source) }
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

      def file_name
        "#{year}_party_compositions"
      end

      def pdf_path
        File.join(DATA_DIR, "pdf", "#{file_name}.pdf")
      end

      def txt_path
        File.join(DATA_DIR, "txt", "#{file_name}.txt")
      end

      def csv_path
        File.join(DATA_DIR, "csv", "#{file_name}.csv")
      end

      def normalized_csv_path
        File.join(DATA_DIR, "csv", "#{file_name}_normalized.csv")
      end

      def json_path
        File.join(DATA_DIR, "json", "#{file_name}.json")
      end

      def download
        puts "Downloading to #{pdf_path}"
        File.open(pdf_path, "wb") do |file|
          open(url, "rb") do |source_file|
            file.write(source_file.read)
          end
        end
      end

      def convert_to_txt
        puts "Converting to #{txt_path}"
        system "pdftotext #{pdf_path} #{txt_path} -layout"
      end

      def txt_lines
        lines = IO.read(txt_path).split("\n")
        lines -= ["\f"]
        lines -= [""]
        lines.reject!{|line| line.include?("Total") }
        lines.reject!{|line| line.include?(year.to_s) }
        lines.reject!{|line| line.include?("Control") }
        lines.reject!{|line| line.include?("Total") }
        lines.reject!{|line| line.include?("Territories") }
        lines.reject!{|line| line.include?("Abbreviations") }
        lines.reject!{|line| line.include?("Notes:") }

        # get rid of all lines between wyoming and american samoa
        wyoming_line = lines.find{|line| line.include?("Wyoming") }
        samoa_line = lines.find{|line| line.include?("American Samoa") }
        indices_of_lines_to_remove = (lines.index(wyoming_line) + 1 .. lines.index(samoa_line) - 1).to_a
        number_of_lines_to_remove = indices_of_lines_to_remove.count
        lines_to_remove = lines.slice(indices_of_lines_to_remove.first, number_of_lines_to_remove)
        lines -= lines_to_remove
        raise LineCountError.new(lines.count) unless lines.count == 56

        # workaround for 2013/2014: Florida, Georgia, Idaho, Indiana, Kansas, Louisiana, Michigan, Wisconsin ...
        lines.map!{|l| l.gsub(" e ", CELL_DELIMETER)}

        # workaround for 2014 new york and washington coalitions...
        #lines.map!{|l| l.gsub("Dem*", "Dem ")}

        # workaround for unicameral legislatures ...
        #lines.map! do |l|
        #  if l.include?("Unicameral")
        #    l.gsub("Unicameral", 0)
        #    l.gsub(DOUBLE_CELL_DELIMETER_UNICAMERAL, "#{CELL_DELIMETER}0#{CELL_DELIMETER}")
        #  else
        #    l
        #  end
        #end

        # workaround for 2015 and 2016 where blank values should be zeros ...
        if [2015,2016].include?(year)
          lines.map!{|l| l.gsub( l.slice(0,25) , "#{l.slice(0,25).strip}#{CELL_DELIMETER}") }
          lines.map!{|l| l.gsub(DOUBLE_CELL_DELIMETER, "#{CELL_DELIMETER}0#{CELL_DELIMETER}") }
        end

        # workaround for 2016 Louisiana where "Rep Rep Dem" should be "Rep    Dem" ...
        if year == 2016
          lines.map!{|l| l.include?("Louisiana") ? l.gsub("Rep Rep Dem", "Rep#{CELL_DELIMETER}Dem") : l }
        end

        return lines
      end

      def convert_txt_to_csv
        puts "Converting to #{csv_path}"
        CSV.open(csv_path, "w") do |csv|
          csv << COLUMN_HEADERS
          txt_lines.each do |line|
            begin
              next if line.include?("Non-partisan")
              next if line.include?("Unicameral")
              cells = line.split(CELL_DELIMETER).map{|l| l.strip } - [""]
              puts "... #{cells.first}"
              cells = cells.insert(-2, "NULL") if year == 2015 && ["Mariana Islands"].include?(cells.first) # workaround for null gov_party values
              cells[11].gsub!("0", "NULL") if year == 2016 && ["Mariana Islands"].include?(cells.first) # workaround for null gov_party values
              raise CellCountError.new(line) unless cells.count == 13
              csv << cells
            rescue CellCountError => e
              binding.pry
            end
          end
        end
      end

      class LineCountError < StandardError ; end
      class CellCountError < StandardError ; end

      class LegislatureControlError < StandardError ; end
      class GovernorControlError < StandardError ; end
      class StateControlError < StandardError ; end
    end
  end
end
