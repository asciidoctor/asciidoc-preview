path = require 'path'
_ = require 'underscore-plus'
cheerio = require 'cheerio'
{$, EditorView} = require 'atom'
Asciidoctor = require('asciidoctorjs-npm-wrapper').Asciidoctor
Opal = require('asciidoctorjs-npm-wrapper').Opal

exports.toHtml = (text, filePath, callback) ->

  defaultAttributes = atom.config.get('asciidoc-preview.defaultAttributes')

  numbered = if atom.config.get('asciidoc-preview.showNumberedHeadings') then 'numbered' else 'numbered!'
  showtitle = if atom.config.get('asciidoc-preview.showTitle') then 'showtitle' else 'showtitle!'
  showtoc = if atom.config.get('asciidoc-preview.showToc')  then 'toc=preamble toc2!' else 'toc! toc2!'
  safemode = atom.config.get('asciidoc-preview.safeMode') or "safe"
  doctype = atom.config.get('asciidoc-preview.docType') or "article"


  attributes = defaultAttributes.concat(' icons=font@ ').concat(numbered).concat(' ').concat(showtitle).concat(' ').concat(showtoc)
  console.log('AsciiDoc attributes: '.concat(attributes))
  Opal.ENV['$[]=']("PWD", path.dirname(window.location.href))
  opts = Opal.hash2(['base_dir', 'safe', 'doctype', 'attributes'], {
      'base_dir': 'file://'.concat(path.dirname(filePath)),
      'safe': safemode,
      'doctype': doctype,
      'attributes': attributes
  });

  html = Asciidoctor.$convert(text, opts)
  html = sanitize(html)
  html = resolveImagePaths(html, filePath)

  callback(html)

exports.toText = (text, filePath, callback) ->
  exports.toHtml text, filePath, (error, html) ->
    if error
      callback(error)
    else
      string = $(document.createElement('div')).append(html)[0].innerHTML
      callback(error, string)

sanitize = (html) ->
  o = cheerio.load(html)
  o('script').remove()
  attributesToRemove = [
    'onabort'
    'onblur'
    'onchange'
    'onclick'
    'ondbclick'
    'onerror'
    'onfocus'
    'onkeydown'
    'onkeypress'
    'onkeyup'
    'onload'
    'onmousedown'
    'onmousemove'
    'onmouseover'
    'onmouseout'
    'onmouseup'
    'onreset'
    'onresize'
    'onscroll'
    'onselect'
    'onsubmit'
    'onunload'
  ]
  o('*').removeAttr(attribute) for attribute in attributesToRemove
  o.html()

resolveImagePaths = (html, filePath) ->
  html = $(html)
  for imgElement in html.find("img")
    img = $(imgElement)
    if src = img.attr('src')
      continue if src.match /^(https?:\/\/)/
      img.attr('src', path.resolve(path.dirname(filePath), src))

  html
