global.$ = global.jQuery = $ = require "jquery"

require "bootstrap/assets/javascripts/bootstrap/transition"
require "bootstrap/assets/javascripts/bootstrap/affix"
require "bootstrap/assets/javascripts/bootstrap/tab"
require "bootstrap/assets/javascripts/bootstrap/dropdown"
require "bootstrap/assets/javascripts/bootstrap/collapse"
require "bootstrap/assets/javascripts/bootstrap/carousel"

data = require('./data')

Keyboard = {
  ENTER: 13,
  SPACE: 32,
  PREVIOUS: 37,
  UP: 38,
  NEXT: 39,
  DOWN: 40
};

GoogleMapsLoader = require('google-maps')
GoogleMapsLoader.KEY = 'AIzaSyD8y7IJNTgRSwbnoR-I1OopiRU721SZg3k'
GoogleMapsLoader.VERSION = '3.14'
GoogleMapsLoader.LANGUAGE = 'el'
GoogleMapsLoader.REGION = 'GR';

mapOptions = {
  zoom: 16
  center: {lat: 40.519118, lng: 21.268211}
  styles: [{"featureType":"all","elementType":"all","stylers":[{"hue":"#ffaa00"},{"saturation":"-33"},{"lightness":"10"}]},{"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#9c5e18"}]},{"featureType":"landscape.natural.terrain","elementType":"geometry","stylers":[{"visibility":"simplified"}]},{"featureType":"poi","elementType":"all","stylers":[{"visibility":"off"}]},{"featureType":"poi.attraction","elementType":"all","stylers":[{"visibility":"off"}]},{"featureType":"poi.business","elementType":"labels","stylers":[{"visibility":"off"}]},{"featureType":"poi.government","elementType":"all","stylers":[{"visibility":"off"}]},{"featureType":"poi.place_of_worship","elementType":"all","stylers":[{"visibility":"off"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"visibility":"simplified"}]},{"featureType":"road.highway","elementType":"labels.text","stylers":[{"visibility":"on"}]},{"featureType":"road.arterial","elementType":"geometry","stylers":[{"visibility":"simplified"}]},{"featureType":"transit.line","elementType":"all","stylers":[{"visibility":"off"}]},{"featureType":"water","elementType":"geometry.fill","stylers":[{"saturation":"-23"},{"gamma":"2.01"},{"color":"#f2f6f6"}]},{"featureType":"water","elementType":"geometry.stroke","stylers":[{"saturation":"-14"}]}]
  disableDefaultUI: true
}
map = null
google = null
selectedMarker = null

if (env!="production")
  kinectGestures = require('./KinectGestures.coffee')
  afterGesture = ()->
    hideHelp()

  kinectGestures.on("swipe_left", ()->
    if !$('body').hasClass('show-help')
      selectNextMarker() if !$('body').hasClass('gallery-zoom')
      $('.info-item.active').find('.carousel').carousel('next') if $('body').hasClass('gallery-zoom')
    afterGesture()
  )
  kinectGestures.on("swipe_right", ()->
    if !$('body').hasClass('show-help')
      selectPreviousMarker() if !$('body').hasClass('gallery-zoom')
      $('.info-item.active').find('.carousel').carousel('prev') if $('body').hasClass('gallery-zoom')
    afterGesture()
  )
  kinectGestures.on("swipe_in", ()->
    unsetGalleryMode() if !$('body').hasClass('show-help')
    afterGesture()
  )
  kinectGestures.on("swipe_out", ()->
    setGalleryMode() if !$('body').hasClass('show-help')
    afterGesture()
  )
  kinectGestures.on("swipe_down", ()->
    toggleLanguage() if !$('body').hasClass('show-help')
    afterGesture()
  )

  kinectGestures.on("swipe_left", ()->

  )
if (env=="production")
  $('body').addClass('production')

  $('.info-gallery').bind('click', ()->
    if $('body').hasClass('gallery-zoom')
      unsetGalleryMode()
    else
      setGalleryMode()
  )

try
  $('.help video')[0].pause()
catch

handleKeyup = (event)->
  if (event.keyCode==Keyboard.PREVIOUS)
    selectPreviousMarker() if !$('body').hasClass('gallery-zoom')
    $('.info-item.active').find('.carousel').carousel('prev') if $('body').hasClass('gallery-zoom')
  else if (event.keyCode==Keyboard.NEXT)
    selectNextMarker() if !$('body').hasClass('gallery-zoom')
    $('.info-item.active').find('.carousel').carousel('next') if $('body').hasClass('gallery-zoom')
  else if (event.keyCode==Keyboard.UP)
    setGalleryMode()
  else if (event.keyCode==Keyboard.DOWN)
    unsetGalleryMode()
  else if (event.keyCode==Keyboard.ENTER)
    if $('body').hasClass('show-help')
      hideHelp()
    else
      showHelp()
  else if (event.keyCode==Keyboard.SPACE)
    toggleLanguage()

hideHelp = ()->
  try
    $('body').removeClass('show-help')
    $('.help video')[0].pause()
  catch

showHelp = ()->
  try
    $('body').addClass('show-help')
    $('.help video')[0].play()
  catch

toggleLanguage = ()->
  $('body').toggleClass('en')

