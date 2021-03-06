class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable

  devise :omniauthable, omniauth_providers: [:facebook]

  has_many :groups,         inverse_of: :owner, foreign_key: :owner_id
  has_many :subscriptions,  through: :groups_users, source: :group
  has_many :groups_users,   class_name: "GroupUser", foreign_key: :member_id
  has_many :games,          through: :games_users, source: :game
  has_many :games_users,    class_name: "GameUser", foreign_key: :player_id

  scope :not_owner, ->(user) { where.not(id: user.id) }
  scope :with_address, ->() { where.not(longitude: nil).where.not(latitude: nil).where.not(address: nil) }

  geocoded_by      :address
  after_validation :geocode

  class << self
    def from_omniauth(auth)
      where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
        user.email    = auth.info.email || "#{auth.uid}@#{auth.provider}.com"
        user.password = Devise.friendly_token[0,20]
        user.name     = auth.info.name   # assuming the user model has a name
        user.avatar   = auth.info.image # assuming the user model has an image
        user.skip_confirmation!
      end
    end

    def new_with_session(params, session)
      super.tap do |user|
        if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
          user.email = data["email"] if user.email.blank?
        end
      end
    end

    def not_in_group(group)
      member_ids = group.members.pluck(:id)
      where.not(id: member_ids)
    end
  end

  def has_address?
    latitude.present? && longitude.present?
  end

  def has_not_address?
    !has_address?
  end

  def as_json(options)
    {
      links: { self: "/freaks/#{id}" },
      data: {
        latitude:  latitude,
        longitude: longitude,
        address:   address,
        name:      name,
        avatar:    avatar
      },
      meta: {}
    }
  end
end
