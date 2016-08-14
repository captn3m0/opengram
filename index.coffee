fs = require('fs')
telegramLink = require('telegram.link')()
config = require('./config')
AuthKey = require('telegram-mt-node/lib/auth/auth-key')

conf =
  id      : config.api_id
  hash    : config.api_hash
  version : '1.0.0'
  lang    : 'EN',
  connectionType: 'UDP'

client = null

fs.readFile "./auth.json", (err, content)->
  if (!err)
    conf.authKey = telegramLink.retrieveAuthKey(content,'password')

  client = telegramLink.createClient conf, config.dc.prod, (err)->
    client.createAuthKey()

  client.on 'authKeyCreate', (auth)->
    console.log 'authKeyCreated'
    authKey = auth.key.encrypt('password')

    fs.writeFile "./auth.json", authKey, (err)->
      if(!err)
        client.emit('signin.ready')

  client.on 'connect', (err)->
    console.log 'connected'
    client.createAuthKey()

  switchDataCenter = (toDC,f)->
    data.client.getDataCenters (dcs)->
      console.log dcs

  phoneCallback = (result)->
    console.log 'phoneCallback called'


  signinEmitted = false

  client.on 'sendCode', ()->
    console.log 'sendCode cb called'

  client.on 'signin.ready', ()->
    console.log 'signin.ready emitted'

    if signinEmitted
      console.log 'firing sendCode'
      client.auth.sendCode config.phone, 5, 'en', (result)->
        console.log result
        if (result.error_code == 303)
          console.log "switching data centers"
          switchDataCenter result.error_message.slice(-1)
        else
          console.log "got a result into phoneCallback"
          console.log result
        console.log 'phoneCallback done with'

    signinEmitted = true

  client.on 'error', (err)->
    console.log err