zoomingTimeout = -1
smoothZoom = ()->
  $('body').addClass('gallery-zooming')
  clearTimeout(zoomingTimeout)
  zoomingTimeout = setInterval(()->
    $('body').removeClass('gallery-zooming')
  , 500)

setGalleryMode = ()->
  smoothZoom()
  $('body').addClass('gallery-zoom')
  $('.info-item.active').find('.carousel').carousel({interval:1000000000})
  $('.info-item.active').find('.carousel').carousel('pause')

unsetGalleryMode = ()->
  smoothZoom()
  $('body').removeClass('gallery-zoom')
  $('.info-item.active').find('.carousel').carousel({interval:5000})

getData = () ->
  data.filter((point) -> point.properties['category-slug']==window.FILTER || window.FILTER=='')


GoogleMapsLoader.load((g)->
  initMaps(g)
)


initMaps = (g)->
  google = g
  map = new google.maps.Map($('.map')[0], mapOptions)
  setMarkers()
  google.maps.event.addListenerOnce(map,"bounds_changed", ()-> selectMarker(getData()[0].marker))
  $(global).unbind('keyup').bind('keyup', handleKeyup)

setMarkers = ()->
  getData()
    .forEach((point, index)->
      setTimeout(()=>
        addMarker(point)
      , index * 100)
    )

round = (value) ->
  Math.round(value * 100000) / 100000

getMarkerByPosition = (position) ->
  lat = position.lat()
  lng = position.lng()
  filteredData = getData().filter((point)->
    return round(point.geometry.coordinates[1]) == round(lat) && round(point.geometry.coordinates[0]) == round(lng)
  )
  return if filteredData.length==1 then filteredData[0] else null

getIcon = (url='assets/images/church-red.png', w=30, h=34)->
  return {
    url: url
    size: new google.maps.Size(w, h)
    origin: new google.maps.Point(0, 0)
    anchor: new google.maps.Point(w/2, h)
    scaledSize: new google.maps.Size(w, h)
  }

addMarker = (point)->
  marker = new google.maps.Marker({
    map: map
    draggable: true
    animation: google.maps.Animation.DROP
    icon: getIcon()
    position: {lat: point.geometry.coordinates[1], lng: point.geometry.coordinates[0]}
  })
  point.marker = marker
  marker.addListener('click', handleMarkerClick)
  return marker

resetMarker = (marker)->
  return if !marker
  marker.setZIndex(100)
  marker.setIcon(getIcon())
  marker.setAnimation(null) if (selectedMarker!=marker)

selectMarker = (value) ->
  position =
    if value.getPosition
      value.getPosition()
    else if value.marker
      value.marker.getPosition()
    else
      value
  markerData = getMarkerByPosition(position)
  if markerData?
    marker = markerData.marker
    panToCenter(position)
    resetMarker(selectedMarker)
    marker.setAnimation(google.maps.Animation.BOUNCE)
    setTimeout(()->
      marker.setAnimation(null)
    , 1000)
    marker.setZIndex(1000)
    selectedMarker = marker
    marker.setIcon(getIcon('assets/images/church-yellow.png'))
    index = data.indexOf(markerData)
    $('.info-item.active').find('.carousel').carousel({interval:1000000000})
    $('.info-item.active').find('.carousel').carousel('pause')
    $('.info-item.active').removeClass('active')
    $('.info-item').eq(index).addClass('active')
    $('.info-item').eq(index).find('.carousel').carousel({interval:5000})
#    setData(markerData)

handleMarkerClick = (event)->
  selectMarker(event.latLng)

getImageArrayFromData = (markerData)->
  a = []
  l = parseInt(markerData.properties.images, 10)
  categorySlug = markerData.properties['category-slug']
  slug = markerData.properties.slug
  for num in [1..l]
    a.push({src:"assets/photos/#{categorySlug}/#{slug}/Image#{num}.jpg"})
  return a

setData = (markerData)->
  infoData = {
    images: getImageArrayFromData(markerData),
    title:markerData.properties.name,
    description:markerData.properties.description
  }
  $('.info').html require('../templates/partials/info.jade')(infoData)
  $('.carousel').carousel()

selectPreviousMarker = ()->
  return if !selectedMarker
  marker = getMarkerByPosition(selectedMarker.getPosition())
  currentIndex = getData().indexOf(marker)
  previousIndex = if currentIndex-1<0 then getData().length-1 else currentIndex-1
  selectMarker(getData()[previousIndex])

selectNextMarker = ()->
  return if !selectedMarker
  marker = getMarkerByPosition(selectedMarker.getPosition())
  currentIndex = getData().indexOf(marker)
  nextIndex = if currentIndex+1>=getData().length then 0 else currentIndex+1
  selectMarker(getData()[nextIndex])

panToCenter = (latlng) ->
  offsetx = - ($(global).width() - $('.info').width())/2
  offsety = 0
  scale = Math.pow(2, map.getZoom());

  worldCoordinateCenter = map.getProjection().fromLatLngToPoint(latlng);
  pixelOffset = new google.maps.Point((offsetx/scale) || 0,(offsety/scale) ||0)

  worldCoordinateNewCenter = new google.maps.Point(
    worldCoordinateCenter.x - pixelOffset.x,
    worldCoordinateCenter.y + pixelOffset.y
  )

  newCenter = map.getProjection().fromPointToLatLng(worldCoordinateNewCenter)
  map.panTo(newCenter)
