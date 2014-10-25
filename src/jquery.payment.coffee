$            = jQuery
$.payment    = {}
$.payment.fn = {}
$.fn.payment = (method, args...) ->
  $.payment.fn[method].apply(this, args)

# Utils

defaultFormat = /(\d{1,4})/g

cards = [
  # Debit cards must come first, since they have more
  # specific patterns than their credit-card equivalents.
  {
      type: 'naranja',
      pattern: /^((402917)|(402918)|(527571)|(527572))/,
      format: defaultFormat,
      length: [16],
      cvcLength: [3],
      luhn: true
  }
  {
      type: 'naranja',
      pattern: /^(589562)/,
      format: defaultFormat,
      length: [16],
      cvcLength: [3],
      luhn: true
  }
  {
      type: 'nativa',
      pattern: /^(546553)/,
      format: defaultFormat,
      length: [16],
      cvcLength: [3],
      luhn: true
  }
  {
      type: 'tarshop',
      pattern: /^(603488)/,
      format: defaultFormat,
      length: [16],
      cvcLength: [3],
      luhn: true
  }
  {
      type: 'tarshop',
      pattern: /^(27995)/,
      format: defaultFormat,
      length: [13],
      cvcLength: [0],
      luhn: false
  } 
  {
      type: 'cencosud',
      pattern: /^(603493)/,
      format: defaultFormat,
      length: [16],
      cvcLength: [3],
      luhn: true
  } 
  {
      type: 'cabal',
      pattern: /^((627170)|(589657)|(603522)|(604((20[1-9])|(2[1-9][0-9])|(3[0-9]{2})|(400))))/,
      format: defaultFormat,
      length: [16],
      cvcLength: [3],
      luhn: true
  } 
  {
      type: 'argencard',
      pattern: /^(501105)/,
      format: defaultFormat,
      length: [16],
      cvcLength: [3],
      luhn: true
  }
  {
      type: 'diners',
      pattern: /^(36)/,
      format: defaultFormat,
      length: [14],
      cvcLength: [3],
      luhn: true
  }
  {
      type: 'hipercard',
      pattern: /^(606282)/,
      format: defaultFormat,
      length: [16],
      cvcLength: [3],
      luhn: true
  }
  {
      type: 'elo',
      pattern: /^((636368)|(438935)|(506726)|(457631)|(401178)|(506727)|(506742)|(506741)|(506778)|(457632)|(506744)|(636297)|(627780))/,
      format: defaultFormat,
      length: [16],
      cvcLength: [3],
      luhn: true
  }
  {
      type: 'melicard',
      pattern: /^((530032)|(522499))/,
      format: defaultFormat,
      length: [16],
      cvcLength: [3],
      luhn: true
  }   
  {
      type: 'visa',
      pattern: /^4/,
      format: defaultFormat,
      length: [16],
      cvcLength: [3],
      luhn: true
  } 
  {
      type: 'master',
      pattern: /^5/,
      format: defaultFormat,
      length: [16],
      cvcLength: [3],
      luhn: true
  } 
  {
      type: 'amex',
      pattern: /^3/,
      format: /(\d{1,4})(\d{1,6})?(\d{1,5})?/,
      length: [15],
      cvcLength: [4],
      luhn: true
  }
]

cardFromNumber = (num) ->
  num = (num + '').replace(/\D/g, '')
  return card for card in cards when card.pattern.test(num)

cardFromType = (type) ->
  return card for card in cards when card.type is type

luhnCheck = (num) ->
  odd = true
  sum = 0

  digits = (num + '').split('').reverse()

  for digit in digits
    digit = parseInt(digit, 10)
    digit *= 2 if (odd = !odd)
    digit -= 9 if digit > 9
    sum += digit

  sum % 10 == 0

hasTextSelected = ($target) ->
  # If some text is selected
  return true if $target.prop('selectionStart')? and
    $target.prop('selectionStart') isnt $target.prop('selectionEnd')

  # If some text is selected in IE
  return true if document?.selection?.createRange?().text

  false

# Private

# Format Card Number

reFormatCardNumber = (e) ->
  setTimeout ->
    $target = $(e.currentTarget)
    value   = $target.val()
    value   = $.payment.formatCardNumber(value)
    $target.val(value)

