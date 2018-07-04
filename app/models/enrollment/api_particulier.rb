class Enrollment::ApiParticulier < Enrollment
  resourcify

  # Note convention on events "#{verb}_#{what}" (see CoreAdditions::String#as_event_personified)
  state_machine :state, initial: :pending do
    state :pending
    state :sent do
      validate :fields_validation

      def fields_validation
        %w[dpo technique responsable_traitement]. each do |contact_type|
          contact = contacts&.find { |e| e['id'] == contact_type }
          errors[:contacts] << "Vous devez renseigner le #{contact&.fetch('heading', nil)} avant de continuer" unless contact&.fetch('nom', false)&.present? && contact&.fetch('email', false)&.present?
        end

        errors[:siren] << "Vous devez renseigner le SIREN de votre organisation avant de continuer" unless siren.present?
        errors[:demarche] << "Vous devez renseigner la description de la démarche avant de continuer" unless demarche && demarche['description'].present?
        errors[:demarche] << "Vous devez renseigner le fondement juridique de la démarche avant de continuer" unless demarche && demarche['fondement_juridique'].present?
        errors[:donnees] << "Vous devez renseigner la conservation des données avant de continuer" unless donnees && donnees['conservation'].present?
        errors[:donnees] << "Vous devez renseigner les destinataires des données avant de continuer" unless donnees && donnees['destinataires'].present?
      end
    end
    state :validated
    state :refused

    event :send_application do
      transition from: :pending, to: :sent
    end

    event :validate_application do
      transition from: :sent, to: :validated
    end

    event :refuse_application do
      transition from: :sent, to: :refused
    end

    event :review_application do
      transition from: :sent, to: :pending
    end

    event :send_technical_inputs do
      transition from: :validated, to: :technical_inputs
    end

    event :deploy_application do
      transition from: :technical_inputs, to: :deployed
    end
  end

  def applicant
    User.with_role(:applicant, self).first
  end

  def as_json(*params)
    super(*params).merge({
      'id' => id,
      'applicant' => applicant.as_json,
      'fournisseur_de_donnees' => fournisseur_de_donnees,
      'validation_de_convention' => validation_de_convention,
      'scopes' => scopes,
      'contacts' => contacts,
      'siren' => siren,
      'demarche' => demarche,
      'donnees' => donnees&.merge('destinataires' => donnees&.fetch('destinataires', {})),
      'state' => state,
      'documents' => documents.as_json(methods: :type),
      'messages' => messages.as_json(include: :sender)
    })
  end

  def short_workflow?
    true
  end
end