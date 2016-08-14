TelegramLogin = require './login'
config = require './config'

class Opengram
  clientReady: (c)=>
    console.log 'client ready called'
    @login.checkPhoneAndSendCode config.phone, (e)->
      console.log 'phone code sent!!!'
      console.log e

  onUserReady: (client, userInfo)->
    @userInfo = userInfo
    console.log 'logged in'

  onError: (err)->
    console.log err

  sentCode: (client)=>
    setInterval ()->
      code = fs.readFileSync 'code.txt'

  submitCode: (code)=>
    @login.signIn(code)

  constructor: ->
    @login = new TelegramLogin()

    @login.once 'clientReady', @clientReady
    @login.once 'sentCode', @sentCode
    @login.on 'error', @onError
    @login.on 'userReady', @onUserReady

  init: ()=>
    @login.initClient()

og = new Opengram()
og.init()

setInterval ()->
  console.log 'waiting'
,5000