formatCardNumber = (e) ->
  # Only format if input is a number
  digit = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  $target = $(e.currentTarget)
  value   = $target.val()
  card    = cardFromNumber(value + digit)
  length  = (value.replace(/\D/g, '') + digit).length

  upperLength = 16
  upperLength = card.length[card.length.length - 1] if card
  return if length >= upperLength

  # Return if focus isn't at the end of the text
  return if $target.prop('selectionStart')? and
    $target.prop('selectionStart') isnt value.length

  if card && card.type is 'amex'
    # AMEX cards are formatted differently
    re = /^(\d{4}|\d{4}\s\d{6})$/
  else
    re = /(?:^|\s)(\d{4})$/

  # If '4242' + 4
  if re.test(value)
    e.preventDefault()
    setTimeout -> $target.val(value + ' ' + digit)

  # If '424' + 2
  else if re.test(value + digit)
    e.preventDefault()
    setTimeout -> $target.val(value + digit + ' ')

formatBackCardNumber = (e) ->
  $target = $(e.currentTarget)
  value   = $target.val()

  # Return unless backspacing
  return unless e.which is 8

  # Return if focus isn't at the end of the text
  return if $target.prop('selectionStart')? and
    $target.prop('selectionStart') isnt value.length

  # Remove the trailing space
  if /\d\s$/.test(value)
    e.preventDefault()
    setTimeout -> $target.val(value.replace(/\d\s$/, ''))
  else if /\s\d?$/.test(value)
    e.preventDefault()
    setTimeout -> $target.val(value.replace(/\s\d?$/, ''))

# Format Expiry

reFormatExpiry = (e) ->
  setTimeout ->
    $target = $(e.currentTarget)
    value   = $target.val()
    value   = $.payment.formatExpiry(value)
    $target.val(value)

formatExpiry = (e) ->
  # Only format if input is a number
  digit = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  $target = $(e.currentTarget)
  val     = $target.val() + digit

  if /^\d$/.test(val) and val not in ['0', '1']
    e.preventDefault()
    setTimeout -> $target.val("0#{val} / ")

  else if /^\d\d$/.test(val)
    e.preventDefault()
    setTimeout -> $target.val("#{val} / ")

formatForwardExpiry = (e) ->
  digit = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  $target = $(e.currentTarget)
  val     = $target.val()

  if /^\d\d$/.test(val)
    $target.val("#{val} / ")

formatForwardSlashAndSpace = (e) ->
  which = String.fromCharCode(e.which)
  return unless which is '/' or which is ' '

  $target = $(e.currentTarget)
  val     = $target.val()

  if /^\d$/.test(val) and val isnt '0'
    $target.val("0#{val} / ")

formatBackExpiry = (e) ->
  $target = $(e.currentTarget)
  value   = $target.val()

  # Return unless backspacing
  return unless e.which is 8

  # Return if focus isn't at the end of the text
  return if $target.prop('selectionStart')? and
    $target.prop('selectionStart') isnt value.length

  # Remove the trailing space
  if /\s\/\s\d?$/.test(value)
    e.preventDefault()
    setTimeout -> $target.val(value.replace(/\s\/\s\d?$/, ''))

#  Restrictions

restrictNumeric = (e) ->
  # Key event is for a browser shortcut
  return true if e.metaKey or e.ctrlKey

  # If keycode is a space
  return false if e.which is 32

  # If keycode is a special char (WebKit)
  return true if e.which is 0

  # If char is a special char (Firefox)
  return true if e.which < 33

  input = String.fromCharCode(e.which)

  # Char is a number or a space
  !!/[\d\s]/.test(input)

restrictCardNumber = (e) ->
  $target = $(e.currentTarget)
  digit   = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  return if hasTextSelected($target)

  # Restrict number of digits
  value = ($target.val() + digit).replace(/\D/g, '')
  card  = cardFromNumber(value)

  if card
    value.length <= card.length[card.length.length - 1]
  else
    # All other cards are 16 digits long
    value.length <= 16

restrictExpiry = (e) ->
  $target = $(e.currentTarget)
  digit   = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  return if hasTextSelected($target)

  value = $target.val() + digit
  value = value.replace(/\D/g, '')

  return false if value.length > 6

restrictCVC = (e) ->
  $target = $(e.currentTarget)
  digit   = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  return if hasTextSelected($target)

  val     = $target.val() + digit
  val.length <= 4

setCardType = (e) ->
  $target  = $(e.currentTarget)
  val      = $target.val()
  cardType = $.payment.cardType(val) or 'unknown'

  unless $target.hasClass(cardType)
    allTypes = (card.type for card in cards)

    $target.removeClass('unknown')
    $target.removeClass(allTypes.join(' '))

    $target.addClass(cardType)
    $target.toggleClass('identified', cardType isnt 'unknown')
    $target.trigger('payment.cardType', cardType)

