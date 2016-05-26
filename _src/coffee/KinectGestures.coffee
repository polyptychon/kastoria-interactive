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

disableTemporaryGestures = ()->
  return if areGesturesDisabled
  areGesturesDisabled = true
  clearTimeout(disableGesturesTimeout)
  disableGesturesTimeout = setTimeout(
    ()-> areGesturesDisabled=false
  , 500)

trackUser = (user, index)->
  if user.tracked
    oldRightHandRelativeXPosition = getRightHandRelativeXPosition(user)
    oldLeftHandRelativeXPosition = Math.abs(getLeftHandRelativeXPosition(user))
#    console.debug(oldRightHandRelativeXPosition, oldLeftHandRelativeXPosition)

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

        if !areGesturesDisabled && (rightHandXSpeed>=20 && (leftHandXSpeed>-5 && leftHandXSpeed<5)) && (headXPosition>=-2 && headXPosition<=2)
          kinectGesturesEmitter.emit('swipe_left')
          disableTemporaryGestures()

        if !areGesturesDisabled && (rightHandXSpeed>=20 && leftHandXSpeed>=10) && (headXPosition>=-2 && headXPosition<=2)
          kinectGesturesEmitter.emit('swipe_in')
          disableTemporaryGestures()
      , 300)

    if (oldRightHandRelativeXPosition<=0 || oldLeftHandRelativeXPosition>=30 || (oldRightHandRelativeXPosition && oldLeftHandRelativeXPosition<=0)) && (headXPosition>=-2 && headXPosition<=2)
      clearTimeout(checkPreviousGestureTimeouts[index])
      checkPreviousGestureTimeouts[index] = setTimeout(()->
        clearTimeout(checkPreviousGestureTimeouts[index])
        clearTimeout(checkNextGestureTimeouts[index])

        newRightHandRelativeXPosition = getRightHandRelativeXPosition(_bodyFrame.bodies[index])
        newLeftHandRelativeXPosition = Math.abs(getLeftHandRelativeXPosition(_bodyFrame.bodies[index]))
        rightHandXSpeed = newRightHandRelativeXPosition - oldRightHandRelativeXPosition
        leftHandXSpeed = newLeftHandRelativeXPosition - oldLeftHandRelativeXPosition

        console.log(areGesturesDisabled, rightHandXSpeed, leftHandXSpeed)

        if !areGesturesDisabled && (Math.abs(leftHandXSpeed)>=22 && (rightHandXSpeed>-5 && rightHandXSpeed<5)) && (headXPosition>=-2 && headXPosition<=2)
          kinectGesturesEmitter.emit('swipe_right')
          disableTemporaryGestures()

        if !areGesturesDisabled && (rightHandXSpeed<=-10 && leftHandXSpeed<=-10) && (headXPosition>=-2 && headXPosition<=2)
          kinectGesturesEmitter.emit('swipe_out')
          disableTemporaryGestures()

      , 300)

module.exports = kinectGesturesEmitter
