global.$ = global.jQuery = $ = require "jquery"

require "bootstrap/assets/javascripts/bootstrap/transition"
require "bootstrap/assets/javascripts/bootstrap/affix"
require "bootstrap/assets/javascripts/bootstrap/tab"
require "bootstrap/assets/javascripts/bootstrap/dropdown"
require "bootstrap/assets/javascripts/bootstrap/collapse"
require "bootstrap/assets/javascripts/bootstrap/carousel"


getRightHandRelativePosition = (user)->
  rightHandRelativePosition = 5
  if user.tracked
    rightHandPosition = Math.floor(user.joints[11].depthX * 100)
    torsoPosition = Math.floor(user.joints[1].depthX * 100)
    rightHandRelativePosition = rightHandPosition - torsoPosition
  return rightHandRelativePosition

_bodyFrame = null
checkNextGestureTimeouts = {
  "0": -1,
  "1": -1,
  "2": -1,
  "3": -1,
  "4": -1,
  "5": -1,
}
checkPreviousGestureTimeouts = {
  "0": -1,
  "1": -1,
  "2": -1,
  "3": -1,
  "4": -1,
  "5": -1,
}
socket = require('socket.io-client')('http://localhost:8000');

socket.on('bodyFrame', (bodyFrame)->
  _bodyFrame = bodyFrame
  bodyFrame.bodies.forEach((user,index)->
    trackUser(user,index)
  )
)

trackUser = (user, index)->
  if user.tracked
    rightHandRelativePosition = getRightHandRelativePosition(user)
    if rightHandRelativePosition>15
      clearTimeout(checkNextGestureTimeouts[index])
      checkNextGestureTimeouts[index] = setTimeout(()->
        clearTimeout(checkNextGestureTimeouts[index])
        checkNextGesture(rightHandRelativePosition, index)
      , 300)

    if rightHandRelativePosition<=0
      clearTimeout(checkPreviousGestureTimeouts[index])
      checkPreviousGestureTimeouts[index] = setTimeout(()->
        clearTimeout(checkPreviousGestureTimeouts[index])
        checkPreviousGesture(rightHandRelativePosition, index)
      , 300)

checkNextGesture = (oldPosition, index)->
  rightHandRelativePosition = getRightHandRelativePosition(_bodyFrame.bodies[index])
  speed = oldPosition-rightHandRelativePosition
  selectNextMarker() if (speed>20)

checkPreviousGesture = (oldPosition, index)->
  rightHandRelativePosition = getRightHandRelativePosition(_bodyFrame.bodies[index])
  speed = rightHandRelativePosition+oldPosition
  selectPreviousMarker() if (speed>20)

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

getData = () ->
  data.filter((point) -> point.properties['category-slug']==FILTER && FILTER!='')

GoogleMapsLoader.load((g)->
  google = g
  map = new google.maps.Map($('.map')[0], mapOptions)
  setMarkers()
  google.maps.event.addListenerOnce(map,"bounds_changed", ()-> selectMarker(getData()[0].marker))
  $(global).bind('keyup', handleKeyup)
)

handleKeyup = (event)->
  if (event.keyCode==Keyboard.PREVIOUS)
    selectPreviousMarker()
  else if (event.keyCode==Keyboard.NEXT)
    selectNextMarker()

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
    setData(markerData)

handleMarkerClick = (event)->
  selectMarker(event.latLng)

getImageArrayFromData = (markerData)->
  a = []
  l = parseInt(markerData.properties.images, 10)
  categorySlug = markerData.properties['category-slug']
  slug = markerData.properties.slug
  for num in [1..l]
    a.push({src:"assets/photos/#{categorySlug}/#{slug}/image#{num}.jpg"})
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
