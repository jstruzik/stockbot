Slack = require 'slack-client'
pg = require 'pg'
fs = require 'fs'

data = fs.readFileSync './config/database.json'
db_config = JSON.parse(data)

env = if process.env['NODE_ENV'] then process.env['NODE_ENV'] else db_config.defaultEnv
pg_user = if process.env['PG_USER'] then process.env['PG_USER'] else db_config[env].user
pg_pwd = if process.env['PG_PWD'] then process.env['PG_PWD'] else db_config[env].password
host = if process.env['DATABASE_URL'] then process.env['DATABASE_URL'] else db_config[env].host
db = db_config[env].database
connectionString = "tcp://" + pg_user + ":" + pg_pwd + "@" + host + "/" + db

slackToken = process.env['SLACK_TOKEN'] # Add a bot at https://my.slack.com/services/new/bot and copy the token here.
autoReconnect = true # Automatically reconnect after an error response from Slack.
autoMark = true # Automatically mark each message as read after it is processed.

slack = new Slack(slackToken, autoReconnect, autoMark)

pg.connect connectionString, (err, pgClient) ->
  return console.log "Error! #{err}" if err?

slack.on 'open', ->
  channels = []
  groups = []
  unreads = slack.getUnreadCount()

  # Get all the channels that bot is a member of
  channels = ("##{channel.name}" for id, channel of slack.channels when channel.is_member)

  # Get all groups that are open and not archived 
  groups = (group.name for id, group of slack.groups when group.is_open and not group.is_archived)

  console.log "Welcome to Slack. You are @#{slack.self.name} of #{slack.team.name}"
  console.log 'You are in: ' + channels.join(', ')
  console.log 'As well as: ' + groups.join(', ')

  messages = if unreads is 1 then 'message' else 'messages'

  console.log "You have #{unreads} unread #{messages}"


slack.on 'message', (message) ->
  channel = slack.getChannelGroupOrDMByID(message.channel)
  user = slack.getUserByID(message.user)
  response = ''

  {type, ts, text} = message

  channelName = if channel?.is_channel then '#' else ''
  channelName = channelName + if channel then channel.name else 'UNKNOWN_CHANNEL'

  userName = if user?.name? then "@#{user.name}" else "UNKNOWN_USER"

  console.log """
    Received: #{type} #{channelName} #{userName} #{ts} "#{text}"
  """

  # Respond to messages with the reverse of the text received.
  if type is 'message' and text? and channel?
    response = process_message_text text
    #channel.send response
    console.log """
      @#{slack.self.name} responded with "#{response}"
    """
  else
    #this one should probably be impossible, since we're in slack.on 'message' 
    typeError = if type isnt 'message' then "unexpected type #{type}." else null
    #Can happen on delete/edit/a few other events
    textError = if not text? then 'text was undefined.' else null
    #In theory some events could happen with no channel
    channelError = if not channel? then 'channel was undefined.' else null

    #Space delimited string of my errors
    errors = [typeError, textError, channelError].filter((element) -> element isnt null).join ' '

    console.log """
      @#{slack.self.name} could not respond. #{errors}
    """

process_message_text = (text) ->
  action_pattern = /// ^ #begin of line
   (buy|sell)\s          #"buy" or "sell"
   (\d+)                 #number of shares
   \sshares\sof\s        #"shares of"
   (\$\w+)               #the $STOCK
   ///i                  #ignore case

  [_, action, shares, stock] = text.match action_pattern

  console.log """
    I've #{action} #{shares} into #{stock} 
  """

slack.on 'error', (error) ->
  console.error "Error: #{error}"


#slack.login()