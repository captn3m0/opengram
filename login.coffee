#
# Module TelegramLogin
#
# Handels the whole login.
#
# Events:
# - clientReady -> first param: complete client object
# - userReady   -> first param: complete client object
#                  second param: userInfo object {telnum, phone_code_hash, code}
# - error       -> first param: error object
# - sentCode    -> no params
# - signedIn    -> first param: userInfo object {telnum, phone_code_hash, code}
#


#
# Imports
#
EventEmitter = require 'events'
config = require './config'
fs = require 'fs'
telegramLink = require 'telegram.link'

#
# Module code
#
module.exports =
  class TelegramLogin extends EventEmitter
    userInfo:
      {
        telNum: null
        phone_code_hash: null
        code: null
      }

    authExists: ->
      return fs.existsSync(config.files.auth)

    userInfoExists: ->
      return fs.existsSync(config.files.userInformation)

    initClient: ->
      console.log 'initClient'
      if @authExists()
        @restoreClient()
      else
        @createClient()

    restoreClient: =>
      console.log 'restoreClient'
      content = fs.readFileSync(config.files.auth)
      authKey = telegramLink.retrieveAuthKey content, 'password'

      @client =
      telegramLink.createClient({
        id: config.api_id
        hash: config.api_hash
        version: config.version
        lang: 'en'
        authKey: authKey
        connectionType: 'HTTP'
      }
        config.dc.prod)

      if @userInfoExists()
        @restoreUserInfo()
      else
        @emit('clientReady', @client)

    createClient: =>
      @client = telegramLink.createClient({
        id: config.api_id
        hash: config.api_hash
        version: config.version
        lang: 'en'
        connectionType: 'HTTP'
      }
        config.dc.prod)

      @client.createAuthKey(@saveAuth)

    saveAuth: (auth) =>
      content = auth.key.encrypt 'password'
      fs.writeFileSync config.files.auth, content

      @emit('clientReady', @client)

    checkPhoneAndSendCode: (telNum) =>
      console.log 'sending phone check request'
      @userInfo.telNum = telNum
      @client.auth.checkPhone(telNum, @afterCheckPhone)

    afterCheckPhone: (res) =>
      console.log 'phone checked'

      if res.error_code?
        @client.getDataCenters (dcs)->
          console.log dcs
      else
        console.log 'sending code after checking phone'
        @sendCode()

    sendCode: =>
      console.log 'sending code'
      @client.auth.sendCode '+919639516176', 5, 'en', @sentCode

    sentCode: (res) =>
      console.log 'CODE SENT'
      if res.error_code?
        @emit('error', res)
      else
        console.log "We got a response"
        console.log res.phone_code_hash
        console.log res
        @userInfo.phone_code_hash = res.phone_code_hash
        @emit('sentCode')

    signIn: (code) =>
      @userInfo.code = code

      console.log @userInfo
      @client.auth.signIn(
        @userInfo.telNum
        @userInfo.phone_code_hash
        @userInfo.code
        @afterSignIn
      )

    afterSignIn: (res) =>
      if res.error_code?
        @emit('error', res)
      else
        @storeUserInfo(@userInfo)
        @emit('signedIn', @userInfo)

    storeUserInfo: (userInfo) ->
      output = userInfo.telNum + ','
      + userInfo.phone_code_hash + ','
      + userInfo.code
      fs.writeFileSync(config.files.userInformation,
        output, 'utf8')

    restoreUserInfo: =>
      console.log 'restoreUserInfo'
      userInfoBuffer =
        fs.readFileSync(config.files.userInformation,
          'utf8').split(',')
      console.log @emit(
        'userReady'
        @client
        {
          telNum: userInfoBuffer[0]
          phone_code_hash: userInfoBuffer[1]
          code: userInfoBuffer[2]
        }
      )
