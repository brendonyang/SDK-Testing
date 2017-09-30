{
  title: "Namely extension",

  connection: {
    fields: [
      { name: "company", control_type: :subdomain, url: ".namely.com", optional: false,
        hint: "If your Namely URL is https://acme.namely.com then use acme as value." },
      { name: "client_id", label: "Client ID", control_type: :password, optional: false },
      { name: "client_secret", control_type: :password, optional: false }
    ],

    authorization: {
      type: "oauth2",

      authorization_url: lambda do |connection|
        params = {
          response_type: "code",
          client_id: connection["client_id"],
          redirect_uri: "https://www.workato.com/oauth/callback",
        }.to_param
        "https://#{connection["company"]}.namely.com/api/v1/oauth2/authorize?" + params
      end,

      acquire: lambda do |connection, auth_code|
        response = post("https://#{connection["company"]}.namely.com/api/v1/oauth2/token").
                     payload(
                       grant_type: "authorization_code",
                       client_id: connection["client_id"],
                       client_secret: connection["client_secret"],
                       code: auth_code).
                     request_format_www_form_urlencoded
        [ response, nil, nil ]
      end,

      refresh_on: [401, 403],

      refresh: lambda do |connection, refresh_token|
        post("https://#{connection["company"]}.namely.com/api/v1/oauth2/token").
          payload(
            grant_type: "refresh_token",
            client_id: connection["client_id"],
            client_secret: connection["client_secret"],
            refresh_token: refresh_token,
            redirect_uri: "https://www.workato.com/oauth/callback").
          request_format_www_form_urlencoded
      end,

      apply: lambda do |connection, access_token|
        headers("Authorization": "Bearer #{access_token}")
      end
    }
  },

  object_definitions: {
    profile: {
      fields: ->() {
        [
          { name: "profiles", type: :array, of: :object, properties: [
            { name: "id", label: "ID" },
            { name: "email" },
            { name: "first_name" },
            { name: "last_name" },
            { name: "user_status" },
            { name: "updated_at", type: :integer },
            { name: "created_at" },
            { name: "preferred_name" },
            { name: "full_name" },
            { name: "job_title", type: :object, properties: [
              { name: "id", label: "ID" },
              { name: "title" }
            ]},
            { name: "reports_to", type: :object, properties: [
              { name: "id", label: "ID" },
              { name: "first_name" },
              { name: "last_name" },
              { name: "email" }
            ]},
            { name: "employee_type", type: :object, properties: [
              { name: "title" }
            ]},
            { name: "access_role" },
            { name: "ethnicity" },
            { name: "middle_name" },
            { name: "gender" },
            { name: "job_change_reason" },
            { name: "start_date" },
            { name: "departure_date" },
            { name: "employee_id", label: "Employee ID" },
            { name: "personal_email" },
            { name: "dob", label: "Date of birth"},
            { name: "ssn", label: "SSN" },
            { name: "marital_status" },
            { name: "bio" },
            { name: "asset_management" },
            { name: "laptop_asset_number" },
            { name: "corporate_card_number" },
            { name: "key_tag_number" },
            { name: "linkedin_url" },
            { name: "office_main_number" },
            { name: "office_direct_dial" },
            { name: "office_phone" },
            { name: "office_fax" },
            { name: "office_company_mobile" },
            { name: "home_phone" },
            { name: "mobile_phone" },
            { name: "home", type: :object, properties: [
              { name: "address1" },
              { name: "address2" },
              { name: "city" },
              { name: "state_id", label: "State ID" },
              { name: "country_id", label: "Country ID" },
              { name: "zip" }
            ]},
            { name: "office", type: :object, properties: [
              { name: "address1" },
              { name: "address2" },
              { name: "city" },
              { name: "state_id", label: "State ID" },
              { name: "country_id", label: "Country ID"},
              { name: "zip" },
              { name: "phone" }
            ]},
            { name: "emergency_contact" },
            { name: "emergency_contact_phone" },
            { name: "resume" },
            { name: "current_job_description" },
            { name: "job_description" },
            { name: "salary", type: :object, properties: [
              { name: "currency_type" },
              { name: "date" },
              { name: "guid", label: "GUID" },
              { name: "pay_group_id", label: "Pay group ID", type: :integer },
              { name: "payroll_job_id", label: "Payroll job ID" },
              { name: "rate" },
              { name: "yearly_amount", type: :integer },
              { name: "is_hourly", label: "Is hourly?", type: :boolean },
              { name: "amount_raw", label: "Raw amount" } ] },
            { name: "healthcare", type: :object, properties: [
              { name: "beneficiary" },
              { name: "amount" },
              { name: "currency_type" }
            ]},
            { name: "healthcare_info" },
            { name: "dental", type: :object, properties: [
              { name: "beneficiary" },
              { name: "amount" },
              { name: "currency_type" }
            ]},
            { name: "dental_info" },
            { name: "vision_plan_info" },
            { name: "life_insurance_info" },
            { name: "namely_time_employee_role" },
            { name: "namely_time_manager_role" }
          ]},
        ]
      }
    },
    event: {
      fields: ->() {
        [
          { name: "id", label: "ID" },
          { name: "href", label: "URL" },
          { name: "type" },
          { name: "time", type: :integer },
          { name: "utc_offset", type: :integer },
          { name: "content" },
          { name: "html_content" },
          { name: "years_at_company", type: :integer },
          { name: "use_comments", label: "Use comments?", type: :boolean },
          { name: "can_comment", label: "Can comment?", type: :boolean },
          { name: "can_destroy", label: "Can destroy?", type: :boolean },
          { name: "links", type: :object, properties: [
            { name: "profile" },
            { name: "comments", type: :array, of: :string },
            { name: "file" },
            { name: "appreciations", type: :array, of: :string },
          ]},
          { name: "can_like", label: "Can like?", type: :boolean },
          { name: "likes_count", type: :integer },
          { name: "liked_by_current_profile", type: :boolean },
        ]
      }
    }
  },

  test: ->(connection) {
    get("https://#{connection["company"]}.namely.com/api/v1/profiles/me")
  },

  actions: {
    search_employee_profiles: {
      description: 'Search <span class="provider">employee profiles</span> '\
                   'in <span class="provider">Namely</span>',
      subtitle: "Search employee profiles in Namely",
      hint: "Use the input fields to add filters to employee profile results. "\
            "Leave input fields blank to return all employee profiles.",

      input_fields: lambda do
        [
          { name: "first_name", optional: true, sticky: true },
          { name: "last_name", optional: true, sticky: true },
          { name: "email", label: "Company email", optional: true, sticky: true },
          { name: "personal_email", optional: true },
          { name: "job_title", optional: true },
          { name: "reports_to", optional: true,
            hint: "ID of employee profile whom employee profile reports to" },
          { name: "status", optional: true, control_type: :select,
            pick_list: "employee_status", toggle_hint: "Select from list",
            toggle_field: {
              name: "status", type: :string, control_type: :text,
              label: "Status (Custom)", toggle_hint: "Use custom value"
            }
          },
          { name: "start_date", type: :date, optional: true }
        ]
      end,

      execute: lambda do |connection, input|
        params = (input["first_name"].present? ? "&filter[first_name]=#{input["first_name"]}" : "") +
                 (input["last_name"].present? ? "&filter[last_name]=#{input["last_name"]}" : "") +
                 (input["email"].present? ? "&filter[email]=#{input["email"]}" : "") +
                 (input["personal_email"].present? ? "&filter[personal_email]=#{input["personal_email"]}" : "") +
                 (input["job_title"].present? ? "&filter[job_title]=#{input["job_title"]}" : "") +
                 (input["reports_to"].present? ? "&filter[reports_to]=#{input["reports_to"]}" : "") +
                 (input["status"].present? ? "&filter[user_status]=#{input["user_status"]}" : "")

        employees = get("https://#{connection["company"]}.namely.com/api/v1/profiles.json?" +
                      params)["profiles"].to_a
        if input["start_date"].present?
          employees = employees.where("start_date" => input["start_date"].to_s)
        end
        { "profiles": employees }
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["profile"]
      end,

      sample_output: lambda do |connection|
        {
          "profiles": get("https://#{connection["company"]}.namely.com/api/v1/profiles.json").
                        params(
                          page: 1,
                          per_page: 1)["profiles"].to_a.values
        }
      end
    }
  },

  triggers: {}
}