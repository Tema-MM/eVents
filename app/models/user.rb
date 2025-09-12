class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]
  has_many :purchases, dependent: :destroy 
  ## Custom fields
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6, maximum: 128 }, if: :password_required?

  scope :admins, -> { where(admin: true) }

  def self.from_omniauth(access_token)
       data = access_token.info
       user = User.where(email: data['email']).first

       # Uncomment the section below if you want users to be created if they don't exist
       unless user
         user = User.create(
           first_name: data['first_name'],
           last_name: data['last_name'],
           email: data['email'],
           password: Devise.friendly_token[0,20]
         )
       end
       user
  end

end
