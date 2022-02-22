class CreateForm1095BBeneficiaries < ActiveRecord::Migration[6.1]
  def change
    create_table :form1095_b_beneficiaries, id: :uuid do |t|
      t.uuid :form1095_b_id, foreign_key: true, null: false

      t.string :first_name
      t.string :last_name
      t.string :middle_name
      t.string :ssn
      t.date :birth_date
      t.boolean :coverage_months, array:true, null: false
      t.boolean :isCorrected, default: false

      t.timestamps

      t.index :form1095_b_id, name: "index_form1095_b_beneficiaries_on_form1095_b_id"
    end
  end
end