# Public

# Formatting

$.payment.fn.formatCardCVC = ->
  @payment('restrictNumeric')
  @on('keypress', restrictCVC)
  this

$.payment.fn.formatCardExpiry = ->
  @payment('restrictNumeric')
  @on('keypress', restrictExpiry)
  @on('keypress', formatExpiry)
  @on('keypress', formatForwardSlashAndSpace)
  @on('keypress', formatForwardExpiry)
  @on('keydown',  formatBackExpiry)
  @on('change', reFormatExpiry)
  @on('input', reFormatExpiry)
  this

$.payment.fn.formatCardNumber = ->
  @payment('restrictNumeric')
  @on('keypress', restrictCardNumber)
  @on('keypress', formatCardNumber)
  @on('keydown', formatBackCardNumber)
  @on('keyup', setCardType)
  @on('paste', reFormatCardNumber)
  @on('change', reFormatCardNumber)
  @on('input', reFormatCardNumber)
  @on('input', setCardType)
  this

# Restrictions

$.payment.fn.restrictNumeric = ->
  @on('keypress', restrictNumeric)
  this

# Validations

$.payment.fn.cardExpiryVal = ->
  $.payment.cardExpiryVal($(this).val())

$.payment.cardExpiryVal = (value) ->
  value = value.replace(/\s/g, '')
  [month, year] = value.split('/', 2)

  # Allow for year shortcut
  if year?.length is 2 and /^\d+$/.test(year)
    prefix = (new Date).getFullYear()
    prefix = prefix.toString()[0..1]
    year   = prefix + year

  month = parseInt(month, 10)
  year  = parseInt(year, 10)

  month: month, year: year

$.payment.validateCardNumber = (num) ->
  num = (num + '').replace(/\s+|-/g, '')
  return false unless /^\d+$/.test(num)

  card = cardFromNumber(num)
  return false unless card

  num.length in card.length and
    (card.luhn is false or luhnCheck(num))

$.payment.validateCardExpiry = (month, year) ->
  # Allow passing an object
  if typeof month is 'object' and 'month' of month
    {month, year} = month

  return false unless month and year

  month = $.trim(month)
  year  = $.trim(year)

  return false unless /^\d+$/.test(month)
  return false unless /^\d+$/.test(year)
  return false unless 1 <= month <= 12

  if year.length == 2
    if year < 70
      year = "20#{year}"
    else
      year = "19#{year}"

  return false unless year.length == 4

  expiry      = new Date(year, month)
  currentTime = new Date

  # Months start from 0 in JavaScript
  expiry.setMonth(expiry.getMonth() - 1)

  # The cc expires at the end of the month,
  # so we need to make the expiry the first day
  # of the month after
  expiry.setMonth(expiry.getMonth() + 1, 1)

  expiry > currentTime

$.payment.validateCardCVC = (cvc, type) ->
  cvc = $.trim(cvc)
  return false unless /^\d+$/.test(cvc)

  card = cardFromType(type)
  if card?
    # Check against a explicit card type
    cvc.length in card.cvcLength
  else
    # Check against all types
    cvc.length >= 3 and cvc.length <= 4

$.payment.cardType = (num) ->
  return null unless num
  cardFromNumber(num)?.type or null

$.payment.formatCardNumber = (num) ->
  card = cardFromNumber(num)
  return num unless card

  upperLength = card.length[card.length.length - 1]

  num = num.replace(/\D/g, '')
  num = num[0...upperLength]

  if card.format.global
    num.match(card.format)?.join(' ')
  else
    groups = card.format.exec(num)
    return unless groups?
    groups.shift()
    groups = $.grep(groups, (n) -> n) # Filter empty groups
    groups.join(' ')

$.payment.formatExpiry = (expiry) ->
  parts = expiry.match(/^\D*(\d{1,2})(\D+)?(\d{1,4})?/)
  return '' unless parts

  mon = parts[1] || ''
  sep = parts[2] || ''
  year = parts[3] || ''

  if year.length > 0 || (sep.length > 0 && !(/\ \/?\ ?/.test(sep)))
    sep = ' / '

  if mon.length == 1 and mon not in ['0', '1']
    mon = "0#{mon}"
    sep = ' / '

  return mon + sep + year
