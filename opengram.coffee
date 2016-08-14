TelegramLogin = require './login'
config = require './config'
fs = require 'fs'

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
    console.error err

  sentCode: (client)=>
    console.log 'sent code called, reading code.txt'

  submitCode: (code)=>
    @login.signIn(code)

  signedIn: (userInfo)->
    console.log 'user logged in'
    console.log userInfo

  constructor: ->
    @login = new TelegramLogin()

    @login.once 'clientReady', @clientReady
    @login.once 'sentCode', @sentCode
    @login.on 'error', @onError
    @login.on 'userReady', @onUserReady
    @login.on 'signedIn', @signedIn

  init: ()=>
    @login.initClient()

og = new Opengram()
og.init()

setInterval ()->
  fs.exists './code.txt', (exists)->
    if exists
      console.log 'submitting code'
      og.submitCode('90077')
,5000
