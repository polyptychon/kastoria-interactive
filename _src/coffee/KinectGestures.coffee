EventEmitter = require('events')

class KinectGesturesEmitter extends EventEmitter

SWIPE_IN    = "swipe_in"
SWIPE_OUT   = "swipe_out"
SWIPE_LEFT  = "swipe_left"
SWIPE_RIGHT = "swipe_right"
SWIPE_UP    = "swipe_up"
SWIPE_DOWN  = "swipe_down"

kinectGesturesEmitter = new KinectGesturesEmitter();

_bodyFrame = null
checkGestureTimeouts = {}
isGestureDisabledTimeout = -1
isGesturePaused = {}

socket = require('socket.io-client')('http://localhost:8000');
socket.on('bodyFrame', (bodyFrame)->
  _bodyFrame = bodyFrame
  bodyFrame.bodies.forEach((user,index)->
    trackUser(index) if user.tracked
  )
)
getYPositionRelativeToTorso = (user, skeletonJoint=11)->
  relativePosition = 5
  if user.tracked
    position = Math.floor(user.joints[skeletonJoint].depthY * 100)
    relativePosition = position
#    torsoPosition = Math.floor(user.joints[1].depthY * 100)
#    relativePosition = position - torsoPosition
  return relativePosition

getRightHandYPositionRelativeToTorso = (user)->
  return getYPositionRelativeToTorso(user)

getLeftHandYPositionRelativeToTorso = (user)->
  return getYPositionRelativeToTorso(user, 7)

getXPositionRelativeToTorso = (user, skeletonJoint=11)->
  relativePosition = 5
  if user.tracked
    position = Math.floor(user.joints[skeletonJoint].depthX * 100)
    torsoPosition = Math.floor(user.joints[1].depthX * 100)
    relativePosition = position - torsoPosition
  return relativePosition

getRightHandXPositionRelativeToTorso = (user)->
  return getXPositionRelativeToTorso(user)

getLeftHandXPositionRelativeToTorso = (user)->
  return getXPositionRelativeToTorso(user, 7)

getHeadXPositionRelativeToTorso = (user)->
  return getXPositionRelativeToTorso(user, 3)

isHeadLooking = (positionX)->
  (positionX>=-2 and positionX<=2)

isLeftHandStretched = (positionX)->
  positionX>20

isRightHandStretched = (positionX)->
  positionX>20

isLeftHandClosed = (positionX)->
  positionX<5

isRightHandClosed = (positionX)->
  positionX<5

isLeftHandStretching = (oldPositionX, positionX)->
  speed = positionX - oldPositionX
  speed>=11

isRightHandStretching = (oldPositionX, positionX)->
  speed = positionX - oldPositionX
  speed>=11

isLeftHandClosing = (oldPositionX, positionX)->
  speed = Math.abs(oldPositionX - positionX)
  speed>=14

isRightHandClosing = (oldPositionX, positionX)->
  speed = oldPositionX - positionX
  speed>=14

isSwipeInEventStarted = (p)->
  p.isRightHandStretched and p.isLeftHandStretched

isSwipeInEventHappening = (m)->
  m.isLeftHandClosing and m.isRightHandClosing

isSwipeOutEventStarted = (p)->
  p.isLeftHandClosed and p.isRightHandClosed

isSwipeOutEventHappening = (m)->
  m.isRightHandStretching and m.isLeftHandStretching

isSwipeLeftEventStarted = (p)->
  p.isRightHandStretched unless p.isLeftHandStretched

isSwipeLeftEventHappening = (m)->
  m.isRightHandClosing unless m.isLeftHandClosing

isSwipeRightEventStarted = (p)->
  p.isLeftHandStretched unless p.isRightHandStretched

isSwipeRightEventHappening = (m)->
  m.isLeftHandClosing unless m.isRightHandClosing

isLeftHandUp = (positionY)->
  positionY<30

isRightHandUp = (positionY)->
  positionY<30

isLeftHandDown = (positionY)->
  positionY>35

isRightHandDown = (positionY)->
  positionY>35

isLeftHandFalling = (oldPositionY, positionY)->
  speed = Math.abs(oldPositionY - positionY)
  speed>=30

isRightHandFalling = (oldPositionY, positionY)->
  speed = Math.abs(oldPositionY - positionY)
  speed>=20

isLeftHandRising = (oldPositionY, positionY)->
  speed = Math.abs(oldPositionY - positionY)
  speed>=14

isRightHandRising = (oldPositionY, positionY)->
  speed = Math.abs(oldPositionY - positionY)
  speed>=14

isSwipeUpEventStarted = (p)->
  p.isLeftHandDown or p.isRightHandDown

isSwipeUpEventHappening = (m)->
  m.isLeftHandRising or m.isRightHandRising

isSwipeDownEventStarted = (p)->
  p.isLeftHandUp or p.isRightHandUp

isSwipeDownEventHappening = (m)->
  m.isLeftHandFalling or m.isRightHandFalling

HandPositions = (
  oldLeftHandRelativeXPosition,
  oldRightHandRelativeXPosition,
  oldLeftHandRelativeYPosition,
  oldRightHandRelativeYPosition,
  headPositionX
)->
  this.isLeftHandUp = isLeftHandUp(oldLeftHandRelativeYPosition)
  this.isRightHandUp = isRightHandUp(oldRightHandRelativeYPosition)
  this.isLeftHandDown = isLeftHandDown(oldLeftHandRelativeYPosition)
  this.isRightHandDown = isRightHandDown(oldRightHandRelativeYPosition)

  this.isLeftHandStretched = isLeftHandStretched(oldLeftHandRelativeXPosition)
  this.isRightHandStretched = isRightHandStretched(oldRightHandRelativeXPosition)
  this.isLeftHandClosed = isLeftHandClosed(oldLeftHandRelativeXPosition)
  this.isRightHandClosed = isRightHandClosed(oldRightHandRelativeXPosition)
  this.isHeadLooking = isHeadLooking(headPositionX)

