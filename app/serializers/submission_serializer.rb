class SubmissionSerializer < ActiveModel::Serializer
  attributes :public_id, :time, :memory, :stdout, :result, :stderr, :compile_output, :message, :status, :language_id

  def stdout
    Base64Service.encode(object.stdout)
  end
  def compile_output
    Base64Service.encode(object.compile_output)
  end
  def stderr
    Base64Service.encode(object.stderr)
  end
  def message
    Base64Service.encode(object.message)
  end
  def result
    Base64Service.encode(object.result)
  end

  def self.default_fields
    [
      :public_id,
      :time,
      :memory,
      :stdout,
      :result,
      :stderr,
      :compile_output,
      :message,
      :status
    ]
  end
end
