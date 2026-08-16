class UsersController < ApplicationController
  before_action :set_user, only: %i[ show update destroy ]
  before_action :set_deleted_user, only: %i[ restore ]

  # GET /users
  def index
    users = User.all
    render json: paginate(users), each_serializer: UserSerializer
  end

  # GET /users/:id
  def show
    render json: @user
  end

  # POST /users
  def create
    @user = User.create!(**form.to_h)
    render json: @user, status: :created, location: @user
  end

  # PATCH/PUT /users/:id
  def update
    @user.update!(**form.to_h.compact)
    render json: @user
  end

  # DELETE /users/:id
  def destroy
    raise ForbiddenError, "You cannot delete your own account" if @user == current_user
    @user.soft_delete!
  end

  # PATCH /users/:id/restore
  def restore
    @user.restore!
    render json: @user
  end

  private

  def set_user
    @user = User.find(params.expect(:id))
  end

  def set_deleted_user
    @user = User.deleted.find(params.expect(:id))
  end

  def form
    params_hash = params.expect(user: [ :username, :name, :password, :role ]).to_h.symbolize_keys
    UserForm.new(**params_hash)
  end
end
