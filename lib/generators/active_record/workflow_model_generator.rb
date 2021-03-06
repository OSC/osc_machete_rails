require 'rails/generators/active_record/model/model_generator'
require 'generators/active_record/orm_helpers'
require 'generators/osc_machete_rails/job_helpers'

class ActiveRecord::WorkflowModelGenerator < ActiveRecord::Generators::ModelGenerator
  include ActiveRecord::OrmHelpers
  include OscMacheteRails::JobHelpers
  source_root File.expand_path('../templates', __FILE__)

  # add a new attribute to the generator
  # the workflow needs to know what the job model is
  # to render the template properly
  attr_reader :job

  # jobs is a new attribute type, like "references", so we can let the user specify the corresponding
  # job model. This attribute is used in the workflow_model.rb template file. i.e.
  #
  #     rails g osc_machete_rails:workflow_model Container name:string container_job:jobs
  #
  def initialize(args, *options)
    @job = parse_job!(args)
    super
  end

  # overrides original ModelGenerator#create_model_file to make a workflow_model instead of a model
  # since we are inheriting from ModelGenerator, we get the tests and all the other good stuff
  def create_model_file
    template 'workflow_model.rb', File.join('app/models', class_path, "#{file_name}.rb")
  end
end
