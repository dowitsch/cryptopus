# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.
class User < ActiveRecord::Base

  autoload 'Authentication', 'user/authentication'
  include User::Authentication

  validates :username, uniqueness: true
  validates :username, presence: true
  validates :username, length: { maximum: 20 }

  has_many :teammembers, dependent: :destroy
  has_many :recryptrequests, dependent: :destroy
  has_many :teams, -> { order :name }, through: :teammembers
  has_many :apikeys, foreign_key: :origin_user_id,
           class_name: User::ApiKey

  scope :locked, -> { where(locked: true) }
  scope :unlocked, -> { where(locked: false) }

  scope :admins, -> { where(admin: true) }

  default_scope { order('username') }

  before_destroy :protect_if_last_teammember, :destroy_api_keys

  class << self

    def create_db_user(password, user_params)
      user = new(user_params)
      user.auth = 'db'
      user.create_keypair password
      user.password = CryptUtils.one_way_crypt(password)
      user
    end

    def find_or_import_from_ldap(username, password)
      user = find_by(username: username.strip)

      return user if user

      if Setting.value(:ldap, :enable)
        return unless authenticate_ldap(username, password)
        create_from_ldap(username, password)
      end
    end

    def create_root(password)
      user = new(
        uid: 0,
        username: 'root',
        givenname: 'root',
        surname: '',
        auth: 'db',
        admin: true,
        password: CryptUtils.one_way_crypt(password)
      )
      user.create_keypair(password)
      user.save!
    end

    def root
      find_by(uid: 0)
    end

    private

    def authenticate_ldap(username, cleartext_password)
      LdapTools.ldap_login(username, cleartext_password)
    end

    def create_from_ldap(username, password)
      user = new
      user.username = username
      user.auth = 'ldap'
      user.uid = LdapTools.get_uid_by_username(username)
      user.create_keypair password
      user.update_info
      user
    rescue
      raise Exceptions::UserCreationFailed
    end
  end

  def last_teammember_in_any_team?
    last_teammember_teams.any?
  end

  def last_teammember_teams
    Team.where(id: Teammember.group('team_id').having('count(*) = 1').select('team_id'))
      .joins(:members).where('users.id = ?', id)
  end

  # Updates Information about the user
  def update_info
    update_info_from_ldap if ldap?
    update_attribute(:last_login_at, Time.now) # TODO: needed what for ? remove ?
  end

  def toggle_admin(actor, private_key)
    if self == actor || !actor.admin?
      raise 'user is not allowed to empower/disempower this user'
    end

    update(admin: !admin?)
    admin? ? empower(actor, private_key) : disempower
  end

  def toggle_api(actor, private_key)
    raise 'user is not allowed to activate/deactivate api for this user' if self != actor
    api_is_activated? ? deactivate_api : activate_api(private_key)
  end

  def create_keypair(password)
    keypair = CryptUtils.new_keypair
    uncrypted_private_key = CryptUtils.get_private_key_from_keypair(keypair)
    self.public_key = CryptUtils.get_public_key_from_keypair(keypair)
    self.private_key = CryptUtils.encrypt_private_key(uncrypted_private_key, password)
  end

  # rubocop:disable MethodLength
  def recrypt_private_key!(new_password, old_password)
    unless authenticate(new_password)
      errors.add(:base,
                 I18n.t('activerecord.errors.models.user.new_password_invalid'))
      return false
    end

    begin
      plaintext_private_key = CryptUtils.decrypt_private_key(private_key, old_password)
      CryptUtils.validate_keypair(plaintext_private_key, public_key)
      self.private_key = CryptUtils.encrypt_private_key(plaintext_private_key, new_password)
    rescue Exceptions::DecryptFailed
      errors.add(:base, I18n.t('activerecord.errors.models.user.old_password_invalid'))
      return false
    end
    save!
  end

  def label
    givenname.blank? ? username : "#{givenname} #{surname}"
  end

  def root?
    uid == 0
  end

  def ldap?
    auth == 'ldap'
  end

  def auth_db?
    auth == 'db'
  end

  def auth_api?
    auth == 'api'
  end

  def update_password(old, new)
    return if ldap?
    if authenticate_db(old)
      self.password = CryptUtils.one_way_crypt(new)
      pk = CryptUtils.decrypt_private_key(private_key, old)
      self.private_key = CryptUtils.encrypt_private_key(pk, new)
      save
    end
  end

  def migrate_legacy_private_key(password)
    decrypted_legacy_private_key = CryptUtilsLegacy.decrypt_private_key(private_key, password)
    newly_encrypted_private_key = CryptUtils.encrypt_private_key(decrypted_legacy_private_key, password)
    update_attribute(:private_key, newly_encrypted_private_key)
  end

  def decrypt_private_key(password)
    migrate_legacy_private_key(password) if legacy_private_key?
    CryptUtils.decrypt_private_key(private_key, password)
  rescue
    raise Exceptions::DecryptFailed
  end

  def accounts
    Account.joins(:group).
      joins('INNER JOIN teammembers ON groups.team_id = teammembers.team_id').
      where(teammembers: { user_id: id })
  end

  def legacy_password?
    return false if ldap?
    password.match('sha512').nil?
  end

  def groups
    Group.joins('INNER JOIN teammembers ON groups.team_id = teammembers.team_id').
      where(teammembers: { user_id: id })
  end

  def search_teams(term)
    teams.where('name like ?', "%#{term}%")
  end

  def search_groups(term)
    groups.where('name like ?', "%#{term}%")
  end

  def search_accounts(term)
    accounts
      .includes(group: [:team])
      .where('accountname like ? or accounts.description like ?', "%#{term}%", "%#{term}%")
  end

  def identify_account(identifier)
    accounts
      .includes(group: [:team])
      .where(identifier: identifier)
      .limit(1).first
  end

  def legacy_private_key?
    /^Salted/ !~ private_key
  end

  def unlock
    update!({locked: false, failed_login_attempts: 0})
  end

  def apikey
    apikeys.first
  end

  def api_is_activated?
    apikey.present?
  end

  private

  def empower(actor, private_key)
    teams = Team.where(teams: { private: false })

    teams.each do |t|
      next if t.teammember?(self)
      active_teammember = t.teammembers.find_by user_id: actor.id
      team_password = CryptUtils.decrypt_team_password(active_teammember.password, private_key)
      t.add_user(self, team_password)
    end
  end

  def disempower
    raise 'root can not be disempowered' if username == 'root'
    teammembers.joins(:team).where(teams: { private: false }).destroy_all
  end

  # Updates Information about the user from LDAP
  def update_info_from_ldap
    self.givenname = LdapTools.get_ldap_info(uid.to_s, 'givenname')
    self.surname   = LdapTools.get_ldap_info(uid.to_s, 'sn')
  end

  def protect_if_last_teammember
    !last_teammember_in_any_team?
  end

  def destroy_api_keys
    if type.nil?
      apikeys.each do |api|
        api.destroy
      end
    end
  end

  def activate_api(private_key)
    ActiveRecord::Base.transaction do
      apikey = User::ApiKey.new
      apikey.create(self, private_key)
    end
  end

  def deactivate_api
    self.apikey.destroy
  end

end