HandPositionsMovements = (
  oldLeftHandRelativeXPosition,
  newLeftHandRelativeXPosition,
  oldRightHandRelativeXPosition,
  newRightHandRelativeXPosition,

  oldLeftHandRelativeYPosition,
  newLeftHandRelativeYPosition,
  oldRightHandRelativeYPosition,
  newRightHandRelativeYPosition,
  headPositionX
)->
  this.isLeftHandFalling = isLeftHandFalling(oldLeftHandRelativeYPosition, newLeftHandRelativeYPosition)
  this.isRightHandFalling = isRightHandFalling(oldRightHandRelativeYPosition, newRightHandRelativeYPosition)
  this.isLeftHandRising = isLeftHandRising(oldLeftHandRelativeYPosition, newLeftHandRelativeYPosition)
  this.isRightHandRising = isRightHandRising(oldRightHandRelativeYPosition, newRightHandRelativeYPosition)

  this.isLeftHandClosing = isLeftHandClosing(oldLeftHandRelativeXPosition, newLeftHandRelativeXPosition)
  this.isRightHandClosing = isRightHandClosing(oldRightHandRelativeXPosition, newRightHandRelativeXPosition)
  this.isLeftHandStretching = isLeftHandStretching(oldLeftHandRelativeXPosition, newLeftHandRelativeXPosition)
  this.isRightHandStretching = isRightHandStretching(oldRightHandRelativeXPosition, newRightHandRelativeXPosition)
  this.isHeadLooking = isHeadLooking(headPositionX)

pauseGesture = (gesture)->
  isGesturePaused[gesture] = true
  isGestureDisabledTimeout = setTimeout(()->
    isGesturePaused[gesture] = false
  , 1200)

trackUser = (userIndex)->
  if $('body').hasClass('gallery-zoom')
    trackUserEvent(userIndex, SWIPE_IN, isSwipeInEventStarted, isSwipeInEventHappening, SWIPE_OUT, true)
  if !$('body').hasClass('gallery-zoom')
    trackUserEvent(userIndex, SWIPE_OUT, isSwipeOutEventStarted, isSwipeOutEventHappening, SWIPE_IN, true)
  trackUserEvent(userIndex, SWIPE_LEFT, isSwipeLeftEventStarted, isSwipeLeftEventHappening)
  trackUserEvent(userIndex, SWIPE_RIGHT, isSwipeRightEventStarted, isSwipeRightEventHappening)
  trackUserEvent(userIndex, SWIPE_UP, isSwipeUpEventStarted, isSwipeUpEventHappening, SWIPE_DOWN)
  trackUserEvent(userIndex, SWIPE_DOWN, isSwipeDownEventStarted, isSwipeDownEventHappening, SWIPE_UP)


trackUserEvent = (userIndex, eventName, shouldTrackEvent, isEventHappening, pauseEventName=null, shouldPauseAllEvents=false)->
  user = _bodyFrame.bodies[userIndex]
  oldLeftHandRelativeXPosition = Math.abs(getLeftHandXPositionRelativeToTorso(user))
  oldRightHandRelativeXPosition = getRightHandXPositionRelativeToTorso(user)
  oldLeftHandRelativeYPosition = Math.abs(getLeftHandYPositionRelativeToTorso(user))
  oldRightHandRelativeYPosition = getRightHandYPositionRelativeToTorso(user)

  headXPosition = getHeadXPositionRelativeToTorso(user)

  p = new HandPositions(
    oldLeftHandRelativeXPosition,
    oldRightHandRelativeXPosition,
    oldLeftHandRelativeYPosition,
    oldRightHandRelativeYPosition,
    headXPosition
  )

  if shouldTrackEvent(p) and p.isHeadLooking

    checkGestureTimeouts[userIndex] = checkGestureTimeouts[userIndex] || {}
    clearTimeout(checkGestureTimeouts[userIndex][eventName])

    checkGestureTimeouts[userIndex][eventName] = setTimeout(()->
      user = _bodyFrame.bodies[userIndex]
      newLeftHandRelativeXPosition = Math.abs(getLeftHandXPositionRelativeToTorso(user))
      newRightHandRelativeXPosition = getRightHandXPositionRelativeToTorso(user)
      newLeftHandRelativeYPosition = Math.abs(getLeftHandYPositionRelativeToTorso(user))
      newRightHandRelativeYPosition = getRightHandYPositionRelativeToTorso(user)
      headXPosition = getHeadXPositionRelativeToTorso(user)

      m = new HandPositionsMovements(
        oldLeftHandRelativeXPosition,
        newLeftHandRelativeXPosition,
        oldRightHandRelativeXPosition,
        newRightHandRelativeXPosition,

        oldLeftHandRelativeYPosition,
        newLeftHandRelativeYPosition,
        oldRightHandRelativeYPosition,
        newRightHandRelativeYPosition,

        headXPosition
      )

      if !isGesturePaused["ALL"]
        if !isGesturePaused[eventName] and isEventHappening(m) and m.isHeadLooking
          kinectGesturesEmitter.emit(eventName)
          pauseGesture(pauseEventName) if pauseEventName
          pauseGesture("ALL") if shouldPauseAllEvents
          clearTimeout(checkGestureTimeouts[userIndex][eventName])

    , 300)

module.exports = kinectGesturesEmitter
