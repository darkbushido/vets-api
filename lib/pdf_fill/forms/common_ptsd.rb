# frozen_string_literal: true

module PdfFill
  module Forms
    module CommonPtsd
      include FormHelper

      def expand_ssn(hash)
        ssn = hash['veteranSocialSecurityNumber']
        return if ssn.blank?
        ['', '1', '2'].each do |suffix|
          hash["veteranSocialSecurityNumber#{suffix}"] = split_ssn(ssn)
        end
        hash
      end

      def expand_veteran_dob(hash)
        veteran_date_of_birth = hash['veteranDateOfBirth']
        return if veteran_date_of_birth.blank?
        split_date(veteran_date_of_birth)
      end

      def expand_incident_date(incident)
        incident_date = incident['incidentDate']
        return if incident_date.blank?
        split_date(incident_date)
      end

      def expand_incident_location(incident)
        incident_location = incident['incidentLocation']
        return if incident_location.blank?

        split_incident_location = {}
        s_location = incident_location.scan(/(.{1,30})(\s+|$)/)

        s_location.each_with_index do |row, index|
          split_incident_location["row#{index}"] = row[0]
        end

        split_incident_location
      end

      def expand_unit_assigned_dates(incident)
        incident_unit_assigned_dates = incident['unitAssignedDates']
        return if incident_unit_assigned_dates.blank?
        from_dates = split_date(incident_unit_assigned_dates['from'])
        to_dates = split_date(incident_unit_assigned_dates['to'])

        unit_assignment_dates = {
          'fromMonth' => from_dates['month'],
          'fromDay' => from_dates['day'],
          'fromYear' => from_dates['year'],
          'toMonth' => to_dates['month'],
          'toDay' => to_dates['day'],
          'toYear' => to_dates['year']
        }

        incident_unit_assigned_dates.except!('to')
        incident_unit_assigned_dates.except!('from')
        incident_unit_assigned_dates.merge!(unit_assignment_dates)
      end

      def expand_incident_unit_assignment(incident)
        incident_unit_assignment = incident['unitAssigned']
        return if incident_unit_assignment.blank?

        split_incident_unit_assignment = {}
        s_incident_unit_assignment = incident_unit_assignment.scan(/(.{1,30})(\s+|$)/)

        s_incident_unit_assignment.each_with_index do |row, index|
          split_incident_unit_assignment["row#{index}"] = row[0]
        end

        split_incident_unit_assignment
      end

      def get_unit_date_overflow(unit_assigned_dates)
        unit_assigned_dates_overflow = combine_date_ranges(unit_assigned_dates)
        unit_assigned_dates_overflow.nil? ? '' : unit_assigned_dates_overflow
      end

      def format_incident(incident, index)
        return if incident.blank?
        incident_overflow = ["Incident Number: #{index}"]

        incident_date = incident['incidentDate'].nil? ? '' : incident['incidentDate']
        incident_overflow.push('Incident Date: ' + incident_date)

        incident_overflow.push('Dates of Unit Assignment: ' + get_unit_date_overflow([incident['unitAssignedDates']]))

        incident_location = incident['incidentLocation'].nil? ? '' : incident['incidentLocation']
        incident_overflow.push("Incident Location: \n\n" + incident_location)

        incident_unit_assigned = incident['unitAssigned'].nil? ? '' : incident['unitAssigned']
        incident_overflow.push("Unit Assignment During Incident: \n\n" + incident_unit_assigned)

        incident_description = incident['incidentDescription'].nil? ? '' : incident['incidentDescription']
        incident_overflow.push("Description of Incident: \n\n" + incident_description)

        incident_overflow
      end
    end
  end
end
