require 'nokogiri'
require 'httparty'
require 'active_support/core_ext/object' # enable .try method

module Ncsl
  module GenderComposition
    class HtmlSource

      def self.all
        Ncsl::GenderComposition::URL_SOURCES.map{|source| new(source) }
      end

      def initialize(source)
        @url = source[:url]
        @year = source[:year]
      end

      def year
        @year
      end

      def download_to_csv
        puts "Extracting #{@year} data from #{@url}"
        response = HTTParty.get(@url)
        puts "Parsing response body"
        doc = Nokogiri::HTML(response.body)
        tables = doc.xpath("//table")
        table = tables.find{|table| table.attribute("summary").try(:value) == "State-by-state data about women in legislatures." }
        raise UnknownTableError unless table.present?
        rows = table.css("tr")
        rows.each_with_index do |row, i|
          tds = row.children.select{|child| child.name == "td" } # get rid of erroneous Nokogiri::XML::Text elements
          divs = tds.map{|td| td.children.find{|child| child.name == "div"} } # get the div nested inside the td

          if i == 0 # handle header rows
            bs = divs.map{|div| div.children.find{|child| child.name == "b"} }
            texts = bs.map{|b| b.children.find{|child| child.name == "text"} }
            values = texts.map{|text| text.text.strip}
            puts values
          else
            texts = divs.map{|div| div.children.find{|child| child.name == "text"} }
            values = texts.map{|text| text.text.strip}
            puts values.first
          end
          raise UnexpectedCellCount unless values.count == 6

        end
      end

      class UnknownTableError < StandardError ; end
      class UnexpectedCellCount < StandardError ; end
    end
  end
end
