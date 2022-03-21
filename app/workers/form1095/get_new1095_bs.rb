require 'sidekiq-scheduler'

module Form1095
  class GetNew1095Bs
    include Sidekiq::Worker


    def bucket
      @bucket ||= Aws::S3::Resource.new(
        region: Settings.form1095_b.s3.region,
        access_key_id: Settings.form1095_b.s3.aws_access_key_id,
        secret_access_key: Settings.form1095_b.s3.aws_secret_access_key
      ).bucket(Settings.form1095_b.s3.bucket)
      # @bucket ||= Aws::S3::Resource.new(
      #   region: 'us-gov-west-1', 
      #   access_key_id: "ASIAQD72FDTF63A3VAUG",
      #   secret_access_key: "cQ7SC6SvAFULPxMYhp8xjzK9gFagoQFPdNrto9EX",
      #   session_token: "FwoDYXdzEHgaDBxU3s1GZvIIF3w9MCKGAdw1ILuU+sqc7BNpUzdteDW/y1Z9Cn9GXMptMNgYqXqzkS0MFCgmOCmF+CQHzAeJPnyOLgES+MiG+bupYKl664PnZh2TfGcNWYD2YWjApGV1nUiHPKJmm1cfVpw4NxZ9VrG+86MTnn79KFkFHJXUdQaykBYM4vPjHh6ZNvTLS+UOuK/zqcXLKLWPw5EGMii8BJXjgSNY/jNhRlYRDFgHDl553+EsgsHw95jwPm3PY62RKIC5bZHi"
      # ).bucket("dsva-vagov-dev-1095b-form-uploads")
    end


    def get_bucket_files
      # grabs available file names from bucket
      bucket.objects({prefix: 'MEC', delimiter: '/'}).collect(&:key)
    end


    def parse_file_name(file_name) # or file...?
      return {} unless file_name.present?

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
      data = form.split('^')

      # form_type = data[0].sub('FORM=', '')
      # creation_date = data[1]
      unique_id = data[2]

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
        coverage_arr.push((temp[val.to_sym]) ? true : false)

        i += 1
      end

      {
        :unique_id => unique_id,
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


    def save_data?(form_data)

      existing_form = Form1095B.find_by(:veteran_icn => form_data[:veteran_icn], :tax_year => form_data[:tax_year])

      if !form_data[:is_corrected] and existing_form.present?  # returns true to indicate successful entry
        Rails.logger.warn "Form for #{form_data[:tax_year]} already exists, but file is for Original 1095-B forms. Skipping this entry."
        return true 
      elsif form_data[:is_corrected] and existing_form.nil?
        Rails.logger.warn "Form for year #{form_data[:tax_year]} not found, but file is for Corrected 1095-B forms. Skipping this entry." # ...?
        return true  # return false here?? (or create form?) if is a correction, then it should already exist
      end

      if existing_form.nil?
        form = Form1095B.new(form_data)
        return form.save
      else
        return existing_form.update(form_data)
      end

      false
    end


    # downloading file to the disk and then reading that file, this will allow us to read large S3 files without exhausting resources/crashing the system
    def process_file?(file_name)
      Rails.logger.info "processing file: " + file_name
      return false unless file_name.include?(".txt")

      file_details = parse_file_name(file_name)

      return false unless file_details.present?

      # downloads S3 file into local file, allows for processing large files this way
      temp_file_name = "lib/form1095_b/temp_files/#{file_name}"
      begin
        file = bucket.object(file_name).get(response_target: temp_file_name)

        file = File.open(temp_file_name, "r")

        file.each_line do |form|
          data = parse_form(form)

          data[:tax_year] = file_details[:tax_year]
          data[:is_corrected] = !file_details[:isOg?]
          data[:is_beneficiary] = file_details[:is_dep_file?]
          unique_id = data[:unique_id]
          data.delete(:unique_id)

          unless save_data?(data)
            Rails.logger.error "Failed on form with unique ID: #{unique_id}"
            return false
          end
        end

        File.delete(file)
        file.close
      rescue => e
        Rails.logger.error(e.message)
        return false
      end

      true
    end


    def perform
      Rails.logger.info "Checking for new 1095-B data"

      file_names = get_bucket_files
      Rails.logger.info "No new 1095 files found" if file_names.empty?

      file_names.each do |file_name|
        if process_file?(file_name)
          Rails.logger.info "#{file_name} read successfully, deleting file from S3"
          bucket.delete_objects(delete: { objects: [{ key: file_name }] })
        else
          Rails.logger.error "failed to load 1095 data from file: #{file_name}"
        end
      end
    end
  end
end