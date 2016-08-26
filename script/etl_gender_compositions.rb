require_relative "../lib/ncsl"

Ncsl::GenderComposition::HtmlSource.all.each do |html_source|
  next if html_source.year > 2009
  html_source.download_to_csv
end

#Ncsl::GenderComposition::HtmlSource.all.each do |html_source|
#  html_source.convert_csv_to_json
#end
