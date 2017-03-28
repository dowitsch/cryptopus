module User::Authentication

  def authenticate(cleartext_password)
    return false if locked?
    return authenticate_ldap(cleartext_password) if ldap?
    return authenticate_api(cleartext_password) if auth_api?

    authenticate_db(cleartext_password)
  end

  private

  def authenticate_api(cleartext_api_key)
    return true if decrypted_private_key(cleartext_api_key)
    rescue
      return false
  end

  def authenticate_ldap(cleartext_password)
    LdapTools.ldap_login(username, cleartext_password)
  end

  def authenticate_db(cleartext_password)
    salt = password.split('$')[1]
    password.split('$')[2] == Digest::SHA512.hexdigest(salt+cleartext_password)
  end

end
