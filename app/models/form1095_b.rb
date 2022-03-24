# frozen_string_literal: true

class Form1095B < ApplicationRecord
  validates :veteran_icn, :first_name, :last_name, :address, :tax_year, :city, presence: true
  validates :veteran_icn, uniqueness: { scope: :tax_year }
  validates :ssn, presence: true, unless: -> { birth_date.present? }, format: /\A\d{9}\z|\A\d{4}\z/
  validates :birth_date, presence: true, unless: -> { ssn.present? }
  validates :coverage_months, length: { is: 13 }
  validates :zip_code, presence: true, unless: -> { foreign_zip.present? }, format: /\A\d{5}\z|\A\d{5}-\d{4}\z/
  validates :state, presence: true, unless: -> { province.present? }

  # assumes ssn is already last 4 if only 4 digits are provided
  before_save :store_last_4, if: -> { ssn.size == 9 }

  # scopes
  scope :get_available_forms, ->(icn) { where(veteran_icn: icn).distinct.pluck(:tax_year, :updated_at) }

  # calls pdf generator function
  def get_pdf
    generate_pdf
  end

  private

  def generate_pdf
    pdf = PdfForms.new(Settings.binaries.pdftk)

    temp_location = "lib/pdf_fill/temp/1095B-#{SecureRandom.hex}.pdf"
    template_file = "lib/pdf_fill/forms/pdfs/f1095bs/1095b-#{tax_year}.pdf"

    unless File.exist?(template_file)
      Rails.logger.error "1095-B template for year #{tax_year} does not exist."
      raise "1095-B for tax year #{tax_year} not supported"
    end

    pdf.fill_form(
      template_file,
      temp_location,
      {
        "topmostSubform[0].Page1[0].Pg1Header[0].cb_1[1]": is_corrected && 2,
        "topmostSubform[0].Page1[0].Part1Contents[0].Line1[0].f1_01[0]": first_name,
        "topmostSubform[0].Page1[0].Part1Contents[0].Line1[0].f1_02[0]": middle_name,
        "topmostSubform[0].Page1[0].Part1Contents[0].Line1[0].f1_03[0]": last_name,
        "topmostSubform[0].Page1[0].Part1Contents[0].f1_04[0]": ssn || '',
        "topmostSubform[0].Page1[0].Part1Contents[0].f1_05[0]": ssn ? '' : birth_date,
        "topmostSubform[0].Page1[0].Part1Contents[0].f1_06[0]": address,
        "topmostSubform[0].Page1[0].Part1Contents[0].f1_07[0]": city,
        "topmostSubform[0].Page1[0].Part1Contents[0].f1_08[0]": state || province,
        "topmostSubform[0].Page1[0].Part1Contents[0].f1_09[0]": "#{country} #{zip_code || foreign_zip}",
        "topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].f1_25[0]": first_name,
        "topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].f1_26[0]": middle_name ? middle_name[0] : '',
        "topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].f1_27[0]": last_name,
        "topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].f1_28[0]": ssn || '',
        "topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].f1_29[0]": ssn ? '' : birth_date,
        "topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_01[0]": coverage_months[0] && 1,
        "topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_02[0]": coverage_months[1] && 1,
        "topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_03[0]": coverage_months[2] && 1,
        "topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_04[0]": coverage_months[3] && 1,
        "topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_05[0]": coverage_months[4] && 1,
        "topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_06[0]": coverage_months[5] && 1,
        "topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_07[0]": coverage_months[6] && 1,
        "topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_08[0]": coverage_months[7] && 1,
        "topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_09[0]": coverage_months[8] && 1,
        "topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_10[0]": coverage_months[9] && 1,
        "topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_11[0]": coverage_months[10] && 1,
        "topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_12[0]": coverage_months[11] && 1,
        "topmostSubform[0].Page1[0].Table1_Part4[0].Row23[0].c1_13[0]": coverage_months[12] && 1
      },
      flatten: true
    )
    # TODO: try to return PDF without saving the file first

    file_contents = File.read(temp_location)
    
    File.delete(temp_location)

    file_contents

    # send_data file_contents, filename: file_name, type: 'application/pdf', disposition: 'attachment'
  rescue PdfForms::PdftkError => e
    # in case theres other errors generating the PDF
    Rails.logger.error e
    raise e
  end

  def store_last_4
    self.ssn = ssn[-4..]
  end
end
