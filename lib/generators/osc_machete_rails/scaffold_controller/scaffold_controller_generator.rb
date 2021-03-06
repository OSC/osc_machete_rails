require 'rails/generators/rails/scaffold_controller/scaffold_controller_generator'
require 'generators/osc_machete_rails/job_helpers'

class OscMacheteRails::ScaffoldControllerGenerator < Rails::Generators::ScaffoldControllerGenerator
  include OscMacheteRails::JobHelpers
  source_root File.expand_path('../templates', __FILE__)

  # attribute to know what the job model is - see comments on active_record/workflow_model_generator.rb
  attr_reader :job

  def initialize(args, *options)
    @job = parse_job!(args)

    super
  end

  # override ScaffoldControllerGenerator
  # by recalling hook_for, the erb_generator will be searched for under OscMacheteRails
  # (idiosyncracy of Thor)
  #
  # the default template engine is erb, so we provide specific erb_generator.rb and its templates
  # see lib/generators/osc_machete_rails/erb for details
  hook_for :template_engine
end
