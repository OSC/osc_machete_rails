<% if namespaced? -%>
require_dependency "<%= namespaced_path %>/application_controller"

<% end -%>
<% module_namespacing do -%>
class <%= controller_class_name %>Controller < ApplicationController
  before_action :set_<%= singular_table_name %>, only: [:show, :edit, :update, :destroy, :submit, :copy]

  # GET <%= route_url %>
  # GET <%= route_url %>.json
  def index
    @<%= plural_table_name %> = <%= "#{class_name}.preload(:#{job.plural_name})" %>
  end

  # GET <%= route_url %>/1
  # GET <%= route_url %>/1.json
  def show
  end

  # GET <%= route_url %>/new
  def new
    @<%= singular_table_name %> = <%= orm_class.build(class_name) %>
  end

  # GET <%= route_url %>/1/edit
  def edit
  end

  # POST <%= route_url %>
  # POST <%= route_url %>.json
  def create
    @<%= singular_table_name %> = <%= orm_class.build(class_name, "#{singular_table_name}_params") %>

    respond_to do |format|
      if @<%= orm_instance.save %>
        format.html { redirect_to @<%= singular_table_name %>, notice: <%= "'#{human_name} was successfully created.'" %> }
        format.json { render :show, status: :created, location: @<%= singular_table_name %> }
      else
        format.html { render :new }
        format.json { render json: @<%= orm_instance.errors %>, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT <%= route_url %>/1
  # PATCH/PUT <%= route_url %>/1.json
  def update
    respond_to do |format|
      if @<%= orm_instance.update("#{singular_table_name}_params") %>
        format.html { redirect_to @<%= singular_table_name %>, notice: <%= "'#{human_name} was successfully updated.'" %> }
        format.json { render :show, status: :ok, location: @<%= singular_table_name %> }
      else
        format.html { render :edit }
        format.json { render json: @<%= orm_instance.errors %>, status: :unprocessable_entity }
      end
    end
  end

  # DELETE <%= route_url %>/1
  # DELETE <%= route_url %>/1.json
  def destroy
    respond_to do |format|
      if @<%= orm_instance.destroy %>
        format.html { redirect_to <%= index_helper %>_url, notice: <%= "'#{human_name} was successfully destroyed.'" %> }
        format.json { head :no_content }
      else
        format.html { redirect_to <%= index_helper %>_url, alert: <%= "\"#{human_name} failed to be destroyed: \#{@#{orm_instance.errors}.to_a}\"" %> }
        format.json { render json: @<%= orm_instance.errors %>, status: :internal_server_error }
      end
    end
  end

  # PUT <%= route_url %>/1/submit
  # PUT <%= route_url %>/1/submit.json
  def submit
    respond_to do |format|
      if @<%= singular_table_name %>.submitted?
        format.html { redirect_to <%= index_helper %>_url, alert: <%= "'#{human_name} has already been submitted.'" %> }
        format.json { head :no_content }
      elsif @<%= singular_table_name %>.submit
        format.html { redirect_to <%= index_helper %>_url, notice: <%= "'#{human_name} was successfully submitted.'" %> }
        format.json { head :no_content }
      else
        format.html { redirect_to <%= index_helper %>_url, alert: <%= "\"#{human_name} failed to be submitted: \#{@#{orm_instance.errors}.to_a}\"" %> }
        format.json { render json: @<%= orm_instance.errors %>, status: :internal_server_error }
      end
    end
  end

  # PUT <%= route_url %>/1/copy
  def copy
    @<%= singular_table_name %> = @<%= singular_table_name %>.copy

    respond_to do |format|
      if @<%= orm_instance.save %>
        format.html { redirect_to @<%= singular_table_name %>, notice: <%= "'#{human_name} was successfully copied.'" %> }
        format.json { render :show, status: :created, location: @<%= singular_table_name %> }
      else
        format.html { redirect_to <%= index_helper %>_url, alert: <%= "\"#{human_name} failed to be copied: \#{@#{orm_instance.errors}.to_a}\"" %> }
        format.json { render json: @<%= orm_instance.errors %>, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_<%= singular_table_name %>
      @<%= singular_table_name %> = <%= orm_class.find("#{class_name}.preload(:#{job.plural_name})", "params[:id]") %>
    end

    # Only allow a trusted parameter "white list" through.
    def <%= "#{singular_table_name}_params" %>
      <%- if attributes_names.empty? -%>
      params.fetch(:<%= singular_table_name %>, {})
      <%- else -%>
      params.require(:<%= singular_table_name %>).permit!
      <%- end -%>
    end
end
<% end -%>
