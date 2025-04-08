class DataImport
  require "csv"

  # There are dependencies here.
  # Regions must be imported before providers

  def self.destroy_all_data
    Topic.destroy_all
    Provider.destroy_all
    Language.destroy_all
    Region.destroy_all
    User.destroy_all
  end

  def self.import_all
    import_regions
    import_providers
    import_languages
    # import_branches
    # import_contributors
    import_topics
    restore_default_users
  end

  def self.file_path(file_name)
    Rails.root.join("import_files", file_name)
  end

  def self.import_regions
    data = CSV.read(file_path("regions.csv"), headers: true)

    data.each do |row|
      region = Region.find_or_initialize_by(name: row["Region"])
      region.save! if region.new_record?

      puts "#{region.name} #{region.new_record? ? "created" : "already exists"}"
    end
  end

  def self.import_providers
    data = CSV.read(file_path("providers_obfuscated.csv"), headers: true)

    data.each do |row|
      # First, create the new provider
      provider = Provider.find_or_initialize_by(id: row["Provider_ID"])
      new_record = provider.new_record?
      if new_record
        provider.assign_attributes(
          name: row["Provider_Name"],
          provider_type: row["Provider_Type"],
        )
        provider.save!
      end
      puts "#{provider.name} #{new_record ? "created" : "already exists"}"

      # associate the provider with the region
      region_name = row["region_name"]
      region = Region.find_by(name: region_name)

      puts "Region #{region_name} not found" unless region
      provider.regions << region unless region.blank? || provider.regions.include?(region)

      # Then, create the user that will be associated with the provider
      puts "Creating user for #{provider.name}"
      user = User.find_by(email: "#{row["Provider_Name"]}@test.test")
      user = User.create(email: "#{row["Provider_Name"]}@test.test", password_digest: BCrypt::Password.create(row["Provider_Password"])) if user.blank?

      # Then, associate the user with the provider
      provider.users << user unless provider.users.include?(user)
    end
  end

  def self.import_languages
    [
      { name: "english" },
      { name: "spanish" },
    ].each do |language|
      language = Language.find_or_create_by!(language)
      puts "#{language.name} #{language.new_record? ? "created" : "already exists"}"
    end
  end

  def self.import_topics
    data = CSV.read(file_path("topics_obfuscated.csv"), headers: true)

    data.each do |row|
      # FIXME we need to search for LIKE name since the Topic_Language is 2 letter abbreviated
      language = Language.where("name like ?", "#{row["Topic_Language"]}%").first
      puts "Language #{row["Topic_Language"]} not found" unless language
      provider = Provider.find_by(id: row["Provider_ID"])
      created_year = [ row["Created_Year"].to_i, 2016 ].max
      created_month = [ row["Created_Month"].split("_").first.to_i, 1 ].max

      topic = Topic.find_or_initialize_by(id: row["Topic_ID"])
      # debugger if row["Topic_UID"].empty?
      # uid = row["Topic_UID"].nil? ? SecureRandom.uuid : row["Topic_UID"]
      topic.assign_attributes(
        id: row["Topic_ID"],
        title: row["Topic_Original_Title"],
        language: language,
        provider: provider,
        description: row["Topic_Desc"],
        published_at: DateTime.new(created_year, created_month, 1),
        # uid: uid,
        state: row["Topic_Archived"].to_i,
      )
      puts "#{topic.title} #{topic.new_record? ? "created" : "already exists"}"
      topic.save!
    end
  end

  def self.restore_default_users
    return if User.find_by_email("admin@email.com")

    admin = User.find_by(email: "admin@mail.com")
    if admin.nil?
      User.create!(email: "admin@mail.com", password: "test123", is_admin: true)
    end
    Provider.all.each do |provider|
      provider.users << admin unless provider.users.include?(admin)
    end

    me = User.find_by(email: "me@mail.com")
    if me.nil?
     me = User.create!(email: "me@mail.com", password: "test123")
    end

    Provider.first.users << me unless Provider.first.users.include?(me)
  end
end
