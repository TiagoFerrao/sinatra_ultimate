require 'yaml/store'
# require 'dropbox'
# dbx = Dropbox::Client.new(ENV['DROPBOX_ACCESS_TOKEN'])
# folder = dbx.create_folder('/myfolder') # => Dropbox::FolderMetadata
# folder.id

class UserStore

  def initialize(file_name)
    @store = YAML::Store.new(file_name)
  end

  # saves a new account to the YAML store under the users.rb-assigned id
  def save(account)
    @store.transaction do
      @store[account.id] = account
    end
  end

  def all
    @store.transaction do
      @store.roots.map { |id| @store[id] }
    end # the mapped array is returned by the block and thus by .transaction
  end

  # returns an array of all task IDs
  def ids
    @store.transaction do
      @store.roots
    end
  end

  # delete item entirely
  def delete_forever(id)
    @store.transaction do
      @store.delete(id)
    end
  end

  # given user email, return UserStore ID
  def id_from_email(email)
    @store.transaction do
      @store.roots.find { |id| @store[id].email == email }
    end
  end

end
