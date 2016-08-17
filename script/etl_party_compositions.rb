require_relative "../lib/ncsl"

#Ncsl::PartyComposition::PdfSource.all.each do |pdf_source|
#  pdf_source.download
#end

#Ncsl::PartyComposition::PdfSource.all.each do |pdf_source|
#  pdf_source.convert_to_txt
#end

Ncsl::PartyComposition::PdfSource.all.each do |pdf_source|
  pdf_source.convert_txt_to_csv
end

#Ncsl::PartyComposition::PdfSource.all.each do |pdf_source|
#  pdf_source.convert_csv_to_json
#end
