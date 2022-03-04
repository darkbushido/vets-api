require 'sidekiq-scheduler'
# require 'pry'
# require 'active_support'
# require 'active_support/core_ext'
# require 'aws-sdk-s3'

module Form1095
  class GetNew1095Bs
    include Sidekiq::Worker

    # BASE_PATH = './test_flat_files/'
    BUCKET = 'dsva-vagov-dev-1095b-form-uploads'

    def get_bucket_files
      # grabs available file names from bucket
      # how to know if we've checked it already?? todo: delete files after successfully reading them...?
      # todo: does the below return array of the file names?
      @s3.list_objects({ bucket: BUCKET, prefix: 'MEC', delimiter: '/' }).contents.collect(&:key) # gets file names # todo: uncomment when @s3 available
      # Dir.entries(BASE_PATH).filter {|file| file.include?('.txt')}

      # files.present? ? files : [] # what does empty bucket return?
    end

    # def get_test_bucket_files
    #   # check for filenames in './test_flat_files/'
    #   Dir.entries(BASE_PATH).filter {|file| file.include?('.txt')}
    # end

    def parse_file_name(file_name) # or file...?
      return {} unless file_name.present?
      # parse file name to check if its for veteran/dependent

      # return obj like: {:is_vet => true, :isOg => true, :tax_year => 2021, :timestamp => <file timestamp from name>}
      file_values = file_name.sub('.txt', '').split('_')

      year = file_values[3].to_i
      ts = file_values[-1]

      {
        :is_dep_file? => file_values.include?('B'),
        :isOg? => file_values.include?('O'),
        :tax_year => year,
        :timestamp => ts
      }
    end

    def gen_address(addr1, addr2, addr3)
      addr1.concat(" ", addr2 || "", " ", addr3 || "").strip # shouldn't be an addr3 if addr 2 doesn't exist, so no worries about double space in middle
    end

    def parse_form(form)
      # return hash with form fields
      data = form.split('^')

      # form_type = data[0].sub('FORM=', '')
      # creation_date = data[1]
      # unique_id = data[2]

      temp = {}
      data.each_with_index do |field, ndx|
        next if ndx < 3

        vals = field.split('=')
        temp[vals[0].to_sym] = vals[1] || nil
      end

      coverage_arr = []
      i = 1
      while i <= 13 do
        val = "H".concat(i < 10 ? "0" : "", i.to_s)
        coverage_arr.push(temp[val.to_sym] ? true : false)

        i += 1
      end

      {
        :last_name => temp[:A01],
        :first_name => temp[:A02],
        :middle_name => temp[:A03],
        :veteran_icn => temp[:A15].gsub(/\A0{6}|0{6}\z/, ''),
        :ssn => temp[:A16],
        :birth_date => temp[:N03],
        :address => gen_address(temp[:B01], temp[:B02], temp[:B03]),
        :city => temp[:B04],
        :state => temp[:B05],
        :country => temp[:B06],
        :zip_code => temp[:B07],
        :foreign_zip => temp[:B08],
        :province => temp[:B10],
        :coverage_months => coverage_arr
      }
    end

    def save_data?(form_data, year, is_original, is_beneficiary)
      # check to see if record exists for this year
      # if exists, then make sure its a correction and update
      # else create new Form1095B to store

      existing_form = Form1095B.find_by(:veteran_icn => form_data[:veteran_icn], :tax_year => year)

      return true if is_original and existing_form.present?  # returns true to indicate successful entry
      return false if !is_original and existing_form.nil? # return false here?? if is a correction, then it should already exist

      form_data[:tax_year] = year
      form_data[:is_corrected] = !is_original
      form_data[:is_beneficiary] = is_beneficiary

      if is_original
        form = Form1095B.new(form_data)
        return form.save
      else
        # update only not nil fields...?
        # form_data.each do |key, value|
        #   form_data.delete(key) unless value != nil
        # end

        return existing_form.update(form_data)
      end

      false
    end

    def process_file?(file_name)
      puts 'processing file: ' + file_name
      return false unless file_name.include?(".txt")

      file_details = parse_file_name(file_name) # find how to get file name
      puts 'file_details'
      puts file_details
      # binding.pry

      return false unless file_details.present?

      # file = File.open(BASE_PATH + file_name)
      # file = s3.bucket("Form1095Bucket").object(fileName) # todo: uncomment when s3 available

      # puts 'file class:'
      # puts file.class

      # data comes as string???
      # contents = file.read
      # contents = file.data # todo: uncomment when s3 available


      # binding.pry

      # return true unless contents # return true to show that file has been read

      # todo: get file contents
      contents = @s3.get_object(bucket: BUCKET, key: file_name).body

      puts 'contents'
      puts contents.class

      # forms = contents.split("\n")
      contents.each_line do |form|
        # puts 'form'
        # puts form
        data = parse_form(form)
        puts "data"
        puts data
        # binding.pry
        unless save_data?(data, file_details[:tax_year], file_details[:isOg?], file_details[:is_dep_file?])
          puts "failed on form with unique ID: #{data[:unique_id]}"
          return false
        end
      end

      contents.close

      true
    end

    def perform
      puts 'Performing!!!!!'

      @s3 = Aws::S3::Client.new

      binding.pry

      # File.open('new_file.txt', "w+") {|f| f.write("hi there :)")}
      #
      # puts "wrote to file"
      # return

      # get file names
      file_names = get_bucket_files
      # fileNames = getBucketFiles

      puts 'fileNames'
      puts file_names
      # binding.pry
      puts "No files found" if file_names.empty?

      file_names.each do |file_name|
        if process_file?(file_name)
          # todo: delete file from bucket
          puts "#{file_name} read successfully, deleting file from S3..."
          @s3.delete_object({ key: file_name, bucket: BUCKET })
        else
          puts "failed to load data from file: #{file_name}"
        end
      end

    end
  end
end