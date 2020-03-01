# an account consists of an email address, a password, and a datafile
# the system will save all email addresses and pwds in an accounts file
# the system will create a datafile when accounts are created
class User
  attr_accessor :email, :pwd, :id

  def initialize(email, password, id)
    @email = email
    @pwd = password
    @id = id
  end

end
