class Form1095B < ApplicationRecord
  # belongs_to :account # ...?

  has_many :form1095_b_beneficiaries

  # validations for required form fields
  validates :veteran_icn, :first_name, :last_name, :address, :tax_year, presence: true
  validates :veteran_icn, uniqueness: { scope: :tax_year}
  validates :ssn, presence: true, unless: -> { birth_date.present? }, format: /\A\d{9}\z|\A\d{4}\z/
  validates :birth_date, presence: true, unless: -> { ssn.present? }
  validates :coverage_months, length: { is: 13 }
  validates :zip_code, presence: true, unless: -> { foreign_zip.present? }, format: /\A\d{5}\z|\A\d{5}-\d{4}\z/
  validates :country, presence: true, unless: -> { foreign_zip.present? }
  # more validations

  # scopes
  scope :find_by_icn_and_year, -> (icn, year) {where("veteran_icn = ? and tax_year = ?", icn, year).first}

  # assumes ssn is already last 4 if only 4 digits are provided
  before_save :store_last_4, if: -> { ssn.size == 9 }

  # calls pdf generator function
  def get_pdf
    puts 'Generating PDF!' # placeholder
    # gen_1095B(self)
    generate_pdf
  end


  private

  def generate_pdf
    puts "Here is PDF!" # placeholder for testing
    pdf = PdfForms.new(Settings.binaries.pdftk)
    # binding.pry

    temp_location = "lib/pdf_fill/temp/1095B-#{DateTime.now.to_i}.pdf"

    pdf.fill_form(
      "lib/pdf_fill/forms/pdfs/f1095bs/1095b-#{self.tax_year}.pdf",
      temp_location,
      {
        :"topmostSubform[0].Page1[0].Pg1Header[0].cb_1[1]" => self.is_corrected && 2,
        :"topmostSubform[0].Page1[0].Part1Contents[0].Line1[0].f1_01[0]" => self.first_name,
        :"topmostSubform[0].Page1[0].Part1Contents[0].Line1[0].f1_02[0]" => self.middle_name,
        :"topmostSubform[0].Page1[0].Part1Contents[0].Line1[0].f1_03[0]" => self.last_name,
        :"topmostSubform[0].Page1[0].Part1Contents[0].f1_04[0]" => self.ssn || "",
        :"topmostSubform[0].Page1[0].Part1Contents[0].f1_05[0]" => self.birth_date || "",
        :"topmostSubform[0].Page1[0].Part1Contents[0].f1_06[0]" => self.address, #street address
        :"topmostSubform[0].Page1[0].Part1Contents[0].f1_07[0]" => self.city,  #city/town
        :"topmostSubform[0].Page1[0].Part1Contents[0].f1_08[0]" => self.state ? self.state : self.province, 
        :"topmostSubform[0].Page1[0].Part1Contents[0].f1_09[0]" => self.country + " " + (self.zip_code || self.foreign_zip), # country + zip OR foreign postal string
        :"topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].f1_25[0]" => self.first_name,
        :"topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].f1_26[0]" => self.middle_name ? self.middle_name[0] : "",
        :"topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].f1_27[0]" => self.last_name,
        :"topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].f1_28[0]" => self.ssn || "",
        :"topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].f1_29[0]" => self.birth_date || "", 
        :"topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_01[0]" => self.coverage_months[0] && 1,
        :"topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_02[0]" => self.coverage_months[1] && 1,
        :"topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_03[0]" => self.coverage_months[2] && 1,
        :"topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_04[0]" => self.coverage_months[3] && 1,
        :"topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_05[0]" => self.coverage_months[4] && 1,
        :"topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_06[0]" => self.coverage_months[5] && 1,
        :"topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_07[0]" => self.coverage_months[6] && 1,
        :"topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_08[0]" => self.coverage_months[7] && 1,
        :"topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_09[0]" => self.coverage_months[8] && 1,
        :"topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_10[0]" => self.coverage_months[9] && 1,
        :"topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_11[0]" => self.coverage_months[10] && 1,
        :"topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_12[0]" => self.coverage_months[11] && 1,
        :"topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_13[0]" => self.coverage_months[12] && 1
      },
      flatten: true
    )
    # binding.pry

    # TODO: try with below commented out
    # source_file_path = temp_location # where the file gets saved - do we want to change this? 
    # client_file_name = '1095B.pdf'
    file_contents = File.read(temp_location)
    
     #during testing make sure this line does not delete the file that is used as the template
    File.delete(temp_location)

    file_contents

    # send_data file_contents, filename: client_file_name, type: 'application/pdf', disposition: 'attachment'
  end

  def store_last_4
    self.ssn = self.ssn[-4...]
  end
end
