require_relative "../lib/ncsl"

Ncsl::GenderComposition::HtmlSource.all.each do |html_source|
  html_source.download
end

Ncsl::GenderComposition::HtmlSource.all.each do |html_source|
  html_source.convert_to_csv
end
