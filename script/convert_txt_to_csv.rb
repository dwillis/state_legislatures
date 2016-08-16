require_relative "../lib/ncsl"

Ncsl::PdfSource.all.each do |pdf_source|
  pdf_source.convert_txt_to_csv
end
