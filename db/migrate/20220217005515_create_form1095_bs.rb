class CreateForm1095Bs < ActiveRecord::Migration[6.1]
  def change
    create_table :form1095_bs, id: :uuid do |t|
      t.string :veteran_icn, null: false

      t.string :first_name, null: false
      t.string :middle_name
      t.string :last_name, null: false
      t.date :birth_date
      t.string :ssn # only need to store last 4; is string because first character can be 0
      t.string :address, null: false
      t.string :city
      t.string :state
      t.string :country
      t.string :zip_code
      t.string :province
      t.string :foreign_zip
      t.boolean :coverage_months, array:true, null: false
      t.integer :tax_year, null: false # validate that only one exists per vet, per year
      t.datetime :last_modified, null: false # , default: DateTime.now
      t.boolean :isCorrected, default: false
      t.boolean :isBeneficiary, default: false

      t.timestamps
    end
    add_index :form1095_bs, :veteran_icn
  end
end
