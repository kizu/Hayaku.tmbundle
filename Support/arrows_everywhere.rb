#*_*#

# for testing look at current support folder
require_support = ''
require_support = ENV['TM_BUNDLE_SUPPORT'] + '/' unless ENV['TM_BUNDLE_SUPPORT'].include? 'Ruby.tmbundle'

require require_support + 'ololo_dictionary.rb'
require ENV['TM_SUPPORT_PATH'] + '/lib/exit_codes.rb'
require ENV['TM_SUPPORT_PATH'] + '/lib/escape.rb'

def swapRule(property,value)
  if Modifier != 0
    foundValues = valuesOf(property)
    # must be no case-sensitive
    currentIndex = foundValues.index(value) if foundValues
    if currentIndex
      if Modifier < 0 
        newvalue = foundValues[currentIndex+1]
        newvalue = foundValues[0] if currentIndex == foundValues.length-1
      else
        newvalue = foundValues[currentIndex-1]
        newvalue = foundValues[-1] if currentIndex == 0
      end
    end
    # if there is a partial writing autocomplete it
    newvalue = foundValues[0] if !currentIndex and foundValues
  else
    newvalue = '${1:'+value+'}'
  end
  return newvalue if newvalue
  TextMate.exit_discard
end

def findRule()
  # get left and right part from caret position
  left = ''
  left = ENV['TM_CURRENT_LINE'].slice(0..ENV['TM_LINE_INDEX'].to_i-1) if ENV['TM_LINE_INDEX'].to_i > 0
  right = ENV['TM_CURRENT_LINE'].slice(ENV['TM_LINE_INDEX'].to_i..-1)

  result = left + "‸" + right

  # If caret is on property
  result.gsub!(/^(.*?)([a-z\-]*)‸([a-z\-]*)(:\s*)([^;]*)([;}].*)$/m){
    $1+$2+'${1}'+$3+$4+swapRule($2+$3,$5)+$6
  }

  # If caret is on value
  result.gsub!(/^(.*?)([a-z\-]*)(:\s*)([^;]*)‸([^;]*)([;}].*)$/m){
    rule = swapRule($2,$4+$5)
    whereTo = [$4.length,rule.length].min
    whereTo = rule.length if $5.length == 0
    $1+$2+$3+rule.insert(whereTo,'${1}')+$6
  }

  # If caret is after 
  result.gsub!(/^(.*?)([a-z\-]*)(:\s*)([^;]*)([;}].*)‸([^:]*)$/m){
    $1+$2+$3+swapRule($2,$4)+$5+'${1}'+$6
  }

  # Remove ordinal tabstop if editing
  result.gsub!('${1}','') if Modifier == 0

  # need escaping, whitespace at the ^ and better tabstops in value
  return result if !result.include?('‸')
end

if ENV['TM_SELECTED_TEXT']
  if ENV['TM_SELECTED_TEXT'].index(/^[\d\-\.]+$/)
    print "${0:"+ (ENV['TM_SELECTED_TEXT'].to_f + Modifier).to_s.gsub(/\.0$/,'') +"}"
  else
    TextMate.exit_discard
  end
else
  # get left and right part from caret position
  left = ''
  left = ENV['TM_CURRENT_LINE'].slice(0..ENV['TM_LINE_INDEX'].to_i-1) if ENV['TM_LINE_INDEX'].to_i > 0
  right = ENV['TM_CURRENT_LINE'].slice(ENV['TM_LINE_INDEX'].to_i..-1)

  if ENV['TM_CURRENT_WORD'].index(/\d/) and Modifier != 0
    # mark caret position for digit find
    result = left + "‸" + right
    if result.match(/(^|(?!\d)\w)‸((?:(?!\d)\w)*)(-?\d*\.?\d+|\d+(?:\.\d+)?)/)
      # if the caret is before number
      result.gsub!(/(^|(?!\d)\w)‸((?:(?!\d)\w)*)(-?\d*\.?\d+|\d+(?:\.\d+)?)/){
        $1 + $2 + ($3.to_f + Modifier).to_s.gsub(/\.0$/,'')
      }
    elsif result.match(/(-?\d*\.?\d+|\d+(?:\.\d+)?)((?:(?!\d)\w)*)‸($|(?!\d)\w)/)
      # if the caret is after number
      result.gsub!(/(-?\d*\.?\d+|\d+(?:\.\d+)?)((?:(?!\d)\w)*)‸((?!\d)\w|$)/){
        found = [$1,$2||'',$3||'']
        (found[0].to_f + Modifier).to_s.gsub(/\.0$/,'') + found[1] + found[2]
      }
    else
      # if the caret is in middle of number
      # need refactoring (
      result.gsub!(/([\w\-\.]*)‸([\w\-\.]*)/){
        ($1 + $2).gsub(/([\d\-\.]+)/){
          ($1.to_f + Modifier).to_s.gsub(/\.0$/,'')
        }
      }
    end
    # place caret after replace
    jumpIndex = ENV['TM_LINE_INDEX'].to_i + result.length - ENV['TM_CURRENT_LINE'].length
    jumpIndex = 0 if jumpIndex < 0
    result.insert(jumpIndex, '⦉${0}⦊')

    print e_sn(result).gsub('⦉\${0}⦊','${0}')
    
  else
    swapping = findRule() if ENV['TM_SCOPE'].include?('source.css') or ENV['TM_SCOPE'].include?('string.quoted.double.html') or ENV['TM_SCOPE'].include?('string.quoted.single.html')
    print swapping if swapping
    TextMate.exit_discard if !swapping
  end
end