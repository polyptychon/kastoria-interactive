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

getHandRelativePosition = (user, hand=11)->
  handRelativePosition = 5
  if user.tracked
    handPosition = Math.floor(user.joints[hand].depthX * 100)
    torsoPosition = Math.floor(user.joints[1].depthX * 100)
    handRelativePosition = handPosition - torsoPosition
  return handRelativePosition

getRightHandRelativePosition = (user)->
  return getHandRelativePosition(user)

getLeftHandRelativePosition = (user)->
  return getHandRelativePosition(user, 7)

trackUser = (user, index)->
  if user.tracked
    oldRightHandRelativePosition = getRightHandRelativePosition(user)
    oldLeftHandRelativePosition = Math.abs(getLeftHandRelativePosition(user))

    if oldRightHandRelativePosition>15 && oldLeftHandRelativePosition>15
      clearTimeout(checkNextGestureTimeouts[index])
      checkNextGestureTimeouts[index] = setTimeout(()->
        clearTimeout(checkNextGestureTimeouts[index])
        clearTimeout(checkPreviousGestureTimeouts[index])
        newRightHandRelativePosition = getRightHandRelativePosition(_bodyFrame.bodies[index])
        newLeftHandRelativePosition = Math.abs(getLeftHandRelativePosition(_bodyFrame.bodies[index]))
        rightHandSpeed = oldRightHandRelativePosition - newRightHandRelativePosition
        leftHandSpeed = oldLeftHandRelativePosition - newLeftHandRelativePosition
        kinectGesturesEmitter.emit('swipe_left') if (rightHandSpeed>=20 && leftHandSpeed<10)
        kinectGesturesEmitter.emit('swipe_in') if (rightHandSpeed>=20 && leftHandSpeed>=14)
      , 200)

    if oldRightHandRelativePosition<=0 || (oldRightHandRelativePosition && oldLeftHandRelativePosition<=0)
      clearTimeout(checkPreviousGestureTimeouts[index])
      checkPreviousGestureTimeouts[index] = setTimeout(()->
        clearTimeout(checkPreviousGestureTimeouts[index])
        clearTimeout(checkNextGestureTimeouts[index])
        newRightHandRelativePosition = getRightHandRelativePosition(_bodyFrame.bodies[index])
        newLeftHandRelativePosition = Math.abs(getLeftHandRelativePosition(_bodyFrame.bodies[index]))
        rightHandSpeed = newRightHandRelativePosition + oldRightHandRelativePosition
        leftHandSpeed = newLeftHandRelativePosition - oldLeftHandRelativePosition
        kinectGesturesEmitter.emit('swipe_right') if (rightHandSpeed>=20 && leftHandSpeed<10)
        kinectGesturesEmitter.emit('swipe_out') if (rightHandSpeed>=20 && leftHandSpeed>=14)
      , 200)

module.exports = kinectGesturesEmitter
