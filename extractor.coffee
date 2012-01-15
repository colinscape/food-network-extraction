#!/usr/bin/env coffee

_ = require 'underscore'
request = require 'request'
htmlparser = require 'htmlparser'
soup = require 'soupselect'


justText = (node) ->
  separator = '~~~'
  text = ''
  if node.type is 'text' then text = node.data

  if node.children?
    for child in node.children
      childText = justText child
      text = "#{text}#{separator}#{childText}"

  niceText = text.replace ///[\r\n\t ]///, ' '
  words = niceText.split separator
  realWords = _.filter words, (x) -> x.length isnt 0
  nicerText = realWords.join ''
  evenNicerText = nicerText.replace ///\ +///, ' '
  return evenNicerText


decodeIngredient  = (text) ->

  regexp = /^([0-9 \/]+ [^ ]+)?([^,]*)(, .*)?/
  matches = text.match regexp

  console.log text
  console.log JSON.stringify matches


extractIngredients = (name, link, cb) ->

  request.get link, (error, response, body) ->
    if not error and response.statusCode is 200
      handler = new htmlparser.DefaultHandler (err, dom) ->
        if err
          console.log "Error parsing html: #{err}"
        else
          info = []
          ingredients = soup.select dom, 'li.ingredient'
          ingredients.forEach (ingredient) ->
            text = justText ingredient
            info.push text

          recipe =
            name: name
            ingredients: info
          cb recipe

      parser = new htmlparser.Parser handler
      parser.parseComplete body


gatherRecipes = (recipe) ->
  console.log "---=== #{recipe.name} ===---"
  console.log ingredient for ingredient in recipe.ingredients
  console.log ''


findRecipes = (query) ->
  searchPage = "http://www.foodnetwork.com/search/delegate.do?fnSearchString=#{encodeURIComponent query}&fnSearchType=recipe"
  request.get searchPage, (error, response, body) ->
    if not error and response.statusCode is 200

      handler = new htmlparser.DefaultHandler (err, dom) ->
        if err
          console.log "Error parsing html: #{err}"
        else
          recipes = soup.select dom, '.result-item h3 a'
          recipes.forEach (recipe) ->
            name = recipe.children[0].raw
            link = "http://www.foodnetwork.com/#{recipe.attribs.href}"
            extractIngredients name, link, gatherRecipes

      parser = new htmlparser.Parser handler
      parser.parseComplete body

    else
      console.log "Problem getting page #{searchPage}"


query = process.argv[2]
findRecipes query