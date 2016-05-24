EventEmitter = require('events')

class KinectGesturesEmitter extends EventEmitter

kinectGesturesEmitter = new KinectGesturesEmitter();

_bodyFrame = null
checkNextGestureTimeouts = {}
checkPreviousGestureTimeouts = {}

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

getRelativeYPosition = (user, hand=11)->
  if user.tracked
    return Math.floor(user.joints[hand].depthY * 100)
  else
    return -1

getRightHandRelativeXPosition = (user)->
  return getRelativeXPosition(user)

getLeftHandRelativeXPosition = (user)->
  return getRelativeXPosition(user, 7)

getRightHandRelativeYPosition = (user)->
  return getRelativeYPosition(user)

getLeftHandRelativeYPosition = (user)->
  return getRelativeYPosition(user, 7)

getHeadRelativeXPosition = (user)->
  return getRelativeXPosition(user, 3)

trackUser = (user, index)->
  if user.tracked
    oldRightHandRelativeXPosition = getRightHandRelativeXPosition(user)
    oldLeftHandRelativeXPosition = Math.abs(getLeftHandRelativeXPosition(user))

    oldRightHandRelativeYPosition = getRightHandRelativeYPosition(user)
    oldLeftHandRelativeYPosition = getLeftHandRelativeYPosition(user)

    headXPosition = getHeadRelativeXPosition(user)
    if oldRightHandRelativeXPosition>15 && oldLeftHandRelativeXPosition>15 && (headXPosition>=-2 && headXPosition<=2)
      clearTimeout(checkNextGestureTimeouts[index])
      checkNextGestureTimeouts[index] = setTimeout(()->
        clearTimeout(checkNextGestureTimeouts[index])
        clearTimeout(checkPreviousGestureTimeouts[index])

        newRightHandRelativeXPosition = getRightHandRelativeXPosition(_bodyFrame.bodies[index])
        newLeftHandRelativeXPosition = Math.abs(getLeftHandRelativeXPosition(_bodyFrame.bodies[index]))
        rightHandXSpeed = oldRightHandRelativeXPosition - newRightHandRelativeXPosition
        leftHandXSpeed = oldLeftHandRelativeXPosition - newLeftHandRelativeXPosition

        newRightHandRelativeYPosition = getRightHandRelativeYPosition(_bodyFrame.bodies[index])
        newLeftHandRelativeYPosition = getLeftHandRelativeYPosition(_bodyFrame.bodies[index])
        rightHandYSpeed = newRightHandRelativeYPosition - oldRightHandRelativeYPosition
        leftHandYSpeed = newLeftHandRelativeYPosition - oldLeftHandRelativeYPosition

        kinectGesturesEmitter.emit('swipe_left') if (rightHandXSpeed>=20 && leftHandXSpeed<10)
        kinectGesturesEmitter.emit('swipe_in') if (rightHandXSpeed>=15 && leftHandXSpeed>=15) && (Math.abs(rightHandYSpeed) - Math.abs(leftHandYSpeed))<8
      , 250)

    if (oldRightHandRelativeXPosition<=0 || (oldRightHandRelativeXPosition && oldLeftHandRelativeXPosition<=0)) && (headXPosition>=-2 && headXPosition<=2)
      clearTimeout(checkPreviousGestureTimeouts[index])
      checkPreviousGestureTimeouts[index] = setTimeout(()->
        clearTimeout(checkPreviousGestureTimeouts[index])
        clearTimeout(checkNextGestureTimeouts[index])

        newRightHandRelativeXPosition = getRightHandRelativeXPosition(_bodyFrame.bodies[index])
        newLeftHandRelativeXPosition = Math.abs(getLeftHandRelativeXPosition(_bodyFrame.bodies[index]))
        rightHandXSpeed = newRightHandRelativeXPosition + oldRightHandRelativeXPosition
        leftHandXSpeed = newLeftHandRelativeXPosition - oldLeftHandRelativeXPosition

        newRightHandRelativeYPosition = getRightHandRelativeYPosition(_bodyFrame.bodies[index])
        newLeftHandRelativeYPosition = getLeftHandRelativeYPosition(_bodyFrame.bodies[index])
        rightHandYSpeed = newRightHandRelativeYPosition - oldRightHandRelativeYPosition
        leftHandYSpeed = newLeftHandRelativeYPosition - oldLeftHandRelativeYPosition

        kinectGesturesEmitter.emit('swipe_right') if (rightHandXSpeed>=20 && leftHandXSpeed<10)
        kinectGesturesEmitter.emit('swipe_out') if (rightHandXSpeed>=15 && leftHandXSpeed>=15) && (Math.abs(rightHandYSpeed)>20 && Math.abs(leftHandYSpeed)>20)
      , 250)

module.exports = kinectGesturesEmitter
