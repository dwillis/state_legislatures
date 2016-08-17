require 'open-uri'
require 'csv'
require 'pry'
require 'json'

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
      CONTROL_BY_COALITION_MARKER = "*"

      CELL_DELIMETER = "   "
      BLANK_CELL_REPLACEMENT_VALUE = "#{CELL_DELIMETER}0#{CELL_DELIMETER}"
      DOUBLE_CELL_DELIMETER = "                   "
      DOUBLE_CELL_DELIMETER_UNICAMERAL = "            "

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
        # remove line(s) between wyoming and american samoa ...
        wyoming_line = lines.find{|line| line.include?("Wyoming") }
        samoa_line = lines.find{|line| line.include?("American Samoa") }
        indices_of_lines_to_remove = (lines.index(wyoming_line) + 1 .. lines.index(samoa_line) - 1).to_a
        number_of_lines_to_remove = indices_of_lines_to_remove.count
        lines_to_remove = lines.slice(indices_of_lines_to_remove.first, number_of_lines_to_remove)
        lines -= lines_to_remove

        raise LineCountError.new(lines.count) unless lines.count == 56
        return lines
      end

      def parse_line(line)
        parsed_line = line
        parsed_line.gsub!(" e ", CELL_DELIMETER) # workaround for erroneous letter in 2013/2014: Florida, Georgia, Idaho, Indiana, Kansas, Louisiana, Michigan, Wisconsin ...

        if parsed_line.include?("Unicameral") # workaround for unicameral legislature blank values ...
          parsed_line.gsub!( parsed_line.slice(0,24) , "#{parsed_line.slice(0,24).strip}#{CELL_DELIMETER}")
          if [2015,2016].include?(year) && (parsed_line.include?("District of Columbia") || parsed_line.include?("Guam") )
            parsed_line.gsub!("      Unicameral","UNI")
            parsed_line.gsub!(DOUBLE_CELL_DELIMETER_UNICAMERAL, BLANK_CELL_REPLACEMENT_VALUE )
            parsed_line.gsub!("UNI","Unicameral")
          else
            parsed_line.gsub!(DOUBLE_CELL_DELIMETER_UNICAMERAL, BLANK_CELL_REPLACEMENT_VALUE)
          end
          parsed_line.gsub!(parsed_line[-15,15], parsed_line[-15,15].gsub("0","")) # remove erroneously-added 0 between last two control values if necessary (for huge space in District of Columbia lines)
        elsif [2015,2016].include?(year) # workaround for 2015 and 2016 where blank values should be zeros ...
          parsed_line.gsub!( parsed_line.slice(0,25) , "#{parsed_line.slice(0,25).strip}#{CELL_DELIMETER}")
          parsed_line.gsub!(DOUBLE_CELL_DELIMETER, BLANK_CELL_REPLACEMENT_VALUE)
        end

        parsed_line.gsub!("Rep Rep Dem", "Rep#{CELL_DELIMETER}Dem") if year == 2016 && parsed_line.include?("Louisiana") # workaround for 2016 Louisiana where "Rep Rep Dem" should be "Rep    Dem" ...

        return parsed_line
      end

      def convert_txt_to_csv
        puts "Converting to #{csv_path}"
        CSV.open(csv_path, "w") do |csv|
          csv << COLUMN_HEADERS
          txt_lines.each do |txt_line|
            next if txt_line.include?("Non-partisan")
            line = parse_line(txt_line)
            cells = line.split(CELL_DELIMETER).map{|l| l.strip } - [""]
            puts "... #{cells.first}"
            cells = cells.insert(-2, "NULL") if year == 2015 && ["Mariana Islands"].include?(cells.first) # workaround for null gov_party values
            cells[11].gsub!("0", "NULL") #if year == 2016 && ["Mariana Islands"].include?(cells.first) # workaround for "0" gov_party values which resulted from the delimeter conversion process
            raise CellCountError unless cells.count == 13
            raise LegislatureControlError unless LEGISLATURE_CONTROL_VALUES.include?(cells[10].gsub(CONTROL_BY_COALITION_MARKER,""))
            raise GovernorPartyError unless GOVERNOR_PARTY_VALUES.include?(cells[11])
            raise StateControlError unless STATE_CONTROL_VALUES.include?(cells[12].gsub(CONTROL_BY_COALITION_MARKER,""))
            csv << cells
          end
        end
      end

      # @example "1, 1v"
      # @return ["1", "1v"]
      def others(others_str)
        others_str.split(",")
      end

      # @return 2
      def other_seats(others_str)
        others(others_str).map{|str| str.gsub("v","").gsub("u","").to_i }.inject(0){|sum,x| sum + x } #> 3 or 2
      end

      # @return 1
      def vacant_seats(others_str)
        vacancies_str = others(others_str).find{|o| o.include?("v") }
        vacancies_str.nil? ? 0 : vacancies_str.gsub("v","").to_i
      end

      # @return 1
      def remaining_other_seats(others_str)
        other_seats(others_str) - vacant_seats(others_str)
      end

      def senate_composition(row)
        {
          :dem => row[:senate_dem].to_i,
          :rep => row[:senate_gop].to_i,
          :vacant => vacant_seats(row[:senate_other]),
          :other => remaining_other_seats(row[:senate_other])
        }
      end

      def house_composition(row)
        {
          :dem => row[:house_dem].to_i,
          :rep => row[:house_gop].to_i,
          :vacant => vacant_seats(row[:house_other]),
          :other => remaining_other_seats(row[:house_other])
        }
      end

      def parse_chamber(row, chamber_name)
        case chamber_name
        when "Unicameral","Senate"
          {
            :name => chamber_name,
            :seats => row[:total_senate].to_i,
            :composition => senate_composition(row)
          }
        when "House"
          {
            :name => chamber_name,
            :seats => row[:total_house].to_i,
            :composition => house_composition(row)
          }
        end
      end

      def parse_chambers(row)
        if row.to_s.include?("Unicameral")
          chambers = [
            parse_chamber(row, "Unicameral")
          ]
        else
          chambers = [
            parse_chamber(row, "House"),
            parse_chamber(row, "Senate")
          ]
        end
      end

      def convert_csv_to_json
        puts "Converting to #{json_path}"
        obj = {:year => year, :states => []}
        CSV.foreach(csv_path, :headers => true, :header_converters => :symbol) do |row|
          puts "... #{row[:state]}"
          state = {
            :name => row[:state],
            :control => row[:state_control],
            :governor_party => row[:gov_party],
            :legislature_control => row[:legis_control],
            :legislature_seats => row[:total_seats].to_i,
            :legislature_chambers => parse_chambers(row)
          }
          #binding.pry
          #raise LegilsatureSeatCountError unless state[:legislature_seats] == state[:legislature_chambers].map{|chamber| chamber[:seats]}
          #state[:legislature_chambers].each do |chamber|
          #  raise ChamberSeatCountError unless
          #end
          obj[:states] << state
        end
        File.write(json_path, JSON.pretty_generate(obj))
      end

      class LineCountError < StandardError ; end
      class CellCountError < StandardError ; end

      class LegislatureControlError < StandardError ; end
      class GovernorPartyError < StandardError ; end
      class StateControlError < StandardError ; end

      class LegislatureSeatCountError < StandardError ; end
      class ChamberSeatCountError < StandardError ; end
    end
  end
end
