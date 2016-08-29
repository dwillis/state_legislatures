require 'nokogiri'
require 'httparty'
require 'active_support/core_ext/object' # enable .try method

module Ncsl
  module GenderComposition
    class HtmlSource
      COLUMN_HEADERS = [
        {:html_header=> "State", :csv_header => "state"},
        {:html_header => "Number of Women Legislators in the House / Assembly", :csv_header => "house_women"},
        {:html_header => "Number of Women Legislators in the Senate", :csv_header => "senate_women"},
        {:html_header => "Total Number of Women Legislators", :csv_header => "total_women"},
        {:html_header => "Total Seats in the Legislature", :csv_header => "total_seats"},
        {:html_header => "Percentage of Women in the Legislature", :csv_header => "percentage_women"},
      ]
      HTML_COLUMN_HEADERS = COLUMN_HEADERS.map{|h| h[:html_header]}
      CSV_COLUMN_HEADERS = COLUMN_HEADERS.map{|h| h[:csv_header]}

      DATA_DIR = File.expand_path("../../../../data/gender_composition", __FILE__)

      def self.all
        Ncsl::GenderComposition::URL_SOURCES.map{|source| new(source) }
      end

      def initialize(source)
        @url = source[:url]
        @year = source[:year]
      end

      def html_path
        File.join(DATA_DIR, "html", "#{@year}.html")
      end

      def csv_path
        File.join(DATA_DIR, "csv", "#{@year}.csv")
      end

      def json_path
        File.join(DATA_DIR, "json", "#{@year}.json")
      end

      def download
        unless File.exists?(html_path)
          puts "Extracting #{@year} data from #{@url}"
          response = HTTParty.get(@url) # HTTParty handles redirects
          puts "Writing to #{html_path}"
          File.open(html_path, "wb") do |file|
            file.write(response.body)
          end
        else
          puts "Detected local data for #{@year} at #{html_path}"
        end
      end

      def convert_to_csv
        puts "Converting #{@year} html to csv"
        doc = File.open(html_path){|file| Nokogiri::HTML(file)}
        tables = doc.xpath("//table")
        table = tables.find{|table| table.attribute("summary").try(:value) == "State-by-state data about women in legislatures." } # thanks for this table identifier!
        raise UnknownTableError unless table.present?

        rows = table.css("tr")
        rows = rows.reject{|row| row.children.count == 1 } # exclude pre-header row ... #(Element:0x3fede1e81c8c { name = "tr", children = [ #(Text "\n\t\t")] })

        CSV.open(csv_path, "w") do |csv|
          csv << CSV_COLUMN_HEADERS
          rows.each_with_index do |row, i|
            tds = row.children.select{|child| child.name == "td" } # exclude erroneous Nokogiri::XML::Text elements
            next if tds.empty? # skip empty pre-header row
            raise UnexpectedCellCount unless tds.count == 6

            values = []
            tds.each do |td|
              if td.children.map{|child| child.name}.include?("div")
                div = td.children.find{|child| child.name == "div"}
                div_child_names = div.children.map{|child| child.name}
                if div_child_names.include?("b") # headers are bold
                  b = div.children.find{|child| child.name == "b"}
                  raise UnexpectedCell unless b.children.count == 1
                  values << b.text.strip
                elsif div_child_names.include?("text")
                  raise UnexpectedCell unless div.children.count == 1
                  values << div.text.strip
                end
              elsif td.children.count == 1
                values << td.text.strip
              else
                raise UnexpectedCell
              end
            end

            values.each do |val|
              invalid_character_indices = []
              val.each_char.with_index do |char, i|
                invalid_character_indices << i unless char == char.encode(Encoding::UTF_8, Encoding::ISO_8859_1,:invalid => :replace, :undef => :replace, :replace => "")
              end
              invalid_character_indices.each do |i|
                val.delete!(val[i])
              end
            end # remove characters with bad encoding that look like blank strings but aren't

            # puts "#{@year} -- #{i} -- #{values}"
            next if values == HTML_COLUMN_HEADERS # skip header row
            next if values.include?("TOTAL") # skip totals row
            next if values.map{|v| v.blank?}.include?(true) # skip blank rows like [" ", " ", " ", " ", " ", " "]
            next unless values.any?
            next unless values.count == 6
            begin
              raise UnexpectedStateName unless values[0].to_i == 0 # should be a string
              raise TotalWomenCountError unless values[1].to_i + values[2].to_i == values[3].to_i
              pct_women = values[5].gsub("%","").to_f
              calc_pct_women = (values[3].to_f / values[4].to_f * 100).round(1)
              raise TotalWomenPercentageError.new("#{pct_women} does not equal #{calc_pct_women}") unless pct_women == calc_pct_women
            rescue TotalWomenPercentageError => e
              puts " -- #{e.class} -- #{e.message}"
              values[5] = calc_pct_women.to_s + "%" # fix known issue with source data: https://github.com/AdvancedEnergyEconomy/state_legislatures/pull/8
            ensure
              csv << values
            end
          end
        end
      end

      def convert_csv_to_json
        puts "Converting #{@year} csv to json"
        obj = {:year => @year, :states => []}
        CSV.foreach(csv_path, :headers => true, :header_converters => :symbol) do |row|
          state = {
            :house_women => row[:house_women].to_i,
            :senate_women => row[:senate_women].to_i,
            :total_women => row[:total_women].to_i,
            :total_seats => row[:total_seats].to_i,
            :percentage_women => row[:percentage_women]
          }
          obj[:states] << state
        end
        File.write(json_path, JSON.pretty_generate(obj))
      end

      class UnknownTableError < StandardError ; end
      class UnexpectedCellCount < StandardError ; end
      class UnexpectedCell < StandardError ; end

      class UnexpectedStateName < StandardError ; end
      class TotalWomenCountError < StandardError ; end
      class TotalWomenPercentageError < StandardError ; end
    end
  end
end
