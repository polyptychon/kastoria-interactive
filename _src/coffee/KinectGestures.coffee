EventEmitter = require('events')

class KinectGesturesEmitter extends EventEmitter

SWIPE_IN    = "swipe_in"
SWIPE_OUT   = "swipe_out"
SWIPE_LEFT  = "swipe_left"
SWIPE_RIGHT = "swipe_right"

kinectGesturesEmitter = new KinectGesturesEmitter();

_bodyFrame = null
checkGestureTimeouts = {}
isGestureDisabledTimeout = -1
isGesturePaused = {}

socket = require('socket.io-client')('http://localhost:8000');
socket.on('bodyFrame', (bodyFrame)->
  _bodyFrame = bodyFrame
  bodyFrame.bodies.forEach((user,index)->
    trackUser(user,index)
  )
)

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

HandPositions = (oldLeftHandRelativeXPosition, oldRightHandRelativeXPosition, headPositionX)->
  this.isLeftHandStretched = isLeftHandStretched(oldLeftHandRelativeXPosition)
  this.isRightHandStretched = isRightHandStretched(oldRightHandRelativeXPosition)
  this.isLeftHandClosed = isLeftHandClosed(oldLeftHandRelativeXPosition)
  this.isRightHandClosed = isRightHandClosed(oldRightHandRelativeXPosition)
  this.isHeadLooking = isHeadLooking(headPositionX)

HandPositionsMovements = (oldLeftHandRelativeXPosition, newLeftHandRelativeXPosition, oldRightHandRelativeXPosition, newRightHandRelativeXPosition, headPositionX)->
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

trackUser = (user, index)->
  trackEvent(user, index, SWIPE_IN, isSwipeInEventStarted, isSwipeInEventHappening, SWIPE_OUT, true)
  trackEvent(user, index, SWIPE_OUT, isSwipeOutEventStarted, isSwipeOutEventHappening, SWIPE_IN, true)
  trackEvent(user, index, SWIPE_LEFT, isSwipeLeftEventStarted, isSwipeLeftEventHappening)
  trackEvent(user, index, SWIPE_RIGHT, isSwipeRightEventStarted, isSwipeRightEventHappening)


trackEvent = (user, index, eventName, shouldTrackEvent, isEventHappening, pauseEventName=null, shouldPauseAllEvents=false)->
  if user.tracked
    oldLeftHandRelativeXPosition = Math.abs(getLeftHandXPositionRelativeToTorso(user))
    oldRightHandRelativeXPosition = getRightHandXPositionRelativeToTorso(user)
    headXPosition = getHeadXPositionRelativeToTorso(user)

    p = new HandPositions(oldLeftHandRelativeXPosition, oldRightHandRelativeXPosition, headXPosition)

    if shouldTrackEvent(p) and p.isHeadLooking

      checkGestureTimeouts[index] = {} if !checkGestureTimeouts[index]?
      clearTimeout(checkGestureTimeouts[index][eventName])

      checkGestureTimeouts[index][eventName] = setTimeout(()->
        user = _bodyFrame.bodies[index]
        newLeftHandRelativeXPosition = Math.abs(getLeftHandXPositionRelativeToTorso(user))
        newRightHandRelativeXPosition = getRightHandXPositionRelativeToTorso(user)
        headXPosition = getHeadXPositionRelativeToTorso(user)

        m = new HandPositionsMovements(oldLeftHandRelativeXPosition, newLeftHandRelativeXPosition, oldRightHandRelativeXPosition, newRightHandRelativeXPosition, headXPosition)

        if !isGesturePaused["ALL"]
          if !isGesturePaused[eventName] and isEventHappening(m) and m.isHeadLooking
            kinectGesturesEmitter.emit(eventName)
            pauseGesture(pauseEventName) if pauseEventName
            pauseGesture("ALL") if shouldPauseAllEvents
            clearTimeout(checkGestureTimeouts[index][eventName])

      , 300)

module.exports = kinectGesturesEmitter
