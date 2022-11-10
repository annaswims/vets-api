# frozen_string_literal: true

require 'decision_review_v1/utilities/pdf_validation/service'

module FormAttachmentCreate
  extend ActiveSupport::Concern

  def create
    form_attachment_model = self.class::FORM_ATTACHMENT_MODEL
    form_attachment = form_attachment_model.new
    namespace = form_attachment_model.to_s.underscore.split('/').last
    filtered_params = params.require(namespace).permit(:file_data, :password)
    # is it either ActionDispatch::Http::UploadedFile or Rack::Test::UploadedFile
    fd = filtered_params[:file_data]
    pw = filtered_params[:password]
    unless fd.class.name.include? 'UploadedFile'
      raise Common::Exceptions::InvalidFieldValue.new('file_data', fd.class.name)
    end

    form_attachment.set_file_data!(fd, pw)
    form_attachment.save!
    lighthouse_validation_errors = validate_pdf(fd).body
    ret_val = lighthouse_validation_errors.key?('errors') ? lighthouse_validation_errors : form_attachment
    render(json: ret_val)
  end

  private

  def decision_review_pdf_service
    DecisionReviewV1::PdfValidation::Service.new
  end

  def validate_pdf(file)
    decision_review_pdf_service.validate_pdf_with_lighthouse(file)
  end
end
