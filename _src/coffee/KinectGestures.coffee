EventEmitter = require('events')

class KinectGesturesEmitter extends EventEmitter

kinectGesturesEmitter = new KinectGesturesEmitter();

_bodyFrame = null
checkNextGestureTimeouts = {}
checkPreviousGestureTimeouts = {}
areGesturesDisabled = false
disableGesturesTimeout = -1

socket = require('socket.io-client')('http://localhost:8000');
socket.on('bodyFrame', (bodyFrame)->
  _bodyFrame = bodyFrame
  bodyFrame.bodies.forEach((user,index)->
    trackUser(user,index)
  )
)

getRelativeXPosition = (user, hand=11)->
  relativePosition = 5
  if user.tracked
    position = Math.floor(user.joints[hand].depthX * 100)
    torsoPosition = Math.floor(user.joints[1].depthX * 100)
    relativePosition = position - torsoPosition
  return relativePosition

getRightHandRelativeXPosition = (user)->
  return getRelativeXPosition(user)

getLeftHandRelativeXPosition = (user)->
  return getRelativeXPosition(user, 7)

getHeadRelativeXPosition = (user)->
  return getRelativeXPosition(user, 3)

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
  speed>=12

isRightHandStretching = (oldPositionX, positionX)->
  speed = positionX - oldPositionX
  speed>=12

isLeftHandClosing = (oldPositionX, positionX)->
  speed = oldPositionX - positionX
  speed>=20

isRightHandClosing = (oldPositionX, positionX)->
  speed = oldPositionX - positionX
  speed>=20

disableTemporaryGestures = ()->
  return if areGesturesDisabled
  areGesturesDisabled = true
  clearTimeout(disableGesturesTimeout)
  disableGesturesTimeout = setTimeout(
    ()-> areGesturesDisabled=false
  , 500)

clearTimeOuts = (index)->
  clearTimeout(checkNextGestureTimeouts[index])
  clearTimeout(checkPreviousGestureTimeouts[index])

trackUser = (user, index)->
  if user.tracked
    oldRightHandRelativeXPosition = getRightHandRelativeXPosition(user)
    oldLeftHandRelativeXPosition = Math.abs(getLeftHandRelativeXPosition(user))

    headXPosition = getHeadRelativeXPosition(user)

    console.table({
      isLeftHandStretched: isLeftHandStretched(oldLeftHandRelativeXPosition)
      isRightHandStretched: isRightHandStretched(oldRightHandRelativeXPosition)
      isLeftHandClosed: isLeftHandClosed(oldLeftHandRelativeXPosition)
      isRightHandClosed: isRightHandClosed(oldRightHandRelativeXPosition)
    })

    if (oldRightHandRelativeXPosition>20 || (oldRightHandRelativeXPosition>=20 && oldLeftHandRelativeXPosition>=20)) && (headXPosition>=-2 && headXPosition<=2)
      clearTimeout(checkNextGestureTimeouts[index])
      checkNextGestureTimeouts[index] = setTimeout(()->

        newRightHandRelativeXPosition = getRightHandRelativeXPosition(_bodyFrame.bodies[index])
        newLeftHandRelativeXPosition = Math.abs(getLeftHandRelativeXPosition(_bodyFrame.bodies[index]))
        rightHandXSpeed = oldRightHandRelativeXPosition - newRightHandRelativeXPosition
        leftHandXSpeed = oldLeftHandRelativeXPosition - newLeftHandRelativeXPosition

        console.table({
          isLeftHandClosing: isLeftHandClosing(oldLeftHandRelativeXPosition, newLeftHandRelativeXPosition)
          isRightHandClosing: isRightHandClosing(oldRightHandRelativeXPosition, newRightHandRelativeXPosition)
        })

        if !areGesturesDisabled && (rightHandXSpeed>=20 && (leftHandXSpeed>-5 && leftHandXSpeed<5)) && (headXPosition>=-2 && headXPosition<=2)
          kinectGesturesEmitter.emit('swipe_left')
          disableTemporaryGestures()
          clearTimeOuts(index)

        if !areGesturesDisabled && (rightHandXSpeed>=20 && leftHandXSpeed>=10) && (headXPosition>=-2 && headXPosition<=2)
          kinectGesturesEmitter.emit('swipe_in')
          disableTemporaryGestures()
          clearTimeOuts(index)
      , 300)

    if (oldLeftHandRelativeXPosition<=5 || (oldRightHandRelativeXPosition<=5 && oldLeftHandRelativeXPosition<=5)) && (headXPosition>=-2 && headXPosition<=2)
      clearTimeout(checkPreviousGestureTimeouts[index])
      checkPreviousGestureTimeouts[index] = setTimeout(()->

        newRightHandRelativeXPosition = getRightHandRelativeXPosition(_bodyFrame.bodies[index])
        newLeftHandRelativeXPosition = Math.abs(getLeftHandRelativeXPosition(_bodyFrame.bodies[index]))
        rightHandXSpeed = newRightHandRelativeXPosition - oldRightHandRelativeXPosition
        leftHandXSpeed = newLeftHandRelativeXPosition - oldLeftHandRelativeXPosition

        console.table({
          isLeftHandStretching: isLeftHandStretching(oldLeftHandRelativeXPosition, newLeftHandRelativeXPosition)
          isRightHandStretching: isRightHandStretching(oldRightHandRelativeXPosition, newRightHandRelativeXPosition)
        })

        if !areGesturesDisabled && (Math.abs(leftHandXSpeed)>=12 && (rightHandXSpeed>-5 && rightHandXSpeed<5)) && (headXPosition>=-2 && headXPosition<=2)
          kinectGesturesEmitter.emit('swipe_right')
          disableTemporaryGestures()
          clearTimeOuts(index)

        if !areGesturesDisabled && (rightHandXSpeed>=25 && leftHandXSpeed>=25) && (headXPosition>=-2 && headXPosition<=2)
          kinectGesturesEmitter.emit('swipe_out')
          disableTemporaryGestures()
          clearTimeOuts(index)

      , 300)

module.exports = kinectGesturesEmitter
