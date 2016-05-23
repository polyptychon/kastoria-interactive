EventEmitter = require('events');

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
SWIPE_LEFT = "swipe_left"
SWIPE_RIGHT = "swipe_right"

class KinectGestures extends EventEmitter
  constructor: (server='http://localhost:8000')->
    @_bodyFrame = null
    socket = require('socket.io-client')(server);
    socket.on('bodyFrame', (bodyFrame)->
      @_bodyFrame = bodyFrame
      bodyFrame.bodies.forEach((user,index)->
        @trackUser(user,index)
      )
    )

  getRightHandRelativePosition = (user)->
    rightHandRelativePosition = 5
    if user.tracked
      rightHandPosition = Math.floor(user.joints[11].depthX * 100)
      torsoPosition = Math.floor(user.joints[1].depthX * 100)
      rightHandRelativePosition = rightHandPosition - torsoPosition
    return rightHandRelativePosition

  trackUser = (user, index)->
    if user.tracked
      rightHandRelativePosition = getRightHandRelativePosition(user)
      if rightHandRelativePosition>15
        clearTimeout(checkNextGestureTimeouts[index])
        checkNextGestureTimeouts[index] = setTimeout(()=>
          clearTimeout(checkNextGestureTimeouts[index])
          clearTimeout(checkPreviousGestureTimeouts[index])
          @checkNextGesture(rightHandRelativePosition, index)
        , 200)

      if rightHandRelativePosition<=0
        clearTimeout(checkPreviousGestureTimeouts[index])
        checkPreviousGestureTimeouts[index] = setTimeout(()=>
          clearTimeout(checkPreviousGestureTimeouts[index])
          clearTimeout(checkNextGestureTimeouts[index])
          @checkPreviousGesture(rightHandRelativePosition, index)
        , 200)

  checkNextGesture = (oldPosition, index)->
    rightHandRelativePosition = getRightHandRelativePosition(@_bodyFrame.bodies[index])
    speed = oldPosition-rightHandRelativePosition
    this.emit(SWIPE_LEFT) if (speed>20)

  checkPreviousGesture = (oldPosition, index)->
    rightHandRelativePosition = getRightHandRelativePosition(@_bodyFrame.bodies[index])
    speed = rightHandRelativePosition+oldPosition
    this.emit(SWIPE_RIGHT) if (speed>20)

module.export =  KinectGestures
