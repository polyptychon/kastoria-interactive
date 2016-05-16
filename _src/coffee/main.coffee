global.$ = global.jQuery = $ = require "jquery"

require "bootstrap/assets/javascripts/bootstrap/transition"
require "bootstrap/assets/javascripts/bootstrap/affix"
require "bootstrap/assets/javascripts/bootstrap/tab"
require "bootstrap/assets/javascripts/bootstrap/dropdown"
require "bootstrap/assets/javascripts/bootstrap/collapse"

data = require('./data')
GoogleMapsLoader = require('google-maps')

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
)

setMarkers = ()->
  data.forEach((point, index)->
    setTimeout(()=>
      marker = addMarker(point)
      selectMarker(marker) if index==0
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

addMarker = (point)->
  marker = new google.maps.Marker({
    map: map,
    draggable: true,
    animation: google.maps.Animation.DROP,
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
    map.panTo(position);
    selectedMarker.setAnimation(null) if (selectedMarker != null && selectedMarker!=marker)
    marker.setAnimation(google.maps.Animation.BOUNCE)
    selectedMarker = marker

handleMarkerClick = (event)->
  selectMarker(event.latLng)

