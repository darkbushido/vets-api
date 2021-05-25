#!/usr/bin/ruby
require 'faraday'
URL = 'https://dev-api.va.gov'

#curl -v -L -X POST 'https://dev-api.va.gov/services/vba_documents/v2/uploads/submit' -F 'metadata="{\"veteranFirstName\": \"Matsumoto\",\"veteranLastName\": \"Test\",\"fileNumber\": \"012345678\",\"zipCode\": \"97202\",\"source\": \"MyVSO\",\"docType\": \"21-22\"}";type=application/json' -F 'content=@"1.pdf"' -F 'attachment1=@"v1.pdf"' -F 'attachment2=@"v1.pdf"' -F 'attachment3=@"v1.pdf"'
metadata = ARGV[0].to_s
pdf_file = ARGV[1].to_s
num_times = ARGV[2].to_i
pids = []
num_times.times do |i|
  pids << fork do

    pdf1 = Faraday::UploadIO.new(pdf_file, 'application/pdf')
    pdf2 = Faraday::UploadIO.new(pdf_file, 'application/pdf')
    pdf3 = Faraday::UploadIO.new(pdf_file, 'application/pdf')
    metadata = Faraday::UploadIO.new(metadata.to_s, 'application/json')

    conn = Faraday.new(url: URL) do |faraday|
      faraday.request :multipart
      faraday.request :url_encoded
      faraday.adapter Faraday.default_adapter

    end

    payload = {metadata: metadata, content: pdf1, attachment1: pdf2, attachement2: pdf3}

    t1 = Time.now
    puts "Starting post...."
    headers = {apikey: "mulgyIRUpqY8SeJoM89e3t2iZucbZVSH"}
    response = conn.post('/services/vba_documents/v2/uploads/submit', payload, headers)
    t2 = Time.now
    File.write("body_#{i}", response.body+ "\n")
    File.write("status_#{i}", response.status.to_s + "\n")
    File.write("time_#{i}", "I took #{t2 - t1} seconds\n")
  end
end
puts "Waiting"
pids.each { |pid| Process.waitpid(pid) } # wait for my children to completeputs "Summary:"
puts "Done!"