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

getHeadRelativeXPosition = (user)->
  return getRelativeXPosition(user, 3)

trackUser = (user, index)->
  if user.tracked
    oldRightHandRelativePosition = getRightHandRelativeXPosition(user)
    oldLeftHandRelativePosition = Math.abs(getLeftHandRelativeXPosition(user))
    headPosition = getHeadRelativeXPosition(user)
    if oldRightHandRelativePosition>15 && oldLeftHandRelativePosition>15 && (headPosition>=-2 && headPosition<=2)
      clearTimeout(checkNextGestureTimeouts[index])
      checkNextGestureTimeouts[index] = setTimeout(()->
        clearTimeout(checkNextGestureTimeouts[index])
        clearTimeout(checkPreviousGestureTimeouts[index])
        newRightHandRelativePosition = getRightHandRelativeXPosition(_bodyFrame.bodies[index])
        newLeftHandRelativePosition = Math.abs(getLeftHandRelativeXPosition(_bodyFrame.bodies[index]))
        rightHandSpeed = oldRightHandRelativePosition - newRightHandRelativePosition
        leftHandSpeed = oldLeftHandRelativePosition - newLeftHandRelativePosition
        kinectGesturesEmitter.emit('swipe_left') if (rightHandSpeed>=20 && leftHandSpeed<10)
        kinectGesturesEmitter.emit('swipe_in') if (rightHandSpeed>=15 && leftHandSpeed>=15)
      , 250)

    if (oldRightHandRelativePosition<=0 || (oldRightHandRelativePosition && oldLeftHandRelativePosition<=0)) && (headPosition>=-2 && headPosition<=2)
      clearTimeout(checkPreviousGestureTimeouts[index])
      checkPreviousGestureTimeouts[index] = setTimeout(()->
        clearTimeout(checkPreviousGestureTimeouts[index])
        clearTimeout(checkNextGestureTimeouts[index])
        newRightHandRelativePosition = getRightHandRelativeXPosition(_bodyFrame.bodies[index])
        newLeftHandRelativePosition = Math.abs(getLeftHandRelativeXPosition(_bodyFrame.bodies[index]))
        rightHandSpeed = newRightHandRelativePosition + oldRightHandRelativePosition
        leftHandSpeed = newLeftHandRelativePosition - oldLeftHandRelativePosition
        kinectGesturesEmitter.emit('swipe_right') if (rightHandSpeed>=20 && leftHandSpeed<10)
        kinectGesturesEmitter.emit('swipe_out') if (rightHandSpeed>=15 && leftHandSpeed>=15)
      , 250)

module.exports = kinectGesturesEmitter
