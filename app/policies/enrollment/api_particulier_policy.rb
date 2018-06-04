class Enrollment::ApiParticulierPolicy < EnrollmentPolicy
  def validate_application?
    record.can_validate_application? && user.api_particulier?
  end

  def refuse_application?
    record.can_refuse_application? && user.api_particulier?
  end

  def show_technical_inputs?
    (
      (
        record.can_send_technical_inputs? || record.technical_inputs? || record.deployed?
      ) && user.has_role?(:applicant, record)
    ) || user.api_particulier?
  end

  def deploy_application?
    record.can_deploy_application? && user.api_particulier?
  end

  def review_application?
    record.can_review_application? && user.api_particulier?
  end
end
