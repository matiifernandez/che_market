class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable, :confirmable

  # Roles
  enum role: { customer: 0, admin: 1 }

  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :nullify
end
