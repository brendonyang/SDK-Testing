{
  title: 'Harvest',

  connection: {
    fields: [
      {
        name: "client_id",
        label: "Client ID",
        optional: false,
        hint: "You can find your client ID " \
          "<a href='https://id.getharvest.com/developers' " \
          "target='_blank'>here</a>"
      },
      {
        name: "client_secret",
        label: "Client Secret",
        control_type: "password",
        optional: false, 
        hint: "You can find your client secret " \
          "<a href='https://id.getharvest.com/developers' " \
          "target='_blank'>here</a>"
      }
    ],

    authorization: {
      type: 'oauth2',

      authorization_url: lambda do |connection| 
        response = "https://id.getharvest.com/oauth2/authorize?" \
          "client_id=#{connection["client_id"]}&response_type=code"
      end,

      acquire: lambda do |connection, auth_code|
        response = post("https://id.getharvest.com/api/v2/oauth2/token").
          payload(
            code: auth_code,
            client_id: connection["client_id"],
            client_secret: connection["client_secret"],
            grant_type: "authorization_code"
          ).
          request_format_www_form_urlencoded

        [
          {
            access_token: response["access_token"],
            refresh_token: response["refresh_token"]
          },
          nil,
          nil
        ]
      end,

      refresh_on: [403],

      refresh: lambda do |connection, refresh_token|
        post("https://id.getharvest.com/api/v2/oauth2/token").
          payload(
            grant_type: "refresh_token",
            client_id: connection["client_id"],
            client_secret: connection["client_secret"],
            refresh_token: refresh_token,
            redirect_uri: "https://www.workato.com/oauth/callback"
          ).
          request_format_www_form_urlencoded
      end,

      apply: lambda do |connection, access_token|
        headers("Authorization": "Bearer #{access_token}")
      end
    },
  },

  object_definitions: {
    client: {
      fields: ->() {
        [
          { name: 'id', type: :integer },
          { name: 'name' },
          { name: 'is_active', type: :boolean },
          { name: 'address' },
          { name: 'created_at', type: :datetime },
          { name: 'updated_at', type: :datetime },
          { name: 'currency' }
        ]
      }
    },

    time_entry: {
      fields: ->() {
        [
          { name: 'id', type: :integer },
          { name: 'spent_date', type: :date },
          { 
            name: 'user', 
            type: :object,
            properties: 
              [
                { name: 'id', type: :integer },
                { name: 'name' }
              ]
          },
          { 
            name: 'client', 
            type: :object,
            properties: 
              [
                { name: 'id', type: :integer },
                { name: 'name' }
              ]
          },
          { 
            name: 'project', 
            type: :object,
            properties: 
              [
                { name: 'id', type: :integer },
                { name: 'name' }
              ]
          },
          { 
            name: 'task', 
            type: :object,
            properties: 
              [
                { name: 'id', type: :integer },
                { name: 'name' }
              ]
          },
          { 
            name: 'user_assignment', 
            type: :object,
            properties: 
			  [
                { name: 'id', type: :integer },
                { name: 'is_project_manager', type: :boolean },
                { name: 'is_active', type: :boolean },
                { name: 'budget', type: :number },
                { name: 'created_at', type: :date_time },
                { name: 'updated_at', type: :date_time },
                { name: 'hourly_rate', type: :number }
              ]
          },
          { 
            name: 'task_assignment', 
            type: :object,
            properties: 
              [
                { name: 'id', type: :integer },
                { name: 'billable', type: :boolean },
                { name: 'is_active', type: :boolean },
                { name: 'created_at', type: :date_time },
                { name: 'updated_at', type: :date_time },
                { name: 'hourly_rate', type: :number },
                { name: 'budget', type: :number }
              ]
          },
          { name: 'hours', type: :number },
          { name: 'notes' },
          { name: 'created_at', type: :date_time },
          { name: 'updated_at', type: :date_time },
          { name: 'is_locked', type: :boolean },
          { name: 'locked_reason' },
          { name: 'is_closed', type: :boolean },
          { name: 'is_billed', type: :boolean },
          { name: 'timer_started_at' , type: :datetime },
          { name: 'started_time', type: :timestamp },
          { name: 'ended_time', type: :timestamp },
          { name: 'is_running', type: :boolean },
          { 
            name: 'invoice', 
            type: :object,
            properties: 
              [
                { name: 'id', type: :integer },
                { name: 'number' }
              ]
          },
          { 
            name: 'external_reference', 
            type: :object,
            properties: 
			  [
                { name: 'id', type: :integer },
                { name: 'group_id', type: :integer },
                { name: 'permalink' },
                { name: 'service' },
                { name: 'service_icon_url' },
                { name: 'number' }
              ]
          },
          { name: 'billable', type: :boolean },
          { name: 'budgeted', type: :boolean },
          { name: 'billable_rate', type: :number },
          { name: 'cost_rate', type: :number },      
        ]
      }
    }
  },

  actions: {
    get_time_entries: {
	  help: "Fetchs time entries of a specified date. Returns all " \
	    "time entries if left blank. Returns a maximum of 100 records.",
		
      input_fields: ->() {
        [
          { 
            name: "account_id", 
            type: "select", 
            control_type: "select",
            pick_list: "account_id",
            optional: false,
            hint: "Account to list clients from"
          },
          { 
            name: "from", 
            type: "date", 
            sticky: true 
          },
		  { 
            name: "to", 
            type: "date", 
            sticky: true 
          }
        ]
      },

      execute: lambda do |connection, input|
	    #API cap per page is 100.
		# from_time = input["from"] != "" ? input["from"].to_time.utc.iso8601 : ""
		# to_time = input["to"] != "" ? input["to"].to_time.utc.iso8601 : ""
        time_entries = get("https://api.harvestapp.com/v2/time_entries").
                         params(from: input["from"].to_time.utc.iso8601,
                                to: input["to"].to_time.utc.iso8601,
                                per_page: 100).
                         headers("Harvest-Account-Id": input["account_id"])
      end,

      output_fields: ->(object_definitions) {
        object_definitions['time_entry']
      }
    },

    get_recent_clients: {
      help: "Fetchs clients that are last modified after a " \
        "specified time. Returns a maximum of 100 records.",

      input_fields: ->() {
        [
          { 
            name: "account_id", 
            type: "select", 
            control_type: "select",
            pick_list: "account_id",
            optional: false,
            hint: "Account to list clients from"
          },
          { 
            name: 'updated_since', 
            type: "timestamp", 
            hint: "Defaults to 1 hour ago if left blank" },
        ]
      },

      execute: lambda do |connection, input|
        #API cap per page is 100.
        clients = get("https://api.harvestapp.com/v2/clients").
                    params(updated_since: input["updated_since"].to_time.utc.iso8601,
                           per_page: 100).
                    headers("Harvest-Account-Id": input["account_id"])
      end,
      
      output_fields: lambda do |object_definitions|
        [
          { 
            name: "clients", 
            type: "array",
            of: "object", 
            properties: object_definitions['client'] 
          }
        ]
      end,
    }
  },

  triggers: {
    new_or_updated_client: {
    # API returns clients sorted by descending creation date.
      type: :paging_desc,

      input_fields: ->() {
        [
          { 
            name: "since", 
            type: "timestamp", 
			sticky: true,
            hint: "Defaults to 1 hour ago if left blank"
          },
		  { 
            name: "account_id", 
            type: "select", 
            control_type: "select",
            pick_list: "account_id",
            optional: false,
            hint: "Account to list clients from"
          },
          { 
            name: "is_active", 
            type: "boolean", 
            control_type: "select",
            pick_list: "active",
            hint: "True for active, False for inactive"
          }
        ]
      },

      poll: lambda do |connection, input, page| 
        created_since = ( input['since'] || (now - 1.hours) )
        page ||= 1
        limit = 100
        clients = get("https://api.harvestapp.com/v2/clients").
                    params(updated_since: created_since.to_time.utc.iso8601,
                           is_active: input["is_active"],
                           page: page,
                           per_page: limit).
                    headers("Harvest-Account-Id": input["account_id"])
      
        {
          events: clients["clients"],
          next_page: clients["next_page"]
        }
		
      end,
      
      dedup: lambda do |client|
        client["id"]
      end,
      
      output_fields: ->(object_definitions) {
        object_definitions["client"]
      }
    }
  },
  
  pick_lists: {
    account_id: lambda do |connection|
      get("https://id.getharvest.com/api/v2/accounts")["accounts"].
        map { |account| [account["name"], account["id"]] }
    end,
    active: lambda do |_connection|
      [
        ["True", "true"],
        ["False", "false"]
      ]
    end
  }
}