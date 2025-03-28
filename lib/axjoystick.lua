local axjoystick={}

function axjoystick.createJoystickState(j,id)
  state={
    joystick=j,
    id=id,
    vxleft=0.0,vyleft=0.0,vxright=0.0,vyright=0.0,
    leftAngle=0.0,rightAngle=0.0,
    dpleft=false,dpright=false,dpup=false,dpdown=false,
    leftx=0,lefty=0,rightx=0,righty=0,
    leftstick=false,rightstick=false, --buttons on the sticks
    a=false,b=false,x=false,y=false,
    rightshoulder=false,leftshoulder=false,
    triggerleft=0,triggerright=0,
    back=false,start=false,
  }
  return state
end

return axjoystick