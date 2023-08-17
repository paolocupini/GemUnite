class CheckpointsController < ApplicationController
  before_action :set_variables, only: %i[ show edit update destroy change_state]
  before_action :is_member?
  before_action :is_leader?, only: %i[ new edit update destroy  ]
  before_action :project_started?, only: %i[ new edit update destroy create change_state ]



  def index
    @checkpoints = Checkpoint.all
  end

  def show
  end

  def new
    @checkpoint = Checkpoint.new
    @user = current_user
  end

  def edit
    @checkpoint = Checkpoint.find(params[:id])
    @tasks = @checkpoint.tasks
  end

  def create
    @checkpoint = Checkpoint.new(checkpoint_params)
    @project = Project.find(params[:project_id])
    @project.checkpoints << @checkpoint
    respond_to do |format|
      if @checkpoint.save
        format.html { redirect_to project_checkpoint_path(project_id: @project.id, id: @checkpoint.id), notice: "Checkpoint was successfully created." }
        format.json { render :show, status: :created, location: @checkpoint }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @checkpoint.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @checkpoint.destroy

    respond_to do |format|
      format.html { redirect_to project_show_my_project_path(project_id: @project.id), notice: "Checkpoint was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def update
    respond_to do |format|
      if @checkpoint.update(checkpoint_params)
        format.html { redirect_to project_checkpoint_path(project_id: @project.id, id: @checkpoint.id), notice: "Progetto was successfully updated." }
        format.json { render :show, status: :ok, location: @checkpoint }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @checkpoint.errors, status: :unprocessable_entity }
      end
    end
  end


  def change_state
    if @checkpoint.completato == true
      redirect_to project_show_my_project_path(project_id: @project.id), notice: "Checkpoint già completato"
    end
    completati = true
    @checkpoint.tasks.each do |task|
      if task.completato == false
        completati = false
      end
    end
    if completati
      @checkpoint.completato = true
      @checkpoint.save
      redirect_to project_show_my_project_path(project_id: @project.id)
    else
      redirect_to project_show_my_project_path(project_id: @project.id), notice: "Non puoi completare il checkpoint se non hai completato tutti i task"
    end
  end

  private

    def checkpoint_params
      params.require(:checkpoint).permit(:nome, :descrizione, :completato)
    end

    def set_variables
      @user = current_user
      parameter = params[:id] || params[:checkpoint_id]
      @checkpoint = Checkpoint.find(parameter)
      @tasks = @checkpoint.tasks
      @project = Project.find(@checkpoint.project_id)
      @role = UserProject.where(user_id: current_user.id, project_id: @project.id).first.role
    end

    def is_member?
      @user_project = UserProject.where(user_id: current_user.id, project_id: params[:project_id]).first
      if @user_project.nil?
        redirect_to my_projects_projects_path
        flash[:notice] = "Non sei membro di questo progetto"
      else
        @role = @user_project.role
      end
    end

    def is_leader?
      if @user_project.role != "leader"
        redirect_to my_projects_projects_path
        flash[:notice] = "Non sei il leader di questo progetto"
      end
    end

    def project_started?
      @project = Project.find(params[:project_id])
      if @project.stato == "aperto"
        redirect_to project_show_my_project_path(project_id: @project.id)
        flash[:notice] = "Il progetto non è ancora iniziato"
        return
      end

      if @project.stato == "chiuso"
        redirect_to project_show_my_project_path(project_id: @project.id)
        flash[:notice] = "Il progetto è chiuso"
        return
      end
    end


end
