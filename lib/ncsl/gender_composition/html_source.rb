require 'nokogiri'
require 'httparty'
require 'active_support/core_ext/object' # enable .try method

module Ncsl
  module GenderComposition
    class HtmlSource
      DATA_DIR = File.expand_path("../../../../data/gender_composition", __FILE__)
      COLUMN_HEADERS = ["house_women","senate_women","total_women","total_seats","percentage_women"]

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

      def download
        unless File.exists?(html_path)
          puts "Extracting #{@year} data from #{@url}"
          response = HTTParty.get(@url) # HTTParty handles redirects
          puts "Writing to #{html_path}"
          File.open(html_path, "wb") do |file|
            file.write(response.body)
          end
        else
          puts "Detected local #{@year} data"
        end
      end

      def convert_to_csv
        puts "Parsing html"
        doc = File.open(html_path){|f| Nokogiri::HTML(f)}
        tables = doc.xpath("//table")
        table = tables.find{|table| table.attribute("summary").try(:value) == "State-by-state data about women in legislatures." }
        raise UnknownTableError unless table.present?

        rows = table.css("tr")
        puts "Found table with #{rows.count} rows"
        rows = rows.reject{|row| row.children.count == 1 } # reject! wasn't available
        CSV.open(csv_path, "w") do |csv|
          csv << COLUMN_HEADERS
          rows.each_with_index do |row, i|
            tds = row.children.select{|child| child.name == "td" } # get rid of erroneous Nokogiri::XML::Text elements
            next if tds.empty? # skip random blank row before header row (2015 and 2016)
            td_child_counts = tds.map{|td| td.children.count}
            puts "#{@year} -- #{i} -- #{td_child_counts}"
            csv << td_child_counts
          end
        end
      end

      class UnknownTableError < StandardError ; end
      class UnexpectedCellCount < StandardError ; end

=begin
      def select_valid_rows(table_rows)
        binding.pry if @year == 2015
        table_ # reject random blank row before 2015 column header row ... #(Element:0x3fede1e81c8c { name = "tr", children = [ #(Text "\n\t\t")] })
        #next if values.include?("TOTAL") # skip totals row
        #next if values.uniq == [nil] # skip blank row
        #next if values.map{|str| str.blank?}.uniq == [true] # skip row containing all blank values
      end

      def transform_table_row(row, i)



        raise UnexpectedCellCount unless tds.count == 6
        binding.pry unless tds.count == 6
        # #(Element:0x3ff5fe5c6a8c { name = "tr", children = [ #(Text "\n\t\t")] })



        #binding.pry unless td_child_counts.uniq == [3]
        # some rows have three children, including a div element which contains a nested text element. others just have one child, sometimes another nested td which contains the text element.

        divs = []
        tds.each do |td|
          case td.children.count
          when 1
            divs << td.children.first
          when 3
            divs << td.children.find{|child| child.name == "div"}
          else
            binding.pry
          end
        end # get the div nested inside the td

        texts = []
        if i == 0 # handle header rows
          bs = divs.map{|div| div.children.find{|child| child.name == "b"} }
          texts = bs.map{|b| b.children.find{|child| child.name == "text"} }
        else
          divs.each do |div|
            if div.children.any?
              texts << div
            else
              texts << div.children.find{|child| child.name == "text"}
            end
          end
        end

        values = texts.map{|text| text.try(:text).try(:strip) }


        puts "... #{values}"
        binding.pry if values.include?(nil)
      end
=end
    end
  end
end
