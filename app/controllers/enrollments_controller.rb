# frozen_string_literal: true

class EnrollmentsController < ApplicationController
  acts_as_token_authentication_handler_for User
  before_action :set_enrollment, only: %i[show convention update trigger destroy]

  # GET /enrollments
  def index
    if archived_params
      @enrollments = enrollments_scope.archived
    else
      @enrollments = enrollments_scope.pending
    end

    render json: @enrollments.map { |e| serialize(e) }
  end

  # GET /enrollments/1
  def show
    render json: serialize(@enrollment)
  end

  # GET /enrollments/1/convention
  def convention
    authorize @enrollment, :convention?
    @filename = 'convention.pdf'
  end

  # POST /enrollments
  def create
    @enrollment = enrollments_scope.new(enrollment_params)

    authorize @enrollment, :create?

    if @enrollment.save
      current_user.add_role(:applicant, @enrollment)
      render json: @enrollment, status: :created, location: enrollment_url(@enrollment)
    else
      render json: @enrollment.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /enrollments/1
  def update
    @enrollment.attributes = enrollment_params
    authorize @enrollment, :update?

    if @enrollment.save
      render json: serialize(@enrollment)
    else
      render json: @enrollment.errors, status: :unprocessable_entity
    end
  end

  # PATCH /enrollment/1/trigger
  def trigger
    authorize @enrollment, "#{event_param}?".to_sym

    if message_params.has_key?(:messages_attributes)
      params =  {
        messages_attributes: message_params[:messages_attributes].map! {|h| h.merge(category: event_param.to_s)}
      }
      @enrollment.update(params)
    end

    if @enrollment.send(event_param.to_sym, user: current_user)
      render json: serialize(@enrollment)
    else
      render status: :unprocessable_entity, json: @enrollment.errors
    end
  end

  # DELETE /enrollments/1
  def destroy
    authorize @enrollment, :delete?
    @enrollment.destroy
  end

  def serialize(enrollment)
    Rails.application.eager_load!
    policy_class = Object.const_get("#{enrollment.class.to_s}Policy")
    enrollment.as_json(
      include: [{ documents: { methods: :type } }, { messages: { include: :sender } }],
      methods: [:applicant]
    ).merge('acl' => Hash[
      policy_class.acl_methods.map do |method|
        [method.to_s.delete('?'), policy_class.new(current_user, enrollment).send(method)]
      end
    ])
  end

  private

  def set_enrollment
    @enrollment = enrollments_scope.find(params[:id])
  end

  def enrollment_class
    type = params.fetch(:enrollment, {})[:fournisseur_de_donnees]
    type = %w[dgfip api-particulier api-entreprise].include?(type) ? type : nil

    class_name = type ? "Enrollment::#{type.underscore.classify}" : 'Enrollment'
    class_name.constantize
  end

  def enrollments_scope
    EnrollmentPolicy::Scope.new(current_user, enrollment_class).resolve
  end

  def enrollment_params
    params
      .fetch(:enrollment, {})
      .permit(*policy(@enrollment || enrollment_class.new).permitted_attributes)
      .tap do |whitelisted_params|
        enrollment = params.fetch(:enrollment, {})
        scopes = enrollment[:scopes]
        destinataires = enrollment.fetch(:donnees, {})[:destinataires]
        whitelisted_params[:scopes] = scopes.permit! if scopes.present?
        whitelisted_params.fetch(:donnees, {})[:destinataires] = destinataires.permit! if destinataires.present?
    end
  end

  def archived_params
    params.fetch(:archived, false)
  end

  def message_params
    params.fetch(:enrollment, {}).permit(messages_attributes: [:content])
  end

  def event_param
    event = params[:event]
    raise EventNotPermitted unless enrollment_class.state_machine.events.map(&:name).include?(event.to_sym)
    event
  end

  class EventNotPermitted < StandardError; end

  rescue_from EventNotPermitted do
    render status: :bad_request, json: {
      message: ['event not permitted']
    }
  end
end
