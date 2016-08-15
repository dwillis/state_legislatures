require_relative "../lib/ncsl"

Ncsl::PdfSource.all.each do |pdf_source|
  pdf_source.download
end
