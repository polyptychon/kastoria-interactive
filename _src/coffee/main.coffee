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
  data.forEach((point, index)->
    setTimeout(()->
      addMarker(point)
    , index * 100)
  )
)

round = (value) ->
  Math.round(value * 1000000) / 1000000

getMarker = (position) ->
  lat = position.lat()
  lng = position.lng()
  filteredData = data.filter((point)->
    return round(point.geometry.coordinates[1]) == round(lat) && round(point.geometry.coordinates[0]) == round(lng)
  )
  return filteredData[0]

addMarker = (point)->
  marker = new google.maps.Marker({
    map: map,
    draggable: true,
    animation: google.maps.Animation.DROP,
    position: {lat: point.geometry.coordinates[1], lng: point.geometry.coordinates[0]}
  })
  point.marker = marker
  marker.addListener('click', toggleBounce)

toggleBounce = (event)->
  markerData = getMarker(event.latLng)
  if (markerData?)
    marker = markerData.marker
    map.panTo(event.latLng);
    selectedMarker.setAnimation(null) if (selectedMarker != null)
    if (marker.getAnimation() != null)
      marker.setAnimation(null);
    else
      marker.setAnimation(google.maps.Animation.BOUNCE)
      selectedMarker = marker
