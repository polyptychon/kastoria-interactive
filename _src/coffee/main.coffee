global.$ = global.jQuery = $ = require "jquery"

require "bootstrap/assets/javascripts/bootstrap/transition"
require "bootstrap/assets/javascripts/bootstrap/affix"
require "bootstrap/assets/javascripts/bootstrap/tab"
require "bootstrap/assets/javascripts/bootstrap/dropdown"
require "bootstrap/assets/javascripts/bootstrap/collapse"
require "bootstrap/assets/javascripts/bootstrap/carousel"

data = require('./data')
GoogleMapsLoader = require('google-maps')

Keyboard = {
  ENTER: 13,
  SPACE: 32,
  PREVIOUS: 37,
  UP: 38,
  NEXT: 39,
  DOWN: 40
};

GoogleMapsLoader.KEY = 'AIzaSyD8y7IJNTgRSwbnoR-I1OopiRU721SZg3k'
GoogleMapsLoader.VERSION = '3.14'
GoogleMapsLoader.LANGUAGE = 'el'
GoogleMapsLoader.REGION = 'GR';

mapOptions = {
  zoom: 16
  center: {lat: 40.519118, lng: 21.268211}
  disableDefaultUI: true
}
map = null
google = null
selectedMarker = null

GoogleMapsLoader.load((g)->
  google = g
  map = new google.maps.Map($('.map')[0], mapOptions)
  setMarkers()
  google.maps.event.addListenerOnce(map,"bounds_changed", ()-> selectMarker(data[0].marker))
  $(global).bind('keyup', handleKeyup)
)

handleKeyup = (event)->
  if (event.keyCode==Keyboard.PREVIOUS)
    selectPreviousMarker()
  else if (event.keyCode==Keyboard.NEXT)
    selectNextMarker()

setMarkers = ()->
  data.forEach((point, index)->
    setTimeout(()=>
      addMarker(point)
    , index * 100)
  )

round = (value) ->
  Math.round(value * 100000) / 100000

getMarkerByPosition = (position) ->
  lat = position.lat()
  lng = position.lng()
  filteredData = data.filter((point)->
    return round(point.geometry.coordinates[1]) == round(lat) && round(point.geometry.coordinates[0]) == round(lng)
  )
  return if filteredData.length==1 then filteredData[0] else null

getIcon = (url='assets/images/church-red.png')->
  return {
    url: url
    size: new google.maps.Size(30, 34)
    origin: new google.maps.Point(0, 0)
    anchor: new google.maps.Point(15, 34)
    scaledSize: new google.maps.Size(30, 34)
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
    selectedMarker.setIcon(getIcon()) if selectedMarker
    selectedMarker.setAnimation(null) if (selectedMarker && selectedMarker!=marker)
    marker.setAnimation(google.maps.Animation.BOUNCE)
    selectedMarker = marker
    marker.setIcon(getIcon('assets/images/church-yellow.png'))
    setData(markerData)

handleMarkerClick = (event)->
  selectMarker(event.latLng)

setData = (markerData)->
  infoData = {
    images:[
      {src: "assets/images/Sample-image-Ag-Anargiroi.jpg"},
      {src: "assets/images/Sample-image-Ag-Anargiroi.jpg"}
    ],
    title:markerData.properties.name,
    description:markerData.properties.description
  }
  $('.info').html require('../templates/partials/info.jade')(infoData)

selectPreviousMarker = ()->
  marker = getMarkerByPosition(selectedMarker.getPosition())
  currentIndex = data.indexOf(marker)
  previousIndex = if currentIndex-1<0 then data.length-1 else currentIndex-1
  selectMarker(data[previousIndex])

selectNextMarker = ()->
  marker = getMarkerByPosition(selectedMarker.getPosition())
  currentIndex = data.indexOf(marker)
  nextIndex = if currentIndex+1>=data.length then 0 else currentIndex+1
  selectMarker(data[nextIndex])

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
