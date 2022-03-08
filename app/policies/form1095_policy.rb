# frozen_string_literal: true

Form1095Policy = Struct.new(:user, :form1095) do
    def access?
        puts "do they have access?"
        puts user.present?
        user.present? && user.loa3? && user.icn.present?
    end
  end