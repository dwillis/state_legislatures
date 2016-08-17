require 'open-uri'
require 'csv'
require 'pry'

module Ncsl
  module PartyComposition
    class PdfSource
      DATA_DIR = File.expand_path("../../../../data/party_composition", __FILE__)

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
        lines.map!{|l| l.gsub(" e ", "   ")}

        # workaround for 2014 new york and washington coalitions...
        lines.map!{|l| l.gsub("Dem*", "Dem ")}

        # workaround for 2016 Louisiana where "Rep Rep Dem" should be "Rep    Dem" ...
        lines.map!{|line| line.include?("Louisiana") && line.include?("Rep Rep Dem") ? line.gsub("Rep Rep Dem", "Rep     Dem") : line }

        #if year == 2016
        #  lines.map!{|line| line.include?("Louisiana") ? line.gsub("Rep Rep Dem", "Rep     Dem") : line }
        #end

        lines.map!{|line| "  " + line + "  " } # give first and last cells some padding to pass subsequent whitespace validations
        return lines
      end

      def convert_txt_to_csv
        puts "Converting to #{csv_path}"
        CSV.open(csv_path, "w") do |csv|
          csv << COLUMN_HEADERS
          txt_lines.each do |line|
            state = line.slice(0,24)
            puts "  + #{state.strip}"

            unicameral = line.include?("Unicameral")
            nonpartisan = line.include?("Non Partisan")
            next if unicameral == true || nonpartisan == true # skip for now

            total_seats = line.slice(23,7)

            case year
            when 2009,2010,2011,2012,2013
              legis_control = line.slice(121,14)
              gov_party = line.slice(135,11)
              state_control = line.slice(148,20)
            when 2014
              legis_control = line.slice(121,14)
              legis_control = line.slice(125,15) if state.strip == "Mariana Islands"
              gov_party = line.slice(135,11)
              gov_party = line.slice(136,11) if state.strip == "Mariana Islands"
              state_control = line.slice(148,20)
            when 2015
              legis_control = line.slice(123,17) # line.slice(121,17)
              gov_party = line.slice(137,11)
              gov_party = line.slice(138,11) if state.strip == "Mariana Islands"
              gov_party = "NULL" if ["Guam","Mariana Islands", "Virgin Islands"].include?(state.strip) # workaround for null values
              state_control = line.slice(148,20)
            when 2016
              legis_control = line.slice(123,14) # line.slice(121,14)
              legis_control = line.slice(128,14) if state.strip == "Mariana Islands"
              gov_party = line.slice(135,8) # line.slice(135,5)
              gov_party = line.slice(142,8) if ["American Samoa", "Puerto Rico"].include?(state.strip)
              gov_party = "NULL" if ["Guam","Mariana Islands", "Virgin Islands"].include?(state.strip) # workaround for null values
              state_control = line.slice(142,20)
              state_control = line.slice(142,30) if state.strip == "Mariana Islands"
            end

            #raise LegislatureControlError.new("#{legis_control} -- #{line}") unless LEGISLATURE_CONTROL_VALUES.include?(legis_control.strip)
            binding.pry unless LEGISLATURE_CONTROL_VALUES.include?(legis_control.strip)
            #raise GovernorControlError.new("#{gov_party} -- #{line}") unless GOVERNOR_PARTY_VALUES.include?(gov_party.strip)
            binding.pry unless GOVERNOR_PARTY_VALUES.include?(gov_party.strip)
            #raise StateControlError.new("#{state_control} -- #{line}") unless STATE_CONTROL_VALUES.include?(state_control.strip)
            binding.pry unless STATE_CONTROL_VALUES.include?(state_control.strip)



            total_senate = line.slice(33,7)
            senate_dem = line.slice(45,6)
            senate_rep = line.slice(56,6)
            senate_other = line.slice(66,6)

            total_house = line.slice(76,9)
            house_dem = line.slice(88,8)
            house_rep = line.slice(98,7)
            house_other = line.slice(107,10)

            cells = [
              state, total_seats,
              total_senate, senate_dem, senate_rep, senate_other,
              total_house, house_dem, house_rep, house_other,
              legis_control, gov_party, state_control
            ] # order matters
            cells.each do |cell|
              leading_spaces , trailing_spaces = cell.split(cell.strip).map(&:size)
              #raise CellPaddingError.new(cell) unless !leading_spaces.nil? && !trailing_spaces.nil?
              #raise CellPaddingError.new(cell) unless leading_spaces > 1 && trailing_spaces > 1
              #binding.pry unless !leading_spaces.nil? && !trailing_spaces.nil?
              #binding.pry unless leading_spaces > 1 && trailing_spaces > 1
            end
            cells.map!{|cell| cell.to_s.strip } # remove white-space before writing to file
            csv << cells
          end
        end
      end

      class LineCountError < StandardError ; end
      class CellPaddingError < StandardError ; end

      class LegislatureControlError < StandardError ; end
      class GovernorControlError < StandardError ; end
      class StateControlError < StandardError ; end
    end
  end
end
